import 'dart:async';

import 'package:omicall_flutter_plugin/model/action_model.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';
import 'package:omicall_flutter_plugin/omicallsdk_platform_interface.dart';

class OmiChannel {
  final OmicallSDK _instance = OmicallSDK();

  Future<dynamic> action({required ActionModel action}) {
    return _instance.action(action);
  }

  void listerEvent(Function(ActionModel) callback) {
    OmicallSDKPlatform.instance.listenerEvent(callback);
  }
}
