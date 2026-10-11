import 'package:rs_core/rs_core.dart';

/// Thrown when the server answers with a non-2xx status or cannot be reached.
class ApiException implements Exception {
  const ApiException({required this.statusCode, required this.error});

  /// `null` when the server could not be reached at all.
  final int? statusCode;
  final ApiError error;

  bool get isUnreachable => statusCode == null;

  @override
  String toString() =>
      'ApiException($statusCode, ${error.code}: ${error.message})';
}
