import 'package:omicall_flutter_plugin/model/action_model.dart';

import 'omicallsdk_platform_interface.dart';

class OmicallSDK {
  Future<dynamic> action(ActionModel action) {
    return OmicallSDKPlatform.instance.action(action);
  }
}

