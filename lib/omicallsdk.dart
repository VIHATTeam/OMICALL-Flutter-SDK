import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:omicall_flutter_plugin/model/action_model.dart';
import 'omicall.dart';
import 'omicallsdk_platform_interface.dart';

class OmicallClient {
  OmicallClient._() {
    OmicallSDKPlatform.instance.listenerEvent((action) {
      _eventBus.fire(OmiEvent(data: action));
    });
  }

  factory OmicallClient() {
    return OmicallClient._();
  }

  final OmicallSDKPlatform _instance = OmicallSDKPlatform.instance;
  final _eventBus = EventBus();

  ///subscribe event
  Stream<OmiEvent> subscriptionEvent() {
    return _eventBus.on<OmiEvent>();
  }

  ///streaming camera event
  Stream<dynamic> cameraEvent() {
    return OmicallSDKPlatform.instance.cameraEvent();
  }

  ///streaming mic event
  Stream<dynamic> micEvent() {
    return OmicallSDKPlatform.instance.micEvent();
  }

  ///destroy event
  void destroy() {
    _eventBus.destroy();
  }

  Future<dynamic> action({required ActionModel action}) {
    return _instance.action(action);
  }

  Future<void> initCall({
    required String userName,
    required String password,
    required String realm,
    bool isVideo = false,
  }) async {
    final action = ActionModel(actionName: OmiActionName.INIT_CALL, data: {
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
    final action = ActionModel(actionName: OmiActionName.UPDATE_TOKEN, data: {
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
    final action = ActionModel(actionName: OmiActionName.START_CALL, data: {
      'phoneNumber': phoneNumber,
      'isVideo': isVideo,
    });
    return await _instance.action(action);
  }

  Future<void> endCall() async {
    final action = ActionModel(
      actionName: OmiActionName.END_CALL,
      data: {},
    );
    return await _instance.action(action);
  }

  Future<void> startOmiService() async {
    final action = ActionModel(
      actionName: OmiActionName.START_OMI_SERVICE,
      data: {},
    );
    return await _instance.action(action);
  }

  Future<void> toggleMute() async {
    final action = ActionModel(
      actionName: OmiActionName.TOGGLE_MUTE,
      data: {},
    );
    return await _instance.action(action);
  }

  Future<void> toggleSpeaker(bool useSpeaker) async {
    final action = ActionModel(
      actionName: OmiActionName.TOGGLE_SPEAK,
      data: {
        'useSpeaker': useSpeaker,
      },
    );
    return await _instance.action(action);
  }

  Future<void> decline() async {
    final action = ActionModel(
      actionName: OmiActionName.DECLINE,
      data: {},
    );
    return await _instance.action(action);
  }

  Future<void> hangUp(int callId) async {
    final action = ActionModel(
      actionName: OmiActionName.HANGUP,
      data: {
        'callId': callId,
      },
    );
    return await _instance.action(action);
  }

  Future<void> onMute(bool isMute) async {
    final action = ActionModel(
      actionName: OmiActionName.ON_MUTE,
      data: {
        'isMute': isMute,
      },
    );
    return await _instance.action(action);
  }

  Future<void> onHold(bool isHold) async {
    final action = ActionModel(
      actionName: OmiActionName.ON_HOLD,
      data: {
        'isHold': isHold,
      },
    );
    return await _instance.action(action);
  }

  /*
  * This action using only for android
  * */
  Future<void> pickUp(bool isHold) async {
    final action = ActionModel(
      actionName: OmiActionName.ON_HOLD,
      data: {
        'isHold': isHold,
      },
    );
    return await _instance.action(action);
  }

  Future<void> sendDTMF(String character) async {
    final action = ActionModel(
      actionName: OmiActionName.SEND_DTMF,
      data: {
        'character': character,
      },
    );
    return await _instance.action(action);
  }

  Future<void> switchCamera() async {
    final action = ActionModel(
      actionName: OmiActionName.SWITCH_CAMERA,
      data: {

      },
    );
    return await _instance.action(action);
  }

  Future<void> cameraStatus() async {
    final action = ActionModel(
      actionName: OmiActionName.CAMERA_STATUS,
      data: {
      },
    );
    return await _instance.action(action);
  }

  Future<void> toggleVideo() async {
    final action = ActionModel(
      actionName: OmiActionName.TOGGLE_VIDEO,
      data: {
      },
    );
    return await _instance.action(action);
  }

  Future<dynamic> outputs() async {
    final action = ActionModel(
      actionName: OmiActionName.OUTOUTS,
      data: {
      },
    );
    return await _instance.action(action);
  }

  Future<void> setOutput({required String id}) async {
    final action = ActionModel(
      actionName: OmiActionName.SET_OUTPUT,
      data: {
        "id": id,
      },
    );
    return await _instance.action(action);
  }

  Future<dynamic> inputs() async {
    final action = ActionModel(
      actionName: OmiActionName.INPUTS,
      data: {
      },
    );
    return await _instance.action(action);
  }
  Future<void> setInput({required String id}) async {
    final action = ActionModel(
      actionName: OmiActionName.SET_INPUT,
      data: {
        "id": id,
      },
    );
    return await _instance.action(action);
  }
}
