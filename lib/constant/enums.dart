
// ignore_for_file: constant_identifier_names

class OmiActionName {
  static const String INIT_CALL = "INIT_CALL";
  static const String UPDATE_TOKEN = "UPDATE_TOKEN";
  static const String START_OMI_SERVICE = "START_OMI_SERVICE";
  static const String START_CALL = "START_CALL";
  static const String END_CALL = "END_CALL";
  static const String TOGGLE_MUTE = "TOGGLE_MUTE";
  static const String TOGGLE_SPEAK = "TOGGLE_SPEAK";
  static const String CHECK_ON_GOING_CALL = "CHECK_ON_GOING_CALL";
  static const String DECLINE = "DECLINE";
  static const String FORWARD_CALL_TO = "FORWARD_CALL_TO";
  static const String HANGUP = "HANGUP";
  static const String PICK_UP = "PICK_UP";
  static const String ON_CALL_STARTED = "ON_CALL_STARTED";
  static const String ON_HOLD = "ON_HOLD";
  static const String ON_IN_COMING_RECEIVE = "ON_IN_COMING_RECEIVE";
  static const String ON_MUTE = "ON_MUTE";
  static const String ON_OUT_GOING = "ON_OUT_GOING";
  static const String ON_OUT_GOING_STARTED = "ON_OUT_GOING";
  static const String REGISTER = "REGISTER";
  static const String UPDATE_PUSH_TOKEN = "UPDATE_PUSH_TOKEN";
  static const String SEND_DTMF = "SEND_DTMF";
  static const String SWITCH_CAMERA = "SWITCH_CAMERA";
  static const String CAMERA_STATUS = "CAMERA_STATUS";
  static const String TOGGLE_VIDEO = "TOGGLE_VIDEO";
  static const String OUTOUTS = "OUTOUTS";
  static const String INPUTS = "INPUTS";
  static const String SET_INPUT = "SET_INPUT";
  static const String SET_OUTPUT = "SET_OUTPUT";
}

class OmiEventList {
  static const String onCallEnd = "onCallEnd";
  static const String incomingReceived = "incomingReceived";
  static const String onCallEstablished = "onCallEstablished";
  static const String onConnectionTimeout = "onConnectionTimeout";
  static const String onHold = "onHold";
  static const String onMuted = "onMuted";
  static const String onRinging = "onRinging";

}
enum DeviceType {
  ANDROID,IOS

}
