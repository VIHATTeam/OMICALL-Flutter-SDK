#import "OmicallsdkPlugin.h"
#if __has_include(<omicallsdk/omicallsdk-Swift.h>)
#import <omicallsdk/omicallsdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "omicallsdk-Swift.h"
#endif

@implementation OmicallsdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOmicallsdkPlugin registerWithRegistrar:registrar];
}
@end
