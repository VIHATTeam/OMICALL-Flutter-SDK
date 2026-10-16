/// One device registered on the OMI backend for the current SIP user,
/// from [OmicallClient.getOmiDevices]. Native returns snake_case on both platforms.
class OmiDeviceInfo {
  final String? deviceId;
  final String? token;

  /// "ios" / "android" (normalized by the native SDKs).
  final String? deviceType;
  final String? voipToken;
  final String? appId;
  final int? createdTime;
  final String? projectId;

  /// Injected from the local session, not from the server payload.
  final String? sipNumber;

  const OmiDeviceInfo({
    this.deviceId,
    this.token,
    this.deviceType,
    this.voipToken,
    this.appId,
    this.createdTime,
    this.projectId,
    this.sipNumber,
  });

  factory OmiDeviceInfo.fromMap(Map data) {
    return OmiDeviceInfo(
      deviceId: data['device_id']?.toString(),
      token: data['token']?.toString(),
      deviceType: data['device_type']?.toString(),
      voipToken: data['voip_token']?.toString(),
      appId: data['app_id']?.toString(),
      createdTime: (data['created_time'] as num?)?.toInt(),
      projectId: data['project_id']?.toString(),
      sipNumber: data['sipNumber']?.toString(),
    );
  }

  @override
  String toString() =>
      'OmiDeviceInfo(deviceId: $deviceId, deviceType: $deviceType, appId: $appId, sipNumber: $sipNumber)';
}
