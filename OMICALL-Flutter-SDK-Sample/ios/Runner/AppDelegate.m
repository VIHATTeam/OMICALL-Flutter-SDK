// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#import "AppDelegate.h"
#import "GeneratedPluginRegistrant.h"
#import <OmiKit/OmiKit.h>
#import <FirebaseCore/FirebaseCore.h>
#import <omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [FIRApp configure];
  [GeneratedPluginRegistrant registerWithRegistry:self];
  [self registerOmicallWithEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX supportVideoCall:FALSE];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

- (void)application:(UIApplication*)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)devToken
{
    // parse token bytes to string
    const char *data = [devToken bytes];
    NSMutableString *token = [NSMutableString string];
    for (NSUInteger i = 0; i < [devToken length]; i++)
    {
        [token appendFormat:@"%02.2hhX", data[i]];
    }
    
    // print the token in the console.
    NSLog(@"Push Notification Token: %@", [token copy]);
    [OmiClient setUserPushNotificationToken:[token copy]];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    NSLog(@"didFailToRegisterForRemoteNotificationsWithError ---- Error");
}

@end
