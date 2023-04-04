import 'dart:async';

import 'package:flutter/services.dart';

import 'action/action_model.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class OmicallSDKController {
  /// The method channel used to interact with the native platform.

  final _methodChannel = const MethodChannel('omicallsdk');
  final _cameraChannel = const EventChannel('omicallsdk/event/camera');
  final _onMuteChannel = const EventChannel('omicallsdk/event/on_mute');
  final _onMicChannel = const EventChannel('omicallsdk/event/on_mic');
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

  Stream<dynamic> onMuteEvent() {
    return _onMuteChannel.receiveBroadcastStream({"name": "on_mute"});
  }

  Stream<dynamic> onMicEvent() {
    return _onMicChannel.receiveBroadcastStream({"name": "on_mic"});
  }

  Future<dynamic> action(OmiAction action) async {
    final response = await _methodChannel.invokeMethod<dynamic>(
      'action',
      action.toJson(),
    );
    return response;
  }

  Future<dynamic> _omicallSDKMethodCall(MethodCall call) async {
    final Map? args = call.arguments;
    _eventTransfer.sink.add(
      OmiAction(
        actionName: call.method,
        data: args ?? <dynamic, dynamic>{},
      ),
    );
  }
}
