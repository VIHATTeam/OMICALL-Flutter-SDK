import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:omicallsdk/model/action_model.dart';

import 'omicallsdk_platform_interface.dart';

/// An implementation of [OmicallsdkPlatform] that uses method channels.
class MethodChannelOmicallsdk extends OmicallsdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('omicallsdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<dynamic> action(ActionModel action) async {
    final response = await methodChannel.invokeMethod<String>('action',jsonEncode(action.toJson()));
    return response;
  }

}
