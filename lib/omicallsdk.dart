import 'dart:async';

import 'package:omicall_flutter_plugin/omicallsdk_method_channel.dart';

import 'action/action_model.dart';
import 'constant/names.dart';

class OmicallClient {
  OmicallClient._();

  static final instance = OmicallClient._();

  final OmicallSDKController _controller = OmicallSDKController();

  ///streaming camera event
  Stream<OmiAction> get callStateChangeEvent => _controller.callStateChangeEvent;
  ///streaming camera event
  Stream<bool> get cameraEvent => _controller.cameraEvent;
  ///streaming mic event
  Stream<bool> get micEvent => _controller.micEvent;
  ///streaming mic event
  Stream<bool> get mutedEvent => _controller.mutedEvent;

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

  Future<void> initCallWithApiKey({
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
    String? prefix,
    String? declineTitle,
    String? acceptTitle,
    String? acceptBackgroundColor,
    String? declineBackgroundColor,
    String? incomingBackgroundColor,
    String? incomingAcceptButtonImage,
    String? incomingDeclineButtonImage,
    String? backImage,
    String? userImage,
  }) async {
    final action = OmiAction(
      actionName: OmiActionName.CONFIG_NOTIFICATION,
      data: {
        'prefix': prefix,
        'declineTitle': declineTitle,
        'acceptTitle': acceptTitle,
        'acceptBackgroundColor': acceptBackgroundColor,
        'declineBackgroundColor': declineBackgroundColor,
        'incomingBackgroundColor': incomingBackgroundColor,
        'incomingAcceptButtonImage': incomingAcceptButtonImage,
        'incomingDeclineButtonImage': incomingDeclineButtonImage,
        'backImage': backImage,
        'userImage': userImage,
      },
    );
    return await _controller.action(action);
  }

  Future<void> initCallWithUserPassword({
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

  Future<void> updateToken(
    String deviceId,
    String appId, {
    String? fcmToken,
    String? apnsToken,
  }) async {
    final action = OmiAction(actionName: OmiActionName.UPDATE_TOKEN, data: {
      'fcmToken': fcmToken,
      'apnsToken': apnsToken,
      'appId': appId,
      'deviceId': deviceId,
    });
    return await _controller.action(action);
  }

  Future<void> startCall(
    String phoneNumber,
    bool isVideo,
  ) async {
    final action = OmiAction(actionName: OmiActionName.START_CALL, data: {
      'phoneNumber': phoneNumber,
      'isVideo': isVideo,
    });
    return await _controller.action(action);
  }

  Future<void> joinCall() async {
    final action = OmiAction(
      actionName: OmiActionName.JOIN_CALL,
      data: {},
    );
    return await _controller.action(action);
  }

  Future<void> endCall() async {
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
}
