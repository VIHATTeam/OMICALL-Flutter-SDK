import 'dart:async';

import 'package:omicallsdk/constant/enums.dart';
import 'package:omicallsdk/model/action_model.dart';
import 'package:omicallsdk/omicallsdk.dart';

class OmiChannel {
  final Omicallsdk _micallsdk = Omicallsdk();

  Future<dynamic> action({required ActionModel action}) {
    return _micallsdk.action(action);
  }

}

class OmiAction {
  static ActionModel initCall(String userName, String password, String realm) {
    return ActionModel(
        actionName: ActionName.INIT_CALL,
        data: {'userName': userName, 'password': password, 'realm': realm});
  }

  static ActionModel updateToken(String deviceId, String appId,
      {String? deviceTokenAndroid, String? tokenVoipIos}) {
    return ActionModel(actionName: ActionName.UPDATE_TOKEN, data: {
      'deviceTokenAndroid': deviceTokenAndroid,
      'tokenVoipIos': tokenVoipIos,
      'appId': appId,
      'deviceId': deviceId,
    });
  }

  static ActionModel startCall(String phoneNumber, bool isTransfer) {
    return ActionModel(actionName: ActionName.START_CALL, data: {
      'phoneNumber': phoneNumber,
      'isTransfer': isTransfer,
    });
  }

  static ActionModel endCall(String phoneNumber) {
    return ActionModel(actionName: ActionName.END_CALL, data: {});
  }

  static ActionModel startOmiService() {
    return ActionModel(actionName: ActionName.START_OMI_SERVICE, data: {});
  }

  static ActionModel toggleMute() {
    return ActionModel(
        actionName: ActionName.TOGGLE_MUTE, data: {});
  }

  static ActionModel toggleSpeaker(bool useSpeaker) {
    return ActionModel(
        actionName: ActionName.TOGGLE_SPEAK, data: {'useSpeaker': useSpeaker});
  }

  static ActionModel decline() {
    return ActionModel(actionName: ActionName.DECLINE, data: {});
  }

  static ActionModel hangUp(int callId) {
    return ActionModel(actionName: ActionName.HANGUP, data: {'callId':callId});
  }

  static ActionModel onMute(bool isMute) {
    return ActionModel(actionName: ActionName.ON_MUTE, data: {'isMute':isMute});
  }

  static ActionModel onHold(bool isHold) {
    return ActionModel(actionName: ActionName.ON_HOLD, data: {'isHold':isHold});
  }
}
