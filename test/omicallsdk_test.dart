import 'package:flutter_test/flutter_test.dart';
import 'package:omicallsdk/model/action_model.dart';
import 'package:omicallsdk/omicallsdk.dart';
import 'package:omicallsdk/omicallsdk_platform_interface.dart';
import 'package:omicallsdk/omicallsdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockOmicallsdkPlatform
    with MockPlatformInterfaceMixin
    implements OmicallsdkPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future action(ActionModel action) {
    throw UnimplementedError();
  }
}

void main() {
  final OmicallsdkPlatform initialPlatform = OmicallsdkPlatform.instance;

  test('$MethodChannelOmicallsdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelOmicallsdk>());
  });

  test('getPlatformVersion', () async {
    Omicallsdk omicallsdkPlugin = Omicallsdk();
    MockOmicallsdkPlatform fakePlatform = MockOmicallsdkPlatform();
    OmicallsdkPlatform.instance = fakePlatform;

    expect(await omicallsdkPlugin.getPlatformVersion(), '42');
  });
}
