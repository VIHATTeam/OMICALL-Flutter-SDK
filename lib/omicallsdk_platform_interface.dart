import 'package:omicall_flutter_plugin/model/action_model.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'omicallsdk_method_channel.dart';

abstract class OmicallSDKPlatform extends PlatformInterface {
  /// Constructs a OmicallsdkPlatform.
  OmicallSDKPlatform() : super(token: _token);

  static final Object _token = Object();

  static OmicallSDKPlatform _instance = MethodChannelOmicallSDK();

  /// The default instance of [OmicallSDKPlatform] to use.
  ///
  /// Defaults to [MethodChannelOmicallSDK].
  static OmicallSDKPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [OmicallsdkPlatform] when
  /// they register themselves.
  static set instance(OmicallSDKPlatform instance) {
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
