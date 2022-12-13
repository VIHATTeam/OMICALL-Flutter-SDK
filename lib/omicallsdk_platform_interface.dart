import 'package:omikit/model/action_model.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'omicallsdk_method_channel.dart';

abstract class OmicallsdkPlatform extends PlatformInterface {
  /// Constructs a OmicallsdkPlatform.
  OmicallsdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static OmicallsdkPlatform _instance = MethodChannelOmicallsdk();

  /// The default instance of [OmicallsdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelOmicallsdk].
  static OmicallsdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OmicallsdkPlatform] when
  /// they register themselves.
  static set instance(OmicallsdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;

  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }


  Future<dynamic> action(ActionModel action) {
    throw UnimplementedError('action has not been implemented.');
  }

  void listenerEvent(Function(ActionModel) callback) {
    throw UnimplementedError('action has not been implemented.');

  }

}
