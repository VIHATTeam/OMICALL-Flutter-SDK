import 'package:flutter/services.dart';
import 'package:omicall_flutter_plugin/constant/enums.dart';

import 'action/action_model.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class OmicallSDKController  {
  /// The method channel used to interact with the native platform.

  final _methodChannel = const MethodChannel('omicallsdk');
  final _cameraChannel = const EventChannel('event/camera');
  final _micChannel = const EventChannel('event/mic');

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

  void listenerEvent(Function(OmiAction) callback) {
    _methodChannel.setMethodCallHandler(
      (call) async {
        switch (call.method) {
          case "CALL_END":
            callback.call(
              OmiAction(
                actionName: OmiEventList.onCallEnd,
                data: {},
              ),
            );
            break;
          case "INCOMING_RECEIVED":
            final data = call.arguments;
            callback.call(
              OmiAction(
                actionName: OmiEventList.incomingReceived,
                data: {
                  "callerId": data["callerId"] as int,
                  "phoneNumber": data["phoneNumber"] as String
                },
              ),
            );
            break;
          case "CALL_ESTABLISHED":
            callback.call(
              OmiAction(
                actionName: OmiEventList.onCallEstablished,
                data: {
                  "isVideo": call.arguments ?? true,
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
            callback.call(
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
            callback.call(
              OmiAction(
                actionName: OmiEventList.onMuted,
                data: {
                  "isMuted": data["isMuted"] as bool,
                },
              ),
            );
            break;
          case "RINGING":
            callback.call(
              OmiAction(
                actionName: OmiEventList.onRinging,
                data: {},
              ),
            );
            break;
          default:
            break;
        }
      },
    );
  }
}
