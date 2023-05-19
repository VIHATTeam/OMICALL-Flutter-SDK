import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

import 'action/action_model.dart';
import 'constant/names.dart';
import 'omicallsdk_controller.dart';

class OmicallClient {
  OmicallClient._();

  static final instance = OmicallClient._();

  final OmicallSDKController _controller = OmicallSDKController();

  ///streaming camera event
  Stream<OmiAction> get callStateChangeEvent => _controller.callStateChangeEvent;
  ///streaming camera event
  Stream<Map<String, dynamic>> get videoEvent => _controller.videoEvent;
  ///streaming mic event
  Stream<bool> get micEvent => _controller.micEvent;
  ///streaming mic event
  Stream<bool> get mutedEvent => _controller.mutedEvent;
  ///streaming click missed call
  Stream<Map> get missedCallEvent => _controller.missedCallEvent;

  ///destroy event
  void dispose() {
    _controller.dispose();
  }

  Future<void> startServices() async {
    final action = OmiAction(
      actionName: OmiActionName.START_SERVICES,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<bool> initCallWithApiKey({
    String? usrName,
    String? usrUuid,
    String? apiKey,
    bool isVideo = true,
  }) async {
    final action =
        OmiAction(actionName: OmiActionName.INIT_CALL_API_KEY, data: {
      'fullName': usrName,
      'usrUuid': usrUuid,
      'apiKey': apiKey,
      'isVideo': isVideo,
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
        'channelId' : channelId,
      },
    );
    return await _controller.action(action);
  }

  Future<bool> initCallWithUserPassword({
    String? userName,
    String? password,
    String? realm,
    String? host,
    bool isVideo = true,
  }) async {
    final action =
        OmiAction(actionName: OmiActionName.INIT_CALL_USER_PASSWORD, data: {
      'userName': userName,
      'password': password,
      'realm': realm,
      'isVideo': isVideo,
      'host': host,
    });
    return await _controller.action(action);
  }

  Future<void> updateToken({
    String? fcmToken,
    String? apnsToken,
  }) async {
    final action = OmiAction(actionName: OmiActionName.UPDATE_TOKEN, data: {
      'fcmToken': fcmToken,
      'apnsToken': apnsToken,
    });
    return await _controller.action(action);
  }

  Future<bool> startCall(
    String phoneNumber,
    bool isVideo,
  ) async {
    //check permission
    final microphoneRequest = await Permission.microphone.request();
    if (microphoneRequest.isGranted) {
      final action = OmiAction(actionName: OmiActionName.START_CALL, data: {
        'phoneNumber': phoneNumber,
        'isVideo': isVideo,
      });
      return await _controller.action(action);
    }
    return false;
  }

  Future<bool> startCallWithUUID(
      String uuid,
      bool isVideo,
      ) async {
    final microphoneRequest = await Permission.microphone.request();
    if (microphoneRequest.isGranted) {
      final action = OmiAction(actionName: OmiActionName.START_CALL_WITH_UUID, data: {
        'usrUuid': uuid,
        'isVideo': isVideo,
      });
      return await _controller.action(action);
    }
    return false;
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

  Future<dynamic> getOutputAudios() async {
    final action = OmiAction(
      actionName: OmiActionName.OUTPUTS,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> setOutputAudio({required dynamic id}) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_OUTPUT,
      data: {
        "id": id,
      },
    );
    return await _controller.action(action);
  }

  Future<dynamic> getInputAudios() async {
    final action = OmiAction(
      actionName: OmiActionName.INPUTS,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> setInputAudio({required dynamic id}) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_INPUT,
      data: {
        "id": id,
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
}
