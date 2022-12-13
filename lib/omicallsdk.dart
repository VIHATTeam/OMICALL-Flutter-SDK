

import 'package:omikit/model/action_model.dart';

import 'omicallsdk_platform_interface.dart';

class Omicallsdk {
  Future<dynamic> action(ActionModel action) {
    return OmicallsdkPlatform.instance.action(action);
  }
}

