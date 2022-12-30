import 'package:flutter/services.dart';
import 'package:omicall_flutter_plugin/constant/enums.dart';
import 'package:omicall_flutter_plugin/model/action_model.dart';

import 'omicallsdk_platform_interface.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class MethodChannelOmicallSDK extends OmicallSDKPlatform {
  /// The method channel used to interact with the native platform.

  static const methodChannel = MethodChannel('omicallsdk');

  @override
  Future<dynamic> action(ActionModel action) async {
    final response = await methodChannel.invokeMethod<dynamic>(
      'action',
      action.toJson(),
    );
    return response;
  }

  @override
  void listenerEvent(Function(ActionModel) callback) {
    methodChannel.setMethodCallHandler(
      (call) async {
        switch (call.method) {
          case "CALL_END":
            callback.call(
              ActionModel(
                actionName: OmiEventList.onCallEnd,
                data: {},
              ),
            );
            break;
          case "INCOMING_RECEIVED":
            final data = call.arguments as Map<String, dynamic>;
            callback.call(
              ActionModel(
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
              ActionModel(
                actionName: OmiEventList.onCallEstablished,
                data: {},
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
            final data = call.arguments as Map<String, dynamic>;
            callback.call(
              ActionModel(
                actionName: OmiEventList.onHold,
                data: {
                  "isHold": data["isHold"] as bool,
                },
              ),
            );

            break;
          case "MUTED":
            final data = call.arguments as Map<String, dynamic>;
            callback.call(
              ActionModel(
                actionName: OmiEventList.onMuted,
                data: {
                  "isMuted": data["isMuted"] as bool,
                },
              ),
            );
            break;
          case "RINGING":
            callback.call(
              ActionModel(
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
