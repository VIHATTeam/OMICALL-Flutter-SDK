// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <OmiKit/OmiKit.h>
#import <omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>
#import <FirebaseCore/FirebaseCore.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [FIRApp configure];
  [GeneratedPluginRegistrant registerWithRegistry:self];
//    #if DEBUG
//        [OmiClient setEnviroment:@"2" userNameKey:@"full_name" maxCall:1 callKitImage:@"call_image" typePushVoip:@"default" representName: @"CTY H-SOLUTIONS"];
//    #else
//        [OmiClient setEnviroment:@"3" userNameKey:@"full_name" maxCall:1 callKitImage:@"call_image" typePushVoip:@"default" representName: @"CTY H-SOLUTIONS"];
//    #endif
    [OmiClient setEnviroment:@"3" userNameKey:@"full_name" maxCall:1 callKitImage:@"call_image" typePushVoip:@"default" representName: @"CTY H-Finance"];
    [OmiClient setLogLevel:4];

  provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager];
  voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
  pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];

  if (@available(iOS 10.0, *)) {
      [UNUserNotificationCenter currentNotificationCenter].delegate = (id<UNUserNotificationCenterDelegate>) self;
  }
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    bool value = [SwiftOmikitPlugin processUserActivityWithUserActivity:userActivity];
    return value;
}

@end
