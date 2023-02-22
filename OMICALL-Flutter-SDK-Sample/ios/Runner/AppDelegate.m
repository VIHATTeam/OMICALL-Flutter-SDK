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
  [OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX];
  provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager ];
  voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
  pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end
