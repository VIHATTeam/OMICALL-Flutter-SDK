import 'dart:async';

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
      StreamController.broadcast();
  late final _eventSink = _eventTransfer.sink;

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
        _eventSink.add(
          OmiAction(
            actionName: OmiEventList.onCallEnd,
            data: {},
          ),
        );
        break;
      case "INCOMING_RECEIVED":
        _eventSink.add(
          OmiAction(
            actionName: OmiEventList.incomingReceived,
            data: {
              "isVideo": args["isVideo"] == 0 ? false : true,
              "callerNumber": args["callerNumber"] as String,
              "isIncoming": args["isIncoming"] as bool
            },
          ),
        );
        break;
      case "CALL_ESTABLISHED":
        _eventSink.add(
          OmiAction(
            actionName: OmiEventList.onCallEstablished,
            data: {
              "isVideo": args["isVideo"] == 0 ? false : true,
              "callerNumber": args["callerNumber"] as String,
              "isIncoming": args["isIncoming"] as bool
            },
          ),
        );

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
        _eventSink.add(
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
        _eventSink.add(
          OmiAction(
            actionName: OmiEventList.onMuted,
            data: {
              "isMuted": data["isMuted"] as bool,
            },
          ),
        );
        break;
      case "RINGING":
        _eventSink.add(
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
