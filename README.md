# OMICALL SDK FOR Flutter

The OmiKit exposes the <a href="https://pub.dev/packages/omicall_flutter_plugin">omicall_flutter_plugin</a> library.

The most important part of the framework is :
- Help to easy integrate with Omicall.
- Easy custom Call UI/UX.
- Optimize codec voip for you.
- Full inteface to interactive with core function like sound/ringtone/codec.

## Status
Currently active maintained


## Running
Install via pubspec.yaml:

```
omicall_flutter_plugin: ^1.0.9
```

### Configuration

#### Android:

- Add this setting in `build.gradle`:

```
jcenter() // Warning: this repository is going to shut down soon
maven {
    url("https://vihat.jfrog.io/artifactory/vihat-local-repo")
    credentials {
        username = "anonymous"
    }
}
```

```
classpath 'com.google.gms:google-services:4.3.13' //in dependencies
```

- Add this setting In `app/build.gradle`:

```
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'
```

- Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://firebase.flutter.dev/docs/manual-installation/android">Firebase core</a>)

- For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/android-sdk/cau-hinh-sdk">Omicall for Android</a>


#### iOS:
- Set up enviroment:

```
[OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX];
We have 2 environment variables:
- KEY_OMI_APP_ENVIROMENT_SANDBOX //Support for testing
- KEY_OMI_APP_ENVIROMENT_PRODUCTION //Supprt for production
```
- Set up VOIP PUSH:

```
provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager ];
voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
```
- Set up push notification:

```
- (void)requestPushNotificationPermissions
{
    // iOS 10+
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        switch (settings.authorizationStatus)
        {
            // User hasn't accepted or rejected permissions yet. This block shows the allow/deny dialog
            case UNAuthorizationStatusNotDetermined:
            {
                center.delegate = self;
                [center requestAuthorizationWithOptions:(UNAuthorizationOptionSound | UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error)
                 {
                     if(granted)
                     {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [[UIApplication sharedApplication] registerForRemoteNotifications];
                         });
                     }
                     else
                     {
                         // notify user to enable push notification permission in settings
                     }
                 }];
                break;
            }
            case UNAuthorizationStatusAuthorized:
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[UIApplication sharedApplication] registerForRemoteNotifications];
                });
                break;
            }
            default:
                break;
        }
    }];
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
    [OmiClient setUserPushNotificationToken:[token copy]];
}
```

- Init libary:

```
[OmiClient startOmiService: supportForVideo];
//supportForVideo is TRUE, if you need to support video call or else.
```

- For more information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/khoi-tao-sdk">Omicall for iOS</a>

## Implement
- Set up for Firebase:

```
await Firebase.initializeApp();
//if you use only on Android. Add this line `if (Platform.isAndroid)`
//because we use APNS to push notification on iOS so you don't need add Firebase for iOS.
```
- Init OmiChannel:

```
final omiChannel = OmiChannel();
//You need init OmiChannel with a global variable
```

- Call actions: We definded `OmiAction` to call functions. For more information, you can search `omicall.dart`, all actions are in there.

```
final action = OmiAction.initCall(
  userName.text,
  password.text,
  'thaonguyennguyen1197',
);
omiChannel.action(action: action);
```
