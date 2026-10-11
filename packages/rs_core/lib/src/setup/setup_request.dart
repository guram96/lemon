import 'package:freezed_annotation/freezed_annotation.dart';

part 'setup_request.freezed.dart';
part 'setup_request.g.dart';

/// First-run setup. Accepted only while the server is unconfigured and only
/// from the loopback interface.
@freezed
abstract class SetupRequest with _$SetupRequest {
  static const minPasswordLength = 8;

  const factory SetupRequest({
    required String adminUsername,

    /// At least [minPasswordLength] characters.
    required String adminPassword,

    /// Absolute path of the data directory.
    required String dataDir,

    /// Absolute paths of the library roots. At least one.
    required List<String> libraryRoots,

    /// Name of the setup device, which joins the server automatically.
    required String deviceName,
  }) = _SetupRequest;

  factory SetupRequest.fromJson(Map<String, Object?> json) =>
      _$SetupRequestFromJson(json);
}
