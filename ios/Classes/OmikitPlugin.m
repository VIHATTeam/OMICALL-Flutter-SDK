#import "OmikitPlugin.h"
#if __has_include(<omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>)
#import <omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "omicall_flutter_plugin-Swift.h"
#endif

@implementation OmikitPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftOmikitPlugin registerWithRegistrar:registrar];
}
@end
