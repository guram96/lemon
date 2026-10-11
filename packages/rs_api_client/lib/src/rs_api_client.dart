import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:rs_core/rs_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'api_exception.dart';

/// Opens a WebSocket. Injected in tests; defaults to
/// [WebSocketChannel.connect], which works on every platform including web.
typedef WebSocketConnector = WebSocketChannel Function(Uri uri);

/// Client for one server, addressed by [baseUri] (for example
/// `http://192.168.1.10:47320`).
///
/// Sends [ApiHeaders.device] when [deviceToken] is set and
/// `Authorization: Bearer <sessionToken>` when [sessionToken] is set. Both are
/// mutable so the app can update them after joining or logging in.
class RsApiClient {
  RsApiClient({
    required this.baseUri,
    http.Client? httpClient,
    this.deviceToken,
    this.sessionToken,
    WebSocketConnector? webSocketConnector,
    this.reconnectInitialDelay = const Duration(seconds: 1),
    this.reconnectMaxDelay = const Duration(seconds: 30),
  }) : _http = httpClient ?? http.Client(),
       _connectWebSocket = webSocketConnector ?? WebSocketChannel.connect;

  final Uri baseUri;
  final http.Client _http;
  final WebSocketConnector _connectWebSocket;

  /// Device token from joining the server, sent as [ApiHeaders.device].
  String? deviceToken;

  /// Session token from logging in, sent as a bearer token.
  String? sessionToken;

  /// First delay before reconnecting [events]. Doubles on every failed
  /// attempt up to [reconnectMaxDelay].
  final Duration reconnectInitialDelay;
  final Duration reconnectMaxDelay;

  // --- Server ---------------------------------------------------------------

  Future<ServerInfo> getServerInfo() async =>
      ServerInfo.fromJson(_asMap(await _get(ApiRoutes.serverInfo)));

  // --- Setup ----------------------------------------------------------------

  /// Lists a folder on the server. `null` lists the filesystem roots.
  Future<BrowseResult> browse(String? path) async => BrowseResult.fromJson(
    _asMap(
      await _post(
        ApiRoutes.setupBrowse,
        body: BrowseRequest(path: path).toJson(),
      ),
    ),
  );

  Future<PathCheckResult> checkPath(String path, PathKind kind) async =>
      PathCheckResult.fromJson(
        _asMap(
          await _post(
            ApiRoutes.setupCheckPath,
            body: PathCheckRequest(path: path, kind: kind).toJson(),
          ),
        ),
      );

  /// Runs first-run setup. The result also carries the setup device's
  /// credentials; this does not store them in the client.
  Future<AuthResult> setup(SetupRequest request) async => AuthResult.fromJson(
    _asMap(await _post(ApiRoutes.setup, body: request.toJson())),
  );

  // --- Devices and auth ------------------------------------------------------

  /// Same-machine auto-join. Does not store the token in the client.
  Future<DeviceJoinResult> joinLocal(DeviceJoinRequest request) async =>
      DeviceJoinResult.fromJson(
        _asMap(await _post(ApiRoutes.devicesLocal, body: request.toJson())),
      );

  /// Logs in. Does not store the session token in the client.
  Future<AuthResult> login(String username, String password) async =>
      AuthResult.fromJson(
        _asMap(
          await _post(
            ApiRoutes.authLogin,
            body: LoginRequest(username: username, password: password).toJson(),
          ),
        ),
      );

  Future<void> logout() async {
    await _post(ApiRoutes.authLogout);
  }

  Future<User> me() async =>
      User.fromJson(_asMap(await _get(ApiRoutes.authMe)));

  // --- Library --------------------------------------------------------------

  Future<List<SystemSummary>> systems() async =>
      _asList(await _get(ApiRoutes.librarySystems), SystemSummary.fromJson);

  Future<GamePage> games({
    String? system,
    String? query,
    String sort = GameSort.title,
  }) async => GamePage.fromJson(
    _asMap(
      await _get(
        ApiRoutes.libraryGames,
        query: {
          ApiQueryParams.system: ?system,
          if (query != null && query.isNotEmpty) ApiQueryParams.query: query,
          ApiQueryParams.sort: sort,
        },
      ),
    ),
  );

  Future<Game> game(String id) async =>
      Game.fromJson(_asMap(await _get(ApiRoutes.libraryGame(id))));

  Future<List<LibraryRoot>> roots() async =>
      _asList(await _get(ApiRoutes.libraryRoots), LibraryRoot.fromJson);

  /// Starts a background scan. Throws [ApiException] with
  /// [ApiErrorCodes.conflict] if one is already running.
  Future<void> startScan() async {
    await _post(ApiRoutes.libraryScan);
  }

  Future<ScanStatus> scanStatus() async =>
      ScanStatus.fromJson(_asMap(await _get(ApiRoutes.libraryScanStatus)));

  /// URL of an artwork image, optionally resized to [width].
  Uri artworkUri(String artworkId, {int? width}) {
    final uri = baseUri.resolve(ApiRoutes.artwork(artworkId));
    return width == null
        ? uri
        : uri.replace(queryParameters: {ApiQueryParams.width: '$width'});
  }

  // --- Events ---------------------------------------------------------------

  /// WebSocket URL of [ApiRoutes.events] with the current tokens as query
  /// parameters (browsers can't send headers on a WebSocket).
  Uri eventsUri() {
    final uri = baseUri.resolve(ApiRoutes.events);
    return uri.replace(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      queryParameters: {
        ApiQueryParams.device: ?deviceToken,
        ApiQueryParams.session: ?sessionToken,
      },
    );
  }

  /// Push events from the server.
  ///
  /// Connects when listened to and reconnects with exponential backoff
  /// (from [reconnectInitialDelay] up to [reconnectMaxDelay]) whenever the
  /// connection fails or closes, until the subscription is cancelled. Tokens
  /// are read again on every reconnect. Messages that can't be decoded (for
  /// example event types from a newer server) are skipped.
  Stream<ServerEvent> events() {
    late StreamController<ServerEvent> controller;
    WebSocketChannel? channel;
    StreamSubscription<Object?>? subscription;
    Timer? retryTimer;
    var attempt = 0;
    var cancelled = false;

    void scheduleReconnect(void Function() connect) {
      if (cancelled) return;
      final factor = math.pow(2, math.min(attempt, 16)).toInt();
      var delay = reconnectInitialDelay * factor;
      if (delay > reconnectMaxDelay) delay = reconnectMaxDelay;
      attempt++;
      retryTimer = Timer(delay, connect);
    }

    void connect() {
      if (cancelled) return;
      final WebSocketChannel ws;
      try {
        ws = _connectWebSocket(eventsUri());
      } on Object {
        scheduleReconnect(connect);
        return;
      }
      channel = ws;
      ws.ready.then<void>(
        (_) => attempt = 0,
        // Failures also close the stream below, which schedules the retry.
        onError: (Object _) {},
      );
      subscription = ws.stream.listen(
        (message) {
          final event = _decodeEvent(message);
          if (event != null && !cancelled) controller.add(event);
        },
        onError: (Object _) {},
        onDone: () {
          subscription = null;
          channel = null;
          scheduleReconnect(connect);
        },
        cancelOnError: false,
      );
    }

    controller = StreamController<ServerEvent>(
      onListen: connect,
      onCancel: () async {
        cancelled = true;
        retryTimer?.cancel();
        await subscription?.cancel();
        await channel?.sink.close();
      },
    );
    return controller.stream;
  }

  void close() => _http.close();

  // --- Helpers --------------------------------------------------------------

  Map<String, String> _headers({bool json = false}) => {
    ApiHeaders.device: ?deviceToken,
    if (sessionToken case final token?)
      ApiHeaders.authorization: '${ApiHeaders.bearerPrefix}$token',
    if (json) 'Content-Type': 'application/json',
  };

  Future<Object?> _get(String path, {Map<String, String>? query}) {
    var uri = baseUri.resolve(path);
    if (query != null && query.isNotEmpty) {
      uri = uri.replace(queryParameters: query);
    }
    return _send(() => _http.get(uri, headers: _headers()));
  }

  Future<Object?> _post(String path, {Map<String, Object?>? body}) => _send(
    () => _http.post(
      baseUri.resolve(path),
      headers: _headers(json: body != null),
      body: body == null ? null : jsonEncode(body),
    ),
  );

  /// For admin delete routes (M2+).
  // ignore: unused_element
  Future<Object?> _delete(String path) =>
      _send(() => _http.delete(baseUri.resolve(path), headers: _headers()));

  /// Runs a request and returns its decoded JSON body, or `null` for an empty
  /// body (for example `204` or `202`).
  Future<Object?> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request();
    } on http.ClientException catch (e) {
      // Also covers socket errors: package:http wraps them on every platform.
      throw ApiException(
        statusCode: null,
        error: ApiError(code: ApiErrorCodes.unreachable, message: e.message),
      );
    }
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    Object? body;
    if (response.statusCode != 204 && response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body);
      } on FormatException {
        // A malformed success body is a protocol error; a malformed error
        // body (for example from a proxy) falls back to a generic ApiError.
        if (ok) rethrow;
      }
    }
    if (!ok) {
      throw ApiException(
        statusCode: response.statusCode,
        error: body is Map<String, Object?>
            ? ApiError.fromJson(body)
            : ApiError(
                code: ApiErrorCodes.internal,
                message: 'HTTP ${response.statusCode}',
              ),
      );
    }
    return body;
  }

  static Map<String, Object?> _asMap(Object? body) {
    if (body is Map<String, Object?>) return body;
    throw FormatException('Expected a JSON object', body);
  }

  static List<T> _asList<T>(
    Object? body,
    T Function(Map<String, Object?> json) fromJson,
  ) {
    if (body is List<Object?>) {
      return [for (final item in body) fromJson(_asMap(item))];
    }
    throw FormatException('Expected a JSON array', body);
  }

  static ServerEvent? _decodeEvent(Object? message) {
    if (message is! String) return null;
    try {
      final json = jsonDecode(message);
      return json is Map<String, Object?> ? ServerEvent.fromJson(json) : null;
    } on Object {
      return null;
    }
  }
}
