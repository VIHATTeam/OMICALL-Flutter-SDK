import 'dart:core';
import 'dart:core';
import 'dart:ffi';


class OmiAction {
  final String actionName;
  final Map<dynamic, dynamic> data;

  OmiAction({
    required this.actionName,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'actionName': actionName,
      'data': data,
    };
  }
}


enum OmiCallState {
  calling,
  early,
  connecting,
  confirmed,
  incoming,
  disconnected,
  hold,
}

extension ExtensionCallState on OmiCallState {
  int get rawValue {
    return index;
  }
}

enum OmiStartCallStatus {
  invalidUuid,
  invalidPhoneNumber,
  samePhoneNumber,
  maxRetry,
  permissionDenied,
  couldNotFindEndpoint,
  accountRegisterFailed,
  startCallFailed,
  startCallSuccess,
  haveAnotherCall,
}

extension ExtensionOmiStartCallStatus on OmiStartCallStatus {
  int get rawValue {
    return index;
  }
}

class OmiStartCallModel {
  late final int status;
  late final OmiCallModel callInfo;
  late final String message;
}


class OmiCallModel {
  int callId;
  bool incoming;
  int callState;
  String callerNumber;
  bool isVideo;
  String omiId;
  String uuid;
  String callerName;
  bool muted;
  bool speaker;
  bool onHold;
  String numberToCall;
  bool connected;
  double totalMBsUsed;
  double mos;
  double latency;
  double jitter;
  double ppl;

  OmiCallModel({
    required this.callId,
    required this.incoming,
    required this.callState,
    required this.callerNumber,
    required this.isVideo,
    required this.omiId,
    required this.uuid,
    required this.callerName,
    required this.muted,
    required this.speaker,
    required this.onHold,
    required this.numberToCall,
    required this.connected,
    required this.totalMBsUsed,
    required this.mos,
    required this.latency,
    required this.jitter,
    required this.ppl,
  });

  factory OmiCallModel.fromJson(Map<String, dynamic> json) {
    return OmiCallModel(
      callId: json['callId'],
      incoming: json['incoming'],
      callState: json['callState'],
      callerNumber: json['callerNumber'],
      isVideo: json['isVideo'],
      omiId: json['omiId'],
      uuid: json['uuid'],
      callerName: json['callerName'],
      muted: json['muted'],
      speaker: json['speaker'],
      onHold: json['onHold'],
      numberToCall: json['numberToCall'],
      connected: json['connected'],
      totalMBsUsed: json['totalMBsUsed'],
      mos: json['mos'],
      latency: json['latency'],
      jitter: json['jitter'],
      ppl: json['ppl'],
    );
  }
}