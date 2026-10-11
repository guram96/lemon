import 'dart:convert';

import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';

import 'api_failure.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

/// Largest JSON request body accepted.
const maxJsonBodyBytes = 1024 * 1024;

Response jsonOk(Object? body) => jsonResponse(200, body);

Response jsonResponse(
  int status,
  Object? body, {
  Map<String, String>? headers,
}) => Response(
  status,
  body: jsonEncode(body),
  headers: {..._jsonHeaders, ...?headers},
);

Response jsonError(
  int status,
  String code,
  String message, {
  Map<String, String>? headers,
}) => jsonResponse(
  status,
  ApiError(code: code, message: message).toJson(),
  headers: headers,
);

/// Reads the request body as a JSON object and decodes it with [fromJson].
///
/// An empty body is treated as `{}`. Throws [ApiFailure] (400 / 413) for
/// oversized, malformed or mistyped bodies.
Future<T> readJson<T>(
  Request request,
  T Function(Map<String, Object?> json) fromJson,
) async {
  final length = request.contentLength;
  if (length != null && length > maxJsonBodyBytes) {
    throw const ApiFailure.payloadTooLarge();
  }
  final bytes = <int>[];
  await for (final chunk in request.read()) {
    bytes.addAll(chunk);
    if (bytes.length > maxJsonBodyBytes) {
      throw const ApiFailure.payloadTooLarge();
    }
  }
  Object? decoded;
  try {
    decoded = bytes.isEmpty
        ? <String, Object?>{}
        : jsonDecode(utf8.decode(bytes));
  } on FormatException {
    throw const ApiFailure.badRequest('The request body is not valid JSON.');
  }
  if (decoded is! Map<String, Object?>) {
    throw const ApiFailure.badRequest(
      'The request body must be a JSON object.',
    );
  }
  try {
    return fromJson(decoded);
  } on Object catch (e) {
    if (e is TypeError || e is ArgumentError || e is FormatException) {
      throw const ApiFailure.badRequest(
        'The request body is missing fields or has fields of the wrong type.',
      );
    }
    rethrow;
  }
}
