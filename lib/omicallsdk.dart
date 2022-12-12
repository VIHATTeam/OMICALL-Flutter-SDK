
import 'package:omicallsdk/model/action_model.dart';

import 'omicallsdk_platform_interface.dart';

class Omicallsdk {
  Future<String?> getPlatformVersion() {
    return OmicallsdkPlatform.instance.getPlatformVersion();
  }

  Future<dynamic> action(ActionModel action) {
    return OmicallsdkPlatform.instance.action(action);
  }

  Future<dynamic> initCall(ActionModel action) {
    return OmicallsdkPlatform.instance.action(action);
  }



}
