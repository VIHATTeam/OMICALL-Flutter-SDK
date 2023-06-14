import 'dart:async';

import 'package:flutter/services.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import 'action/action_model.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class OmicallSDKController {
  /// The method channel used to interact with the native platform.

  final _methodChannel = const MethodChannel('omicallsdk');
  Function(Map)? videoListener;
  Function(bool)? muteListener;
  Function(bool)? speakerListener;
  Function(Map)? missedCallListener;
  Function(Map)? callQualityListener;
  Function(Map)? callLogListener;
  Function(List<dynamic>)? audioChangedListener;
  final StreamController<OmiAction> _callStateChangeController =
      StreamController<OmiAction>.broadcast();

  OmicallSDKController() {
    _methodChannel.setMethodCallHandler((call) async {
      final method = call.method;
      final data = call.arguments;
      if (method == OmiEventList.onMuted) {
        if (muteListener != null) {
          muteListener!(data);
        }
        return;
      }
      if (method == OmiEventList.onSpeaker) {
        if (speakerListener != null) {
          speakerListener!(data);
        }
        return;
      }
      if (method == OmiEventList.onRemoteVideoReady) {
        final param = {
          "name": method,
          "data": data,
        };
        if (videoListener != null) {
          videoListener!(param);
        }
        return;
      }
      if (method == OmiEventList.onMissedCall) {
        if (missedCallListener != null) {
          missedCallListener!(data);
        }
        return;
      }
      if (method == OmiEventList.onCallQuality) {
        if (callQualityListener != null) {
          callQualityListener!.call(data);
        }
        return;
      }
      if (method == OmiEventList.onHistoryCallLog) {
        if (callLogListener != null) {
          callLogListener!.call(data);
        }
        return;
      }
      if (method == OmiEventList.onAudioChanged) {
        if (audioChangedListener != null) {
          audioChangedListener!.call(data["data"]);
        }
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
    _callStateChangeController.close();
  }

  Stream<OmiAction> get callStateChangeEvent =>
      _callStateChangeController.stream;

  Future<dynamic> action(OmiAction action) async {
    final response = await _methodChannel.invokeMethod<dynamic>(
      'action',
      action.toJson(),
    );
    return response;
  }
}
