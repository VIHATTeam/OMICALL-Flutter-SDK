import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

import 'action/action_model.dart';
import 'constant/names.dart';
import 'models/consult_transfer.dart';
import 'models/register_result.dart';
import 'models/video_call_state.dart';
import 'models/device_info.dart';
import 'omicallsdk_controller.dart';

class OmicallClient {
  OmicallClient._();

  static OmicallClient? _instance;

  static OmicallClient get instance {
    _instance ??= OmicallClient._();
    return _instance!;
  }

  final OmicallSDKController _controller = OmicallSDKController();

  ///streaming camera event
  Stream<OmiAction> get callStateChangeEvent =>
      _controller.callStateChangeEvent;

  void setVideoListener(Function(Map) videoListener) {
    _controller.videoListener = videoListener;
  }

  void setMuteListener(Function(bool) muteListener) {
    _controller.muteListener = muteListener;
  }

  void setHoldListener(Function(bool) holdListener) {
    _controller.holdListener = holdListener;
  }

  void setSpeakerListener(Function(bool) speakerListener) {
    _controller.speakerListener = speakerListener;
  }

  void setMissedCallListener(Function(Map) missedCallListener) {
    _controller.missedCallListener = missedCallListener;
  }

  void setCallQualityListener(Function(Map) callQualityListener) {
    _controller.callQualityListener = callQualityListener;
  }

  void setCallLogListener(Function(Map) callLogListener) {
    _controller.callLogListener = callLogListener;
  }

  void setAudioChangedListener(Function(List<dynamic>) audioChangedListener) {
    _controller.audioChangedListener = audioChangedListener;
  }

  /// Progress of the consult call started with [startConsultCall].
  void setConsultStateListener(
      Function(OmiConsultStateEvent) consultStateListener) {
    _controller.consultStateListener = consultStateListener;
  }

  /// REFER progress of [transferCall] and [completeConsultTransfer].
  void setTransferStatusListener(
      Function(OmiTransferStatusEvent) transferStatusListener) {
    _controller.transferStatusListener = transferStatusListener;
  }

  /// Hold state of any call (customer or consult), with its call id.
  void setCallHoldChangedListener(
      Function(OmiCallHoldEvent) callHoldChangedListener) {
    _controller.callHoldChangedListener = callHoldChangedListener;
  }

  /// System Picture-in-Picture started (true) / stopped (false) — hide call controls while true.
  void setPictureInPictureListener(Function(bool) pictureInPictureListener) {
    _controller.pictureInPictureListener = pictureInPictureListener;
  }

  /// iOS: health of the other party's media during a video call.
  void setRemoteConnectionListener(
      Function(OmiRemoteConnectionEvent) remoteConnectionListener) {
    _controller.remoteConnectionListener = remoteConnectionListener;
  }

  void removePictureInPictureListener() {
    _controller.pictureInPictureListener = null;
  }

  void removeRemoteConnectionListener() {
    _controller.remoteConnectionListener = null;
  }

  void removeConsultStateListener() {
    _controller.consultStateListener = null;
  }

  void removeTransferStatusListener() {
    _controller.transferStatusListener = null;
  }

  void removeCallHoldChangedListener() {
    _controller.callHoldChangedListener = null;
  }

  void removeCallLogListener() {
    _controller.callLogListener = null;
  }

  void removeVideoListener() {
    _controller.videoListener = null;
  }

  void removeMuteListener() {
    _controller.muteListener = null;
  }

  void removeHoldListener() {
    _controller.holdListener = null;
  }

  void removeSpeakerListener() {
    _controller.speakerListener = null;
  }

  void removeMissedCallListener() {
    _controller.missedCallListener = null;
  }

  void removeCallQualityListener() {
    _controller.callQualityListener = null;
  }

  void removeAudioChangedListener() {
    _controller.audioChangedListener = null;
  }

  ///destroy event
  void dispose() {
    _controller.dispose();
  }

  Future<void> startServices({
    bool showMissedCall = true,
  }) async {
    final action = OmiAction(
      actionName: OmiActionName.START_SERVICES,
      data: {
        "showMissedCall": showMissedCall,
      },
    );
    return await _controller.action(action);
  }

  /// Register a SIP extension with username / password.
  ///
  /// [host] is the SIP proxy (`host` or `host:port`); leave it empty to use the OMICall default.
  /// [fcmToken] is the FCM token on Android and the APNS token on iOS.
  Future<OmiRegisterResult> register({
    required String userName,
    required String password,
    required String realm,
    required String fcmToken,
    String host = "",
    bool isVideo = true,
    String projectId = "",
  }) async {
    final action = OmiAction(
      actionName: OmiActionName.INIT_CALL_USER_PASSWORD,
      data: {
        'userName': userName,
        'password': password,
        'realm': realm,
        'host': host,
        'isVideo': isVideo,
        'fcmToken': fcmToken,
        'projectId': projectId,
      },
    );
    return OmiRegisterResult.fromNative(await _controller.action(action));
  }

  /// Register a customer (App-to-App) with an OMICall API key.
  ///
  /// [fcmToken] is the FCM token on Android and the APNS token on iOS.
  Future<OmiRegisterResult> registerWithApiKey({
    required String fullName,
    required String userUuid,
    required String apiKey,
    required String phone,
    required String fcmToken,
    bool isVideo = true,
    String projectId = "",
  }) async {
    final action = OmiAction(
      actionName: OmiActionName.INIT_CALL_API_KEY,
      data: {
        'fullName': fullName,
        'usrUuid': userUuid,
        'apiKey': apiKey,
        'phone': phone,
        'isVideo': isVideo,
        'fcmToken': fcmToken,
        'projectId': projectId,
      },
    );
    return OmiRegisterResult.fromNative(await _controller.action(action));
  }

  @Deprecated('Use registerWithApiKey(), which returns OmiRegisterResult')
  Future<dynamic> initCallWithApiKey({
    String? usrName,
    String? usrUuid,
    String? apiKey,
    String? phone,
    String? fcmToken,
    bool isVideo = true,
    String projectId = "",
  }) async {
    final action =
        OmiAction(actionName: OmiActionName.INIT_CALL_API_KEY, data: {
      'fullName': usrName,
      'usrUuid': usrUuid,
      'apiKey': apiKey,
      'phone': phone,
      'isVideo': isVideo,
      'fcmToken':fcmToken,
      'projectId': projectId
    });
    return await _controller.action(action);
  }

  Future<void> configPushNotification({
    required String notificationIcon,
    String? prefix,
    String? incomingBackgroundColor,
    String? incomingAcceptButtonImage,
    String? incomingDeclineButtonImage,
    String? backImage,
    String? userImage,
    String? missedCallTitle,
    String? prefixMissedCallMessage,
    String? userNameKey,
    String? channelId,
    String? videoNotificationDescription,
    String? audioNotificationDescription,
    String? representName,
    bool? isUseIntentFilter = true,
  }) async {
    final action = OmiAction(
      actionName: OmiActionName.CONFIG_NOTIFICATION,
      data: {
        'notificationIcon': notificationIcon,
        'prefix': prefix,
        'incomingBackgroundColor': incomingBackgroundColor,
        'incomingAcceptButtonImage': incomingAcceptButtonImage,
        'incomingDeclineButtonImage': incomingDeclineButtonImage,
        'backImage': backImage,
        'userImage': userImage,
        'missedCallTitle': missedCallTitle,
        'prefixMissedCallMessage': prefixMissedCallMessage,
        'userNameKey': userNameKey,
        'channelId': channelId,
        'audioNotificationDescription': audioNotificationDescription,
        'videoNotificationDescription': videoNotificationDescription,
        'representName': representName,
        'isUseIntentFilter': isUseIntentFilter
      },
    );
    return await _controller.action(action);
  }

  @Deprecated('Use register(), which returns OmiRegisterResult')
  Future<dynamic> initCallWithUserPassword({
  String? userName,
  String? password,
  String? realm,
  String? host,
  String? fcmToken,
  bool isVideo = true,
  String projectId = "",
}) async {
  final action = OmiAction(
    actionName: OmiActionName.INIT_CALL_USER_PASSWORD,
    data: {
      'userName': userName,
      'password': password,
      'realm': realm,
      'isVideo': isVideo,
      'fcmToken': fcmToken,
      'host': host,
      'projectId': projectId,
    },
  );
  return await _controller.action(action);
}

  Future<dynamic> startCall(
    String phoneNumber,
    bool isVideo,
  ) async {
    final action = OmiAction(actionName: OmiActionName.START_CALL, data: {
      'phoneNumber': phoneNumber,
      'isVideo': isVideo,
    });
    return await _controller.action(action);
  }

  Future<int> startCallWithUUID(
    String uuid,
    bool isVideo,
  ) async {
    final microphoneRequest = await Permission.microphone.request();
    if (microphoneRequest.isGranted) {
      final action =
          OmiAction(actionName: OmiActionName.START_CALL_WITH_UUID, data: {
        'usrUuid': uuid,
        'isVideo': isVideo,
      });
      return await _controller.action(action);
    }
    return OmiStartCallStatus.permissionDenied.rawValue;
  }

  Future<dynamic> getInitialCall() async {
    final action = OmiAction(
      actionName: OmiActionName.GET_INITIAL_CALL,
      data: {},
    );
    final result = await _controller.action(action);
    return result;
  }

  Future<bool> joinCall() async {
    final microphoneRequest = await Permission.microphone.request();
    if (microphoneRequest.isGranted) {
      final action = OmiAction(
        actionName: OmiActionName.JOIN_CALL,
        data: {},
      );
      await _controller.action(action);
      return true;
    }
    return false;
  }

  Future<Map?> endCall() async {
    final action = OmiAction(
      actionName: OmiActionName.END_CALL,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> toggleAudio() async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_MUTE,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> toggleSpeaker() async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_SPEAK,
      data: {},
    );
    return await _controller.action(action);
  }

   Future<void> toggleHold() async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_HOLD,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> sendDTMF(String character) async {
    final action = OmiAction(
      actionName: OmiActionName.SEND_DTMF,
      data: {
        'character': character,
      },
    );
    return await _controller.action(action);
  }

  Future<void> switchCamera() async {
    final action = OmiAction(
      actionName: OmiActionName.SWITCH_CAMERA,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> getCameraStatus() async {
    final action = OmiAction(
      actionName: OmiActionName.CAMERA_STATUS,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> toggleVideo() async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_VIDEO,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<List<dynamic>> getOutputAudios() async {
    final action = OmiAction(
      actionName: OmiActionName.GET_AUDIO,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> setOutputAudio({required dynamic portType}) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_AUDIO,
      data: {
        "portType": portType,
      },
    );
    return await _controller.action(action);
  }

  Future<dynamic> logout() async {
    final action = OmiAction(
      actionName: OmiActionName.LOG_OUT,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<dynamic> registerVideoEvent() async {
    final action = OmiAction(
      actionName: OmiActionName.REGISTER_VIDEO_EVENT,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<dynamic> removeVideoEvent() async {
    final action = OmiAction(
      actionName: OmiActionName.REMOVE_VIDEO_EVENT,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<Map?> getCurrentUser() async {
    final action = OmiAction(
      actionName: OmiActionName.GET_CURRENT_USER,
      data: {},
    );
    final result = await _controller.action(action);
    if (result != null) {
      return result as Map;
    }
    return null;
  }

  Future<Map?> getGuestUser() async {
    final action = OmiAction(
      actionName: OmiActionName.GET_GUEST_USER,
      data: {},
    );
    final result = await _controller.action(action);
    if (result != null) {
      return result as Map;
    }
    return null;
  }

  Future<Map?> getUserInfo({required String phone}) async {
    final action = OmiAction(
      actionName: OmiActionName.GET_USER_INFO,
      data: {
        "phone": phone,
      },
    );
    final result = await _controller.action(action);
    if (result != null) {
      return result as Map;
    }
    return null;
  }

  Future<String?> getHistoryCallLog() async {
    final action = OmiAction(
      actionName: OmiActionName.GET_HISTORY_CALL_LOG,
      data: {},
    );
    final result = await _controller.action(action);
    if (result != null) {
      return result as String?;
    }
    return null;
  }

  Future<List<dynamic>> getCurrentAudio() async {
    final action = OmiAction(
      actionName: OmiActionName.GET_CURRENT_AUDIO,
      data: {},
    );
    final result = await _controller.action(action);
    return result;
  }

  Future<Map?> changeTransport({required String type}) async {
    final action = OmiAction(
      actionName: OmiActionName.CHANGE_TRANSPORT,
      data: {
        "type": type,
      },
    );
    final result = await _controller.action(action);
    if (result != null) {
      return result as Map;
    }
    return null;
  }

  Future<bool> transferCall({
    String? phoneNumber
  }) async {
    final action = OmiAction(actionName: OmiActionName.TRANSFER_CALL, data: { 'phoneNumber': phoneNumber});
    return await _controller.action(action);
  }

  /// Reject a ringing incoming call with 486 Busy Here (other devices of the same
  /// extension can still answer). Hangs up when the call is already answered.
  Future<bool> rejectCall() async {
    final action = OmiAction(actionName: OmiActionName.REJECT_CALL, data: {});
    return await _controller.action(action) == true;
  }

  /// Decline a ringing incoming call with 603, which stops ringing on every device of the
  /// extension. Hangs up when the call is already answered.
  Future<bool> dropCall() async {
    final action = OmiAction(actionName: OmiActionName.DROP_CALL, data: {});
    return await _controller.action(action) == true;
  }

  /// Consult (attended) transfer, step 1: hold the customer (answered audio call) and call
  /// [extension]. Follow the consult with [setConsultStateListener].
  Future<OmiConsultStartStatus> startConsultCall(
    String extension, {
    Map<String, String>? extraHeaders,
  }) async {
    final action = OmiAction(
      actionName: OmiActionName.START_CONSULT_CALL,
      data: {
        'extension': extension,
        'extraHeaders': extraHeaders,
      },
    );
    final result = await _controller.action(action);
    return ExtensionOmiConsultStartStatus.fromRaw(result);
  }

  /// Consult transfer, step 2a: once the consult is answered, hang it up and transfer the
  /// customer to the same extension. Returns false when there is no answered consult or the
  /// customer already ended. Follow the result with [setTransferStatusListener].
  Future<bool> completeConsultTransfer({
    Map<String, String>? extraHeaders,
  }) async {
    final action = OmiAction(
      actionName: OmiActionName.COMPLETE_CONSULT_TRANSFER,
      data: {'extraHeaders': extraHeaders},
    );
    return await _controller.action(action) == true;
  }

  /// Consult transfer, step 2b: end the consult and take the customer off hold.
  /// [endCall] is not a cancel: during a consult it hangs up the customer.
  Future<bool> cancelConsult() async {
    final action = OmiAction(actionName: OmiActionName.CANCEL_CONSULT, data: {});
    return await _controller.action(action) == true;
  }

  /// True from [startConsultCall] until the consult call has ended.
  Future<bool> isConsulting() async {
    final action = OmiAction(actionName: OmiActionName.IS_CONSULTING, data: {});
    return await _controller.action(action) == true;
  }

  /// True while a consult is running but the customer already hung up.
  Future<bool> isConsultOriginalEnded() async {
    final action = OmiAction(
      actionName: OmiActionName.IS_CONSULT_ORIGINAL_ENDED,
      data: {},
    );
    return await _controller.action(action) == true;
  }

  /// Every live call with its hold state; the consult call has `isConsult == true`.
  Future<List<OmiCallSummary>> getActiveCalls() async {
    final action = OmiAction(actionName: OmiActionName.GET_ACTIVE_CALLS, data: {});
    final result = await _controller.action(action);
    if (result is! List) return [];
    return result
        .whereType<Map>()
        .map((e) => OmiCallSummary.fromMap(e))
        .toList();
  }

  /// Picture-in-Picture for video calls: the remote video moves to a floating window when the
  /// app goes to the background during a video call, and the SDK closes it at call end.
  /// Call before the video call starts. Returns whether the device supports PiP.
  ///
  /// Android: add `android:supportsPictureInPicture="true"` and `android:resizeableActivity="true"`
  /// to MainActivity and forward `onUserLeaveHint` / `onPictureInPictureModeChanged` to
  /// `OmicallsdkPlugin`. iOS 15+: needs `audio` in UIBackgroundModes; add the
  /// `com.apple.developer.avfoundation.multitasking-camera-access` entitlement to keep sending
  /// your camera while in PiP.
  Future<bool> setVideoPictureInPictureEnabled(bool enabled) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_PICTURE_IN_PICTURE,
      data: {'enabled': enabled},
    );
    return await _controller.action(action) == true;
  }

  /// iOS: text of the SDK's remote-connection overlay per state (multi-language apps).
  /// States without a text keep the SDK's Vietnamese default. No effect on Android.
  Future<void> setRemoteConnectionOverlayTexts(
      Map<OmiRemoteConnectionState, String> texts) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_REMOTE_CONNECTION_TEXTS,
      data: {
        'texts': texts.map((state, text) => MapEntry(state.nativeName, text)),
      },
    );
    await _controller.action(action);
  }

  // MARK: - Device info (same names and behaviour as the React Native SDK)

  Future<String?> _getString(String actionName) async {
    final result = await _controller.action(OmiAction(actionName: actionName, data: {}));
    return result is String && result.isNotEmpty ? result : null;
  }

  Future<bool> _getBool(String actionName) async {
    return await _controller.action(OmiAction(actionName: actionName, data: {})) == true;
  }

  /// Firebase project id used when the device was added to the OMI backend.
  Future<String?> getProjectId() => _getString(OmiActionName.GET_PROJECT_ID);

  /// Current SIP account (`user@realm` on Android).
  Future<String?> getSipInfo() => _getString(OmiActionName.GET_SIP_INFO);

  /// App id the SDK sends when adding the device (bundle id / package name).
  Future<String?> getAppId() => _getString(OmiActionName.GET_APP_ID);

  /// Device id the SDK sends when adding the device — match it against [getOmiDevices].
  Future<String?> getDeviceId() => _getString(OmiActionName.GET_DEVICE_ID);

  /// Push token the SDK registered (FCM on Android).
  Future<String?> getFcmToken() => _getString(OmiActionName.GET_FCM_TOKEN);

  /// iOS VoIP (PushKit) token; null on Android.
  Future<String?> getVoipToken() => _getString(OmiActionName.GET_VOIP_TOKEN);

  /// Devices registered on the OMI backend for the current SIP user. Empty when not logged in
  /// or on network failure; never throws. Each call is an HTTP request — do not poll.
  Future<List<OmiDeviceInfo>> getOmiDevices() async {
    final result = await _controller
        .action(OmiAction(actionName: OmiActionName.GET_OMI_DEVICES, data: {}));
    if (result is! List) return [];
    return result.whereType<Map>().map((e) => OmiDeviceInfo.fromMap(e)).toList();
  }

  /// Whether THIS device (device id + app id) is registered on the backend for the current
  /// SIP user. False when not logged in.
  Future<bool> isCurrentDeviceRegistered() =>
      _getBool(OmiActionName.IS_CURRENT_DEVICE_REGISTERED);

  /// True when a SIP user is set locally but the backend has no matching device:
  /// logout + login again to re-register. False when not logged in.
  Future<bool> needsReLogin() => _getBool(OmiActionName.NEEDS_RE_LOGIN);

  /// SIP number bound to [deviceId] in a list from [getOmiDevices], or null when none matches.
  String? findSipNumberByDeviceId(List<OmiDeviceInfo>? devices, String? deviceId) {
    if (devices == null || devices.isEmpty || deviceId == null || deviceId.isEmpty) {
      return null;
    }
    for (final d in devices) {
      if (d.deviceId == deviceId) return d.sipNumber;
    }
    return null;
  }
}
