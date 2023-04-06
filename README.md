# OMICALL SDK FOR Flutter

The OmiKit exposes the <a href="https://pub.dev/packages/omicall_flutter_plugin">omicall_flutter_plugin</a> library.

The most important part of the framework is :
- Help to easy integrate with Omicall.
- Easy custom Call UI/UX.
- Optimize codec voip for you.
- Full inteface to interactive with core function like sound/ringtone/codec.

## Status
Currently active maintainance and improve performance


## Running
Install via pubspec.yaml:

```
omicall_flutter_plugin: ^latest_version
```

### Configuration

#### Android:

- Add this setting in `build.gradle`:

```
jcenter() 
maven {
    url("https://vihatgroup.jfrog.io/artifactory/omi-voice/")
    credentials {
        username = "downloader"
        password = "Omi@2022"
    }
}
```

```
//in dependencies
classpath 'com.google.gms:google-services:4.3.13'
```

```
//under buildscript
allprojects {
    repositories {
        google()
        mavenCentral()
        jcenter() // Warning: this repository is going to shut down soon
        maven {
            url("https://vihatgroup.jfrog.io/artifactory/omi-voice/")
            credentials {
                username = "downloader"
                password = "Omi@2022"
            }
        }
    }
}
```

You can refer <a href="https://github.com/VIHATTeam/OMICALL-Flutter-SDK/blob/main/OMICALL-Flutter-SDK-Sample/android/build.gradle">android/build.gradle</a> to know more informations.

- Add this setting In `app/build.gradle`:

```
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'
```

You can refer <a href="https://github.com/VIHATTeam/OMICALL-Flutter-SDK/blob/main/OMICALL-Flutter-SDK-Sample/android/app/build.gradle">android/app/build.gradle</a> to know more informations.

- Update AndroidManifest.xml:

```
//need request this permission
<uses-permission android:name="android.permission.INTERNET" />
//add this lines inside <activity>
<intent-filter>
    <action android:name="com.omicall.sdk.CallingActivity"/>
    <category android:name="android.intent.category.DEFAULT" />
</intent-filter>
//add this lines outside <activity>
<service
    android:name="vn.vihat.omicall.omisdk.service.FMService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
<service
    android:name="vn.vihat.omicall.omisdk.service.NotificationService"
    android:exported="false">
</service>
```
You can refer <a href="https://github.com/VIHATTeam/OMICALL-Flutter-SDK/blob/main/OMICALL-Flutter-SDK-Sample/android/app/src/main/AndroidManifest.xml">AndroidManifest</a> to know more informations.


- We registered permissions into my plugin:
```
<uses-permission android:name="android.permission.BROADCAST_CLOSE_SYSTEM_DIALOGS"
    tools:ignore="ProtectedPermissions" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.USE_SIP" />
<uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```

- Setup push notification: We only support Firebase for push notification.
  - Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - Add Fire Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/android-sdk/cau-hinh-push-notification">Config Push for Android</a>

#### iOS:
----

We support both Object-C and Swift. But we only support documents for Object-C. We will write for Swift language later. Thank you.

---

- Add variables in Appdelegate.h:

```
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <OmiKit/OmiKit-umbrella.h>
#import <OmiKit/Constants.h>
#import <UserNotifications/UserNotifications.h>

PushKitManager *pushkitManager;
CallKitProviderDelegate * provider;
PKPushRegistry * voipRegistry;
```

- Edit AppDelegate.m:

```
#import <OmiKit/OmiKit.h>
#import <omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>

[OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX];
provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager];
voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
```

-  Add this lines into `Info.plist`:

```
<key>NSCameraUsageDescription</key>
<string>Need camera access for video call functions</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need microphone access for make Call</string>
```

- Save token for `OmiClient`: You use `firebase_messaging` into your project so you don't need add this lines.

```
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

```

*** Only use under lines when add `firebase_messaging` plugin ***
- Setup push notification: We only support Firebase for push notification.
  - Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - Add Firebase Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Config Push for iOS</a>


## Implement
- Set up for Firebase:

```
await Firebase.initializeApp();
// If you only use Firebase on Android. Add this line `if (Platform.isAndroid)`
// Because we use APNS to push notification on iOS so you don't need add Firebase for iOS.
```
- Important function.
  - Start Serivce: OmiKit need start services and register some events.
    ```
    //Call in the root widget
    OmicallClient.instance.startServices();
    ```
  - Create OmiKit: OmiKit need userName, password, realm, host to init enviroment. ViHAT Group will provide informations for you. Please contact for my sale:
    ```
    await OmicallClient.instance.initCall(
      userName: "", 
      password: "",
      realm: "",
      host: "",
      isVideo: true/false,
    );
    ```
  - Create OmiKit With ApiKey: OmiKit need apikey, username, user id to init enviroment. ViHAT Group will provide api key for you. Please contact for my sale:
    ```
     await OmicallClient.instance.initCallWithApiKey(
      usrName: "",
      usrUuid: "",
      isVideo: true/false,
      apiKey: "",
    );
    ```
    - Config push notification for Android:
    ```
    OmicallClient.instance.configPushNotification(
      prefix : "Cuộc gọi tới từ: ",
      declineTitle : "Từ chối",
      acceptTitle : "Chấp nhận",
      acceptBackgroundColor : "#FF3700B3",
      declineBackgroundColor : "#FF000000",
      incomingBackgroundColor : "#FFFFFFFF",
      incomingAcceptButtonImage : "join_call", //image name
      incomingDeclineButtonImage : "hangup", //image name
      backImage : "ic_back", //image name: icon of back button
      userImage : "calling_face", //image name: icon of user default
    );
    //incomingAcceptButtonImage, incomingDeclineButtonImage, backImage, userImage: Add these into `android/app/src/main/res/drawble`
    ```
- Upload token: OmiKit need FCM for Android and APNS to push notification on user devices. We use more packages: <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> and <a href="https://pub.dev/packages/device_info_plus">device_info_plus</a>
  ```
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );
  final token = await FirebaseMessaging.instance.getToken();
  String? apnToken;
  if (Platform.isIOS) {
      apnToken = await FirebaseMessaging.instance.getAPNSToken();
  }
  String id = "";
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
      id = (await deviceInfo.androidInfo).id;
  } else {
      id = (await deviceInfo.iosInfo).identifierForVendor ?? "";
  }
  String appId = 'Bundle id on iOS/ App id on Android'
  await OmicallClient.instance.updateToken(
    id,
    appId,
    fcmToken: token,
    apnsToken: apnToken,
  );
  ```


- Other functions:
  -  Call with phone number (mobile phone or internal number):
    ```
    OmicallClient.instance.startCall(
        phone, //phone number
        _isVideoCall, //call video or audio. If true is video call. 
    );
    ```
  - Accept a call:
    ```
    OmicallClient.instance.joinCall();
    ```
  - End a call: We will push a event `endCall` for you.
    ```
    OmicallClient.instance.endCall();
    ```
  - Toggle the audio: On/off audio a call
    ```
    OmicallClient.instance.toggleAudio();
    ```
  - Toggle the speaker: On/off the phone speaker
    ```
    OmicallClient.instance.toggleSpeaker();
    ```
  - Send character: We only support `1 to 9` and `* #`.
    ```
    OmicallClient.instance.sendDTMF(value);
    ```
- Video Call functions: Support only video call, We need enable video in `init functions` and `start call` to implements under functions.
  - Switch front/back camera: We use the front camera for first time.
  ```
  OmicallClient.instance.switchCamera();
  ```
  - Toggle a video in video call: On/off video in video call
  ```
  OmicallClient.instance.toggleVideo();
  ```
  - Local Camera Widget: Your camera view in a call
  ```
  LocalCameraView(
    width: double.infinity,
    height: double.infinity,
    onCameraCreated: (controller) {
      _localController = controller;
      //we will return the controller to call some functions.
    },
  )
  ```
  - Remote Camera Widget: Remote camera view in a call
  ```
  RemoteCameraView(
     width: double.infinity,
     height: double.infinity,
     onCameraCreated: (controller) {
       _remoteController = controller;
     },
  )
  ```
  - More function: Refresh camera
  ```
  //camera controller receive when you create camera widget.
  RemoteCameraController? _remoteController;
  LocalCameraController? _localController;
  //refresh remote camera
  void refreshRemoteCamera() {
    _remoteController?.refresh();
  }
  //refresh remote camera
  void localRemoteCamera() {
    _localController?.refresh();
  }
  ```

- Event listener:
  - Important event `eventTransferStream`: We provide it to listen call state change.
 ```
 OmicallClient.instance.controller.eventTransferStream..listen((omiAction) {
 }
 //OmiAction have 2 variables: actionName and data
 ```
    - Action Name value: 
        - `incomingReceived`: Have a incoming call. On Android this event work only foreground
        - `onCallEstablished`: Connected a call.
        - `onCallEnd`: End a call.
        - `onHold`: `Comming soon....`
        - `onMuted`: `Comming soon...`
    - Data value: We return `callerNumber`, `isVideo: true/false` information
- Other events:
  - Mic event: Listen on/off mic in a call
  ```
  OmicallClient.instance.onMicEvent() //StreamSubscription
  ```
  - Mute event: Listen on/off muted in a call
  ```
  OmicallClient.instance.onMuteEvent() //StreamSubscription
  ```
