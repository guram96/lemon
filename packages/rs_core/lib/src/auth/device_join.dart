import 'package:freezed_annotation/freezed_annotation.dart';

part 'device_join.freezed.dart';
part 'device_join.g.dart';

@freezed
abstract class DeviceJoinRequest with _$DeviceJoinRequest {
  const factory DeviceJoinRequest({
    required String deviceName,

    /// `macos`, `windows`, `linux`, `android`, `ios` or `web`.
    required String platform,
  }) = _DeviceJoinRequest;

  factory DeviceJoinRequest.fromJson(Map<String, Object?> json) =>
      _$DeviceJoinRequestFromJson(json);
}

@freezed
abstract class DeviceJoinResult with _$DeviceJoinResult {
  const factory DeviceJoinResult({
    required String deviceId,

    /// Sent as [ApiHeaders.device] from now on.
    required String deviceToken,
  }) = _DeviceJoinResult;

  factory DeviceJoinResult.fromJson(Map<String, Object?> json) =>
      _$DeviceJoinResultFromJson(json);
}
