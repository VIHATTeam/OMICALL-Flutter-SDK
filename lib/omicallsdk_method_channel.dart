import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:omicall_flutter_plugin/constant/enums.dart';

import 'action/action_model.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class OmicallSDKController {
  /// The method channel used to interact with the native platform.

  final _methodChannel = const MethodChannel('omicallsdk');
  final _cameraChannel = const EventChannel('event/camera');
  final _micChannel = const EventChannel('event/mic');
  final StreamController<OmiAction> _eventTransfer =
      StreamController<OmiAction>.broadcast();

  OmicallSDKController() {
    _methodChannel.setMethodCallHandler(_omicallSDKMethodCall);
  }

  dispose() {
    _eventTransfer.close();
  }

  Stream<OmiAction> get eventTransferStream => _eventTransfer.stream;

  Stream<dynamic> cameraEvent() {
    return _cameraChannel.receiveBroadcastStream({"name": "camera"});
  }

  Stream micEvent() {
    return _micChannel.receiveBroadcastStream({"name": "mic"});
  }

  Future<dynamic> action(OmiAction action) async {
    final response = await _methodChannel.invokeMethod<dynamic>(
      'action',
      action.toJson(),
    );
    return response;
  }

  Future<dynamic> _omicallSDKMethodCall(MethodCall call) async {
    final args = call.arguments;
    switch (call.method) {
      case "CALL_END":
        _eventTransfer.sink.add(
          OmiAction(
            actionName: OmiEventList.onCallEnd,
            data: {},
          ),
        );
        debugPrint("SEND CALLEND Success");
        break;
      case "INCOMING_RECEIVED":
        final Map<String, dynamic> data = {
          "isVideo": args["isVideo"],
          "callerNumber": args["callerNumber"] as String?,
          "isIncoming": args["isIncoming"] as bool
        };
        _eventTransfer.sink.add(
          OmiAction(
            actionName: OmiEventList.incomingReceived,
            data: data,
          ),
        );
        debugPrint("SEND INCOMING_RECEIVED Success");
        break;
      case "CALL_ESTABLISHED":
        final Map<String, dynamic> data = {
          "isVideo": args["isVideo"],
          "callerNumber": args["callerNumber"] as String?,
        };
        _eventTransfer.sink.add(
          OmiAction(
            actionName: OmiEventList.onCallEstablished,
            data: data,
          ),
        );
        debugPrint("SEND CALL_ESTABLISHED Success");
        break;
      case "CONNECTION_TIMEOUT":
        // callback.call(
        //   ActionModel(
        //     actionName: OmiEventList.onConnectionTimeout,
        //     data: {},
        //   ),
        // );

        break;
      case "HOLD":
        final data = call.arguments;
        _eventTransfer.sink.add(
          OmiAction(
            actionName: OmiEventList.onHold,
            data: {
              "isHold": data["isHold"] as bool,
            },
          ),
        );

        break;
      case "MUTED":
        final data = call.arguments;
        _eventTransfer.sink.add(
          OmiAction(
            actionName: OmiEventList.onMuted,
            data: {
              "isMuted": data["isMuted"] as bool,
            },
          ),
        );
        break;
      case "RINGING":
        _eventTransfer.sink.add(
          OmiAction(
            actionName: OmiEventList.onRinging,
            data: {},
          ),
        );
        break;
      default:
        break;
    }
  }
}
