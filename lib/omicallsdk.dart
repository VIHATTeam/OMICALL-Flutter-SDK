import 'dart:async';
import 'package:omicall_flutter_plugin/omicallsdk_method_channel.dart';
import 'action/action_model.dart';
import 'omicall.dart';

class OmicallClient {

  OmicallClient._();

  factory OmicallClient() {
    return OmicallClient._();
  }

  final OmicallSDKController _instance = OmicallSDKController();


  OmicallSDKController get controller => _instance;

  ///streaming camera event
  Stream<dynamic> cameraEvent() {
    return _instance.cameraEvent();
  }

  ///streaming mic event
  Stream<dynamic> micEvent() {
    return _instance.micEvent();
  }

  ///destroy event
  void dispose() {
    _instance.dispose();
  }

  Future<dynamic> action({required OmiAction action}) {
    return _instance.action(action);
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
    return await _instance.action(action);
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
    return await _instance.action(action);
  }

  Future<void> startCall(
      String phoneNumber,
      bool isVideo,
      ) async {
    final action = OmiAction(actionName: OmiActionName.START_CALL, data: {
      'phoneNumber': phoneNumber,
      'isVideo': isVideo,
    });
    return await _instance.action(action);
  }

  Future<void> endCall() async {
    final action = OmiAction(
      actionName: OmiActionName.END_CALL,
      data: {},
    );
    return await _instance.action(action);
  }

  Future<void> startOmiService() async {
    final action = OmiAction(
      actionName: OmiActionName.START_OMI_SERVICE,
      data: {},
    );
    return await _instance.action(action);
  }

  Future<void> toggleMicrophone() async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_MUTE,
      data: {},
    );
    return await _instance.action(action);
  }

  Future<void> toggleSpeaker(bool useSpeaker) async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_SPEAK,
      data: {
        'useSpeaker': useSpeaker,
      },
    );
    return await _instance.action(action);
  }

  Future<void> sendDTMF(String character) async {
    final action = OmiAction(
      actionName: OmiActionName.SEND_DTMF,
      data: {
        'character': character,
      },
    );
    return await _instance.action(action);
  }

  Future<void> switchCamera() async {
    final action = OmiAction(
      actionName: OmiActionName.SWITCH_CAMERA,
      data: {

      },
    );
    return await _instance.action(action);
  }

  Future<void> getCameraStatus() async {
    final action = OmiAction(
      actionName: OmiActionName.CAMERA_STATUS,
      data: {
      },
    );
    return await _instance.action(action);
  }

  Future<void> toggleVideo() async {
    final action = OmiAction(
      actionName: OmiActionName.TOGGLE_VIDEO,
      data: {
      },
    );
    return await _instance.action(action);
  }

  Future<dynamic> getOutputAudios() async {
    final action = OmiAction(
      actionName: OmiActionName.OUTOUTS,
      data: {
      },
    );
    return await _instance.action(action);
  }

  Future<void> setOutputAudio({required String id}) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_OUTPUT,
      data: {
        "id": id,
      },
    );
    return await _instance.action(action);
  }

  Future<dynamic> getInputAudios() async {
    final action = OmiAction(
      actionName: OmiActionName.INPUTS,
      data: {
      },
    );
    return await _instance.action(action);
  }
  Future<void> setInputAudio({required String id}) async {
    final action = OmiAction(
      actionName: OmiActionName.SET_INPUT,
      data: {
        "id": id,
      },
    );
    return await _instance.action(action);
  }
}
