#import <Flutter/Flutter.h>
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <OmiKit/OmiKit-umbrella.h>
#import <OmiKit/Constants.h>
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate : FlutterAppDelegate<UIApplicationDelegate> {
    PushKitManager *pushkitManager;
    CallKitProviderDelegate * provider;
    PKPushRegistry * voipRegistry;
}

@end
