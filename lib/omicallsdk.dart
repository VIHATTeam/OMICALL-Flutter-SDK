import 'package:omicall_flutter_plugin/model/action_model.dart';

import 'omicallsdk_platform_interface.dart';

class OmiChannel {
  final OmicallSDKPlatform _instance = OmicallSDKPlatform.instance;

  Future<dynamic> action({required ActionModel action}) {
    return _instance.action(action);
  }

  void listerEvent(Function(ActionModel) callback) {
    OmicallSDKPlatform.instance.listenerEvent(callback);
  }
}
