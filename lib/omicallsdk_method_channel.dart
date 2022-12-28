import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:omicall_flutter_plugin/constant/enums.dart';
import 'package:omicall_flutter_plugin/model/action_model.dart';

import 'omicallsdk_platform_interface.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class MethodChannelOmicallsdk extends OmicallsdkPlatform {
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
    methodChannel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onCallEnd":
          callback
              .call(ActionModel(actionName: ListenEvent.onCallEnd, data: {}));
          break;
        case "incomingReceived":
          final data = call.arguments as Map<String, dynamic>;
          callback.call(ActionModel(
              actionName: ListenEvent.incomingReceived,
              data: {
                "callerId": data["callerId"] as int,
                "phoneNumber": data["callerId"] as String
              }));
          break;
        case "onCallEstablished":
          callback.call(
              ActionModel(actionName: ListenEvent.onCallEstablished, data: {}));

          break;
        case "onConnectionTimeout":
          callback.call(ActionModel(
              actionName: ListenEvent.onConnectionTimeout, data: {}));

          break;
        case "onHold":
          final data = call.arguments as Map<String, dynamic>;
          callback.call(ActionModel(
              actionName: ListenEvent.onHold,
              data: {"isHold": data["isHold"] as bool}));

          break;
        case "onMuted":
          final data = call.arguments as Map<String, dynamic>;
          callback.call(ActionModel(
              actionName: ListenEvent.onMuted,
              data: {"isMuted": data["isMuted"] as bool}));
          break;
        case "onRinging":
          callback
              .call(ActionModel(actionName: ListenEvent.onRinging, data: {}));

          break;
      }
    });
  }
}
