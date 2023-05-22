import 'dart:async';

import 'package:flutter/services.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import 'action/action_model.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class OmicallSDKController {
  /// The method channel used to interact with the native platform.

  final _methodChannel = const MethodChannel('omicallsdk');
  final _videoController = StreamController<Map<String, dynamic>>.broadcast();
  final _mutedController = StreamController<bool>.broadcast();
  final _speakerController = StreamController<bool>.broadcast();
  final _missedCallController = StreamController<Map>.broadcast();
  final _callQualityController = StreamController<Map>.broadcast();
  final StreamController<OmiAction> _callStateChangeController =
      StreamController<OmiAction>.broadcast();

  OmicallSDKController() {
    _methodChannel.setMethodCallHandler((call) async {
      final method = call.method;
      final data = call.arguments;
      if (method == OmiEventList.onMuted) {
        _mutedController.sink.add(data);
        return;
      }
      if (method == OmiEventList.onSpeaker) {
        _speakerController.sink.add(data);
        return;
      }
      if (method == OmiEventList.onLocalVideoReady || method == OmiEventList.onRemoteVideoReady) {
        final param = {
          "name": method,
          "data": data,
        };
        _videoController.sink.add(param);
        return;
      }
      if (method == OmiEventList.onMissedCall) {
        _missedCallController.sink.add(data);
        return;
      }
      if (method == OmiEventList.onCallQuality) {
        _callQualityController.sink.add(data);
        return;
      }
      _callStateChangeController.sink.add(
        OmiAction(
          actionName: call.method,
          data: data ?? <dynamic, dynamic>{},
        ),
      );
    });
  }

  dispose() {
    _videoController.close();
    _mutedController.close();
    _speakerController.close();
    _callStateChangeController.close();
    _callQualityController.close();
  }

  Stream<OmiAction> get callStateChangeEvent =>
      _callStateChangeController.stream;

  Stream<Map<String, dynamic>> get videoEvent => _videoController.stream;

  Stream<bool> get mutedEvent => _mutedController.stream;

  Stream<bool> get micEvent => _speakerController.stream;

  Stream<Map> get missedCallEvent => _missedCallController.stream;

  Stream<Map> get callQualityEvent => _callQualityController.stream;

  Future<dynamic> action(OmiAction action) async {
    final response = await _methodChannel.invokeMethod<dynamic>(
      'action',
      action.toJson(),
    );
    return response;
  }
}
