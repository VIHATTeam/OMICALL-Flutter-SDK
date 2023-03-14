import 'dart:async';

import 'package:flutter/services.dart';

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
    _eventTransfer.sink.add(
      OmiAction(
        actionName: call.method,
        data: call.arguments,
      ),
    );
  }
}
