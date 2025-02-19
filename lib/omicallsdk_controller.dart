import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import 'action/action_model.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class OmicallSDKController {
  /// The method channel used to interact with the native platform.
  final _methodChannel = const MethodChannel('omicallsdk');

  Function(Map)? videoListener;
  Function(bool)? muteListener;
  Function(bool)? holdListener;
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
      debugPrint("method OmicallSDKController:: $method  --> data: $data");

      switch (method) {
        case OmiEventList.onMuted:
          muteListener?.call(data);
          return;
       case OmiEventList.onHold:
          bool result = false;
          try {
            result = data["isHold"] as bool;
          } catch (e) {
            if (data is bool) {
              result = data;
            } else {
              debugPrint("Error extracting 'isHold': $e, data is not a bool: $data");
            }
          }
          holdListener?.call(result);
          return;
        case OmiEventList.onSpeaker:
          speakerListener?.call(data);
          return;
        case OmiEventList.onRemoteVideoReady:
          final param = {"name": method, "data": data};
          videoListener?.call(param);
          return;
        case OmiEventList.onMissedCall:
          missedCallListener?.call(data);
          return;
        case OmiEventList.onCallQuality:
          callQualityListener?.call(data);
          return;
        case OmiEventList.onHistoryCallLog:
          callLogListener?.call(data);
          return;
        case OmiEventList.onAudioChanged:
          final rawData = data["data"];
          final correctData = rawData is List ? rawData : [rawData];
          audioChangedListener?.call(correctData);
          return;
        default:
          _callStateChangeController.sink.add(
            OmiAction(
              actionName: method,
              data: data ?? <dynamic, dynamic>{},
            ),
          );
      }
    });
  }

  void dispose() {
    _callStateChangeController.close();
  }

  Stream<OmiAction> get callStateChangeEvent =>
      _callStateChangeController.stream;

  Future<dynamic> action(OmiAction action) async {
    return await _methodChannel.invokeMethod('action', action.toJson());
  }
}