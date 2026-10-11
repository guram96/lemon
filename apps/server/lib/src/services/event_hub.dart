import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:rs_core/rs_core.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

final _log = Logger('events');

/// WebSocket close code for rejected or revoked credentials (bad tokens,
/// logout, revoked device). Application range: `package:web_socket` only
/// lets a server send 1000 or 3000–4999, so 1008 (policy violation) can't be
/// used. Clients should stop reconnecting and re-authenticate.
const wsUnauthorized = 4401;

/// WebSocket close code used when the server shuts down (normal closure;
/// 1001 "going away" can't be sent, see [wsUnauthorized]).
const wsServerShutdown = 1000;

/// Fan-out of [ServerEvent]s to in-process listeners and to WebSocket
/// clients of `GET /events`.
class EventHub {
  final _controller = StreamController<ServerEvent>.broadcast();
  final _clients = <_Client>{};

  /// Every published event, for in-process listeners (and tests).
  Stream<ServerEvent> get stream => _controller.stream;

  /// Connected WebSocket clients.
  int get clientCount => _clients.length;

  void publish(ServerEvent event) {
    if (_controller.isClosed) return;
    _controller.add(event);
  }

  /// Streams events to [channel] until it closes. [initial] events are sent
  /// first (for example the status of a running scan).
  void attach(
    WebSocketChannel channel, {
    required String deviceId,
    required String sessionId,
    Iterable<ServerEvent> initial = const [],
  }) {
    late final _Client client;
    void send(ServerEvent e) {
      try {
        channel.sink.add(jsonEncode(e.toJson()));
      } on Object catch (error) {
        _log.fine('Dropping event for a closed socket: $error');
      }
    }

    for (final e in initial) {
      send(e);
    }
    // Cancelled in _detach.
    // ignore: cancel_subscriptions
    final subscription = stream.listen(send);
    client = _Client(channel, deviceId, sessionId, subscription);
    _clients.add(client);
    // Incoming messages are ignored; the stream only tells us when it closes.
    channel.stream.listen(
      (_) {},
      onError: (Object _) => _detach(client),
      onDone: () => _detach(client),
      cancelOnError: true,
    );
  }

  /// Closes the sockets of a logged-out session.
  Future<void> disconnectSession(String sessionId) => _disconnectWhere(
    (c) => c.sessionId == sessionId,
    wsUnauthorized,
    'logged out',
  );

  /// Closes the sockets of a revoked device.
  Future<void> disconnectDevice(String deviceId) => _disconnectWhere(
    (c) => c.deviceId == deviceId,
    wsUnauthorized,
    'device revoked',
  );

  /// Closes every socket and the in-process stream.
  Future<void> close() async {
    await _disconnectWhere(
      (_) => true,
      wsServerShutdown,
      'server shutting down',
    );
    await _controller.close();
  }

  Future<void> _disconnectWhere(
    bool Function(_Client) test,
    int code,
    String reason,
  ) async {
    final targets = _clients.where(test).toList();
    await Future.wait(
      targets.map((c) async {
        _detach(c);
        try {
          await c.channel.sink
              .close(code, reason)
              .timeout(const Duration(seconds: 2));
        } on Object {
          // Already closed or unresponsive.
        }
      }),
    );
  }

  void _detach(_Client client) {
    if (!_clients.remove(client)) return;
    unawaited(client.subscription.cancel());
  }
}

class _Client {
  _Client(this.channel, this.deviceId, this.sessionId, this.subscription);

  final WebSocketChannel channel;
  final String deviceId;
  final String sessionId;
  final StreamSubscription<ServerEvent> subscription;
}
