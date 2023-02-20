import 'dart:async';

import 'package:event_bus/event_bus.dart';
import 'package:omicall_flutter_plugin/model/action_model.dart';

import 'event/events.dart';
import 'omicallsdk_platform_interface.dart';

class OmiChannel {
  final OmicallSDKPlatform _instance = OmicallSDKPlatform.instance;
  final _eventBus = EventBus();

  Future<dynamic> action({required ActionModel action}) {
    return _instance.action(action);
  }

  void registerEventListener() {
    OmicallSDKPlatform.instance.listenerEvent((action) {
      _eventBus.fire(OmiEvent(data: action));
    });
  }

  Stream<OmiEvent> subscriptionEvent() {
    return _eventBus.on<OmiEvent>();
  }

  Stream<dynamic> cameraEvent() {
    return OmicallSDKPlatform.instance.cameraEvent();
  }

  Stream<dynamic> micEvent() {
    return OmicallSDKPlatform.instance.micEvent();
  }
}
