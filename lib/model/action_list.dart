import '../constant/enums.dart';
import 'action_model.dart';

class OmiAction {
  static ActionModel initCall(
      String userName,
      String password,
      String realm,
      ) {
    return ActionModel(actionName: OmiActionName.INIT_CALL, data: {
      'userName': userName,
      'password': password,
      'realm': realm,
    });
  }

  static ActionModel updateToken(
      String deviceId,
      String appId, {
        String? deviceTokenAndroid,
        String? tokenVoipIos,
      }) {
    return ActionModel(actionName: OmiActionName.UPDATE_TOKEN, data: {
      'deviceTokenAndroid': deviceTokenAndroid,
      'tokenVoipIos': tokenVoipIos,
      'appId': appId,
      'deviceId': deviceId,
    });
  }

  static ActionModel startCall(
      String phoneNumber,
      bool isTransfer,
      ) {
    return ActionModel(actionName: OmiActionName.START_CALL, data: {
      'phoneNumber': phoneNumber,
      'isTransfer': isTransfer,
    });
  }

  static ActionModel endCall() {
    return ActionModel(
      actionName: OmiActionName.END_CALL,
      data: {},
    );
  }

  static ActionModel startOmiService() {
    return ActionModel(
      actionName: OmiActionName.START_OMI_SERVICE,
      data: {},
    );
  }

  static ActionModel toggleMute() {
    return ActionModel(
      actionName: OmiActionName.TOGGLE_MUTE,
      data: {},
    );
  }

  static ActionModel toggleSpeaker(bool useSpeaker) {
    return ActionModel(
      actionName: OmiActionName.TOGGLE_SPEAK,
      data: {
        'useSpeaker': useSpeaker,
      },
    );
  }

  static ActionModel decline() {
    return ActionModel(
      actionName: OmiActionName.DECLINE,
      data: {},
    );
  }

  static ActionModel hangUp(int callId) {
    return ActionModel(
      actionName: OmiActionName.HANGUP,
      data: {
        'callId': callId,
      },
    );
  }

  static ActionModel onMute(bool isMute) {
    return ActionModel(
      actionName: OmiActionName.ON_MUTE,
      data: {
        'isMute': isMute,
      },
    );
  }

  static ActionModel onHold(bool isHold) {
    return ActionModel(
      actionName: OmiActionName.ON_HOLD,
      data: {
        'isHold': isHold,
      },
    );
  }

  /*
  * This action using only for android
  * */
  static ActionModel pickUp(bool isHold) {
    return ActionModel(
      actionName: OmiActionName.ON_HOLD,
      data: {
        'isHold': isHold,
      },
    );
  }

  static ActionModel sendDTMF(String character) {
    return ActionModel(
      actionName: OmiActionName.SEND_DTMF,
      data: {
        'character': character,
      },
    );
  }
}