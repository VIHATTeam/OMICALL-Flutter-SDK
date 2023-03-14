import 'dart:async';

import 'package:omicall_flutter_plugin/omicallsdk_method_channel.dart';

import 'action/action_model.dart';
import 'constant/names.dart';

class OmicallClient {

  OmicallClient._();
  
  static final _instance = OmicallClient._();

  factory OmicallClient() => _instance;

  final OmicallSDKController _controller = OmicallSDKController();


  OmicallSDKController get controller => _controller;

  ///streaming camera event
  Stream<dynamic> cameraEvent() {
    return _controller.cameraEvent();
  }

  ///streaming mic event
  Stream<dynamic> onMicEvent() {
    return _controller.onMicEvent();
  }

  ///streaming mic event
  Stream<dynamic> onMuteEvent() {
    return _controller.onMuteEvent();
  }

  ///destroy event
  void dispose() {
    _controller.dispose();
  }

  Future<dynamic> action({required OmiAction action}) {
    return _controller.action(action);
  }

  Future<void> initCall({
    required String userName,
    required String password,
    required String realm,
    bool isVideo = false,
  }) async {
    final action = OmiAction(actionName: OmiActionName.INIT_CALL, data: {
      'userName': userName,
      'password': password,
      'realm': realm,
      'isVideo': isVideo,
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
      data: {

      },
    );
    return await _controller.action(action);
  }

  Future<void> getCameraStatus() async {
    final action = OmiAction(
      actionName: OmiActionName.CAMERA_STATUS,
      data: {
      },
    );
    return await _controller.action(action);
  }

  Future<void> toggleVideo() async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_VIDEO,
      data: {
      },
    );
    return await _controller.action(action);
  }

  Future<dynamic> getOutputAudios() async {
    final action = OmiAction(
      actionName: OmiActionName.OUTPUTS,
      data: {
      },
    );
    return await _controller.action(action);
  }

  Future<void> setOutputAudio({required String id}) async {
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
      data: {
      },
    );
    return await _controller.action(action);
  }
  Future<void> setInputAudio({required String id}) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_INPUT,
      data: {
        "id": id,
      },
    );
    return await _controller.action(action);
  }
}
