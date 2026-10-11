import 'dart:convert';

import 'package:rs_core/rs_core.dart';
import 'package:shelf/shelf.dart';

const _jsonHeaders = {'content-type': 'application/json; charset=utf-8'};

Response jsonOk(Object? body) =>
    Response.ok(jsonEncode(body), headers: _jsonHeaders);

Response jsonError(int status, String code, String message) => Response(
  status,
  body: jsonEncode(ApiError(code: code, message: message).toJson()),
  headers: _jsonHeaders,
);
