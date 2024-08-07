# OMICALL SDK FOR Flutter

The OmiKit exposes the <a href="https://pub.dev/packages/omicall_flutter_plugin">omicall_flutter_plugin</a> library.

The most important part of the framework is :
- Help to easy integrate with Omicall.
- Easy custom Call UI/UX.
- Optimize codec voip for you.
- Full interface to interactive with core function like sound/ringtone/codec.

### Status
Currently active maintenance and improve performance


### Running
Install via pubspec.yaml:

```
omicall_flutter_plugin: ^latest_version
```

### Configuration

#### Android:

- Add these settings in `build.gradle`:

```
jcenter() 
maven {
          url "https://maven.pkg.github.com/omicall/OMICall-SDK"
          credentials {
              username = OMI_USER
              password = OMI_TOKEN
          }
          authentication {
              basic(BasicAuthentication)
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
          url "https://maven.pkg.github.com/omicall/OMICall-SDK"
          credentials {
              username = OMI_USER
              password = OMI_TOKEN
          }
          authentication {
              basic(BasicAuthentication)
          }
        }
    }
}
```

You can refer <a href="https://github.com/VIHATTeam/OMICALL-Flutter-SDK/blob/main/OMICALL-Flutter-SDK-Sample/android/build.gradle">android/build.gradle</a> to know more information.

- Add these settings in `app/build.gradle`:

```
apply plugin: 'com.android.application'
apply plugin: 'kotlin-android'
apply plugin: 'com.google.gms.google-services'
```

You can refer <a href="https://github.com/VIHATTeam/OMICALL-Flutter-SDK/blob/main/OMICALL-Flutter-SDK-Sample/android/app/build.gradle">android/app/build.gradle</a> to know more information.

- Update AndroidManifest.xml:

```
//need request this permission
<manifest 
      ...... 
      xmlns:tools="http://schemas.android.com/tools">
      ..... // your config 
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
      ..... // your config 

         <application
                android:name=".MainApplication"
                ...... // your config 
                android:alwaysRetainTaskState="true"
                android:largeHeap="true"
                android:exported="true"
                android:supportsRtl="true"
                android:allowBackup="false"
                android:fullBackupContent="false"
                android:enableOnBackInvokedCallback="true"
                .....  // your config 
        >
                <activity
                            android:name=".MainActivity"
                        .....  // your config 
                            android:windowSoftInputMode="adjustResize"
                            android:showOnLockScreen="true"
                            android:launchMode="singleTask"
                            android:largeHeap="true"
                            android:alwaysRetainTaskState="true"
                            android:supportsPictureInPicture="false"
                            android:showWhenLocked="true"
                            android:turnScreenOn="true"
                            android:exported="true"
                        .....  // your config 
                            >
                        .....  // your config 
                          <intent-filter>
                              <action android:name="android.intent.action.MAIN" />
                              <category android:name="android.intent.category.LAUNCHER" />
                          </intent-filter>
                          
                          <intent-filter>
                                <action android:name="android.intent.action.CALL" />
                                <category android:name="android.intent.category.DEFAULT" />
                            <data
                                 android:host="incoming_call"
                                 android:scheme="omisdk" />
                          </intent-filter>
                        .....  // your config 
                     </activity>
                 .....  // your config 
                <receiver
                    android:name="vn.vihat.omicall.omisdk.receiver.FirebaseMessageReceiver"
                    android:exported="true"
                    android:enabled="true"
                    tools:replace="android:exported"
                    android:permission="com.google.android.c2dm.permission.SEND">
                    <intent-filter>
                        <action android:name="com.google.android.c2dm.intent.RECEIVE" />
                    </intent-filter>
                </receiver>
                <service
                  android:name="vn.vihat.omicall.omisdk.service.NotificationService"
                  android:enabled="true"
                  android:exported="false">
                </service>
                 .....  // your config 
           </application>
</manifest>
```
* In the `MainActivity` file we need you to add the following configurations
```
Class MainActivity : {
        ..... // your config 
        
        override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            OmicallsdkPlugin.onOmiIntent(this, intent)
        } catch (e: Throwable) {
            e.printStackTrace()
        }
    }
  
        override fun onResume(){
            super.onResume()
            OmicallsdkPlugin.onResume(this);
        }
        ..... // your config 

}
```

- Setup push notification: Only support Firebase for remote push notification.
  - Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - Add Fire Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/android-sdk/cau-hinh-push-notification">Config Push for Android</a>

#### iOS(Object-C):

- Assets: Add `call_image` into assets folder to update callkit image. We only support png style.

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
```
- Add these lines into `didFinishLaunchingWithOptions`:
```
[OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX userNameKey:@"extension" maxCall:1 callKitImage: @"callkit_image" typePushVoip:@"default" representName:@"OMICALL"];
provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager];
voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
if (@available(iOS 10.0, *)) {
    [UNUserNotificationCenter currentNotificationCenter].delegate = (id<UNUserNotificationCenterDelegate>) self;
}

Notes:
- To custom callkit image, you need add image into assets and paste image name into setEnviroment function.
- The variable representName is not required. If it has a value, when a call comes in, by default this name will be displayed on callKit. If nothing is transmitted, internal calls will display the Employee's name or the employee's internal 
```

```
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    bool value = [SwiftOmikitPlugin processUserActivityWithUserActivity:userActivity];
    return value;
}
```

```
- (void)applicationWillTerminate:(UIApplication *)application {
    @try {
        [OmiClient OMICloseCall];
    }
    @catch (NSException *exception) {

    }
}
```
-  Add these lines into `Info.plist`:

```
<key>NSCameraUsageDescription</key>
<string>Need camera access for video call functions</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need microphone access for make Call</string>
```

- Save token for `OmiClient`: if you added `firebase_messaging` in your project so you don't need add these lines.

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

*** Only use under lines when added `firebase_messaging` plugin in your project ***
- Setup push notification: We only support Firebase for push notification.
  - Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - Add Firebase Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Config Push for iOS</a>

#### iOS(Swift):

- Assets: Add `call_image` into assets folder to update callkit image. We only support png style.

- Add variables in Appdelegate.swift:

```
import OmiKit
import PushKit
import NotificationCenter

var pushkitManager: PushKitManager?
var provider: CallKitProviderDelegate?
var voipRegistry: PKPushRegistry?
```

- Add these lines into `didFinishLaunchingWithOptions`:

```
OmiClient.setEnviroment(KEY_OMI_APP_ENVIROMENT_SANDBOX, prefix: "", userNameKey: "extension", maxCall: 1, callKitImage: "callkit_image" typePushVoip:@"default")
provider = CallKitProviderDelegate.init(callManager: OMISIPLib.sharedInstance().callManager)
voipRegistry = PKPushRegistry.init(queue: .main)
pushkitManager = PushKitManager.init(voipRegistry: voipRegistry)

Notes:
- To custom callkit image, you need add image into assets and paste image name into setEnviroment function.
```

```
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    var value = SwiftOmikitPlugin.processUserActivity(userActivity: userActivity)
    return value
}
```

-  Add these lines into `Info.plist`:

```
<key>NSCameraUsageDescription</key>
<string>Need camera access for video call functions</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need microphone access for make Call</string>
```

- Save token for `OmiClient`: if you added `firebase_messaging` in your project so you don't need add these lines.

```
func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let deviceTokenString = deviceToken.hexString
    OmiClient.setUserPushNotificationToken(deviceTokenString)
}

extension Data {
    var hexString: String {
        let hexString = map { String(format: "%02.2hhx", $0) }.joined()
        return hexString
    }
}
```

*** Only use under lines when added `firebase_messaging` plugin in your project ***
- Setup push notification: We only support Firebase for push notification.
  - Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - Add Firebase Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Config Push for iOS</a>

*** Important release note ***
```
We support 2 environments. So you need set correct key in Appdelegate.
- KEY_OMI_APP_ENVIROMENT_SANDBOX support on debug mode
- KEY_OMI_APP_ENVIROMENT_PRODUCTION support on release mode
- Visit on web admin to select correct enviroment.   
```

## Implement

## Request permission

- We need you request permission about call before make call:

```
 + android.permission.CALL_PHONE (for android)
 + Permission.audio
 + Permission.microphone
 + Permission.camera  (if you want to make Video calls)

```


- Set up for Firebase:

```
await Firebase.initializeApp();
// If you only use Firebase on Android. Add these line `if (Platform.isAndroid)`
// Because we use APNS to push notification on iOS so you don't need add Firebase for iOS.
```
- Important function.
  - Start Serivce: OmiKit need start services and register some events.
    ```
    //Call in the root widget
    OmicallClient.instance.startServices();
    ```
  - Create OmiKit: OmiKit need userName, password, realm, host, fcmToken to init environment(all parameters we require are mandatory). ViHAT Group will provides these information for you.
    This function is used when you want to call any telecommunication number, calling back and forth between internal groups.
    Please contact for my sales:
    ```
    String? token = await FirebaseMessaging.instance.getToken();
    if (Platform.isIOS) {
        token = await FirebaseMessaging.instance.getAPNSToken();
    }
    await OmicallClient.instance.initCall(
      userName: "", 
      password: "",
      realm: "",
      host: "",
      isVideo: true/false,
      fcmToken: token // Note: with IOS, we need APNSToken, and android is FCM_Token
    );
    ```
  - Create OmiKit With ApiKey: OmiKit need apikey, username, fcmToken, user id to init environment (All parameters we require are mandatory). ViHAT Group will provides api key for you.
    This function is used when you want to make a call to the switchboard number (not to call the employee number).
    Please contact for my sales:
    ```
    String? token = await FirebaseMessaging.instance.getToken();
    if (Platform.isIOS) {
        token = await FirebaseMessaging.instance.getAPNSToken();
    }
     await OmicallClient.instance.initCallWithApiKey(
      usrName: "",
      usrUuid: "",
      isVideo: true/false,
      apiKey: "",
      fcmToken: token // Note: with IOS, we need APNSToken, and android is FCM_Token
    );
    ```
  - Get call when user open app from killed status(only iOS):
    ```
    final result = await OmicallClient.instance.getInitialCall();
    ///if result is not equal False => have a calling.
    ```
  - Config push notification: With iOS, I only support these keys: `prefixMissedCallMessage`, `missedCallTitle`, `userNameKey`. With Android, We don't support `missedCallTitle`:
    ```
    OmicallClient.instance.configPushNotification(
      notificationIcon : "calling_face", //notification icon on Android
      prefix : "Cuộc gọi tới từ: ",
      incomingBackgroundColor : "#FFFFFFFF",
      incomingAcceptButtonImage : "join_call", //image name
      incomingDeclineButtonImage : "hangup", //image name
      backImage : "ic_back", //image name: icon of back button
      userImage : "calling_face", //image name: icon of user default
      prefixMissedCallMessage: 'Cuộc gọi nhỡ từ' //config prefix message for the missed call
      missedCallTitle: 'Cuộc gọi nhỡ', //config title for the missed call
      userNameKey: 'uuid', //we have 3 values: uuid, full_name, extension
      channelId: 'channelid.callnotification' // need to use call notification,
      audioNotificationDescription: "" //audio description
      videoNotificationDescription: "" //video description
      representName: "" //  Optional value, if nothing is passed down or nil, will display the employee's name or extension number when a call comes in. If you declare a value, this value will be displayed on CallKit when there is an incoming call
    );
    //incomingAcceptButtonImage, incomingDeclineButtonImage, backImage, userImage: Add these into `android/app/src/main/res/drawble`
    ```
- Other functions:
  -  Call with phone number (mobile phone or internal number):
    ```
    final result = await OmicallClient.instance.startCall(
        phone, //phone number
        _isVideoCall, //call video or audio. If true is video call. 
    );
    ```
| Note                                                                                                                     |
|--------------------------------------------------------------------------------------------------------------------------|
| You need await for result == 8, this means startCallSuccess after you navigate or make another action.                   |
|                                                                                                                          |
| OmiStartCallStatus:                                                                                                      |
| - invalidUuid(0): uuid is invalid (we cannot find on my page)                                                            |
| - invalidPhoneNumber(1): sip user is invalid.                                                                            |
| - samePhoneNumber(2): Cannot call the same phone number.                                                                 |
| - maxRetry(3): We try to refresh the call but we cannot start your call.                                                 |
| - permissionDenied(4): Check audio permission.                                                                           |
| - couldNotFindEndpoint(5): Please login before making your call.                                                         |
| - accountRegisterFailed(6): We cannot register your account.                                                             |
| - startCallFailed(7): We cannot start your call.                                                                         |
| - startCallSuccess(8): Start call successfully.                                                                          |
| - haveAnotherCall(9): We cannot start your call because you are joining another call.                                    |

    
  -  Call with UUID (only support with Api key):
    
    ```
    final result = OmicallClient.instance.startCallWithUUID(
        uuid, //your user id
        _isVideoCall, //call video or audio. If true is video call. 
    );
    // Result is the same with startCall
    ```

  - Accept a call:
    ```
    OmicallClient.instance.joinCall();
    ```
  - End a call: We will push a event `endCall` and return call information for you.
    ```
    OmicallClient.instance.endCall().then((value) {
        //value is call information
    });
    Sample output:
    {
       "transaction_id":ea7dff38-cb1e-483d-8576...........,
       "direction":"inbound",
       "source_number":111,
       "destination_number":110,
       "time_start_to_answer":1682858097393,
       "time_end":1682858152181,
       "sip_user":111,
       "disposition":"answered"
    }
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
  - Get current user information:
    ```
    final user = await OmicallClient.instance.getCurrentUser();
    Output Sample:  
    {
        "extension": "111",
        "full_name": "chau1",
        "avatar_url": "",
        "uuid": "122aaa"
    }
    ```
  - Get guest user information:
    ```
    final user = await OmicallClient.instance.getGuestUser();
    Output Sample:  
    {
        "extension": "111",
        "full_name": "chau1",
        "avatar_url": "",
        "uuid": "122aaa"
    }
    ```
  - Get user information from sip:
    ```
    final user = await OmicallClient.instance.getUserInfo(phone: "111");
    Output Sample:  
    {
        "extension": "111",
        "full_name": "chau1",
        "avatar_url": "",
        "uuid": "122aaa"
    }
    ```
  - Logout:
    ```
    OmicallClient.instance.logout();
    ```
- Video Call functions: Support only video call, We need enable video in `init functions` and `start call` to implements under functions.
  - Switch front/back camera: We use the front camera for first time.
  ```
  OmicallClient.instance.switchCamera();
  ```
  - Toggle a video in video call: On/off video in video call
  ```
  - OmicallClient.instance.toggleVideo();
  ```
  - Register video event: Need to listen remote video ready
  ```
   OmicallClient.instance.toggleVideo();
  ```
  - Remove video event: Need to remove video event
  ```
  OmicallClient.instance.removeVideoEvent();
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
  - Important event `callStateChangeEvent`: We provide it to listen call state change.
 ```
 OmicallClient.instance.controller.callStateChangeEvent
 //OmiAction have 2 variables: actionName and data
 ```
    - Action Name value: 
        - `onCallStateChanged`: Call state changed.
        - `onSwitchboardAnswer`: Switchboard sip is listening. 
        - List status call: 
          + unknown(0),
          + calling(1),
          + incoming(2),
          + early(3),
          + connecting(4),
          + confirmed(5),
          + disconnected(6);
    + onCallStateChanged is call state tracking event. We will return status of state. Please refer `OmiCallState`.
          `onCallStateChanged value:`
              + isVideo: value boolean (true is call Video)
              + status: number (value matching with List status call )
              + callerNumber: phone number 
              + incoming: boolean - status call incoming or outgoing
              + _id: option (id of every call)
    + Incoming call state lifecycle: incoming -> connecting -> confirmed -> disconnected
    + Outgoing call state lifecycle: calling -> early -> connecting -> confirmed -> disconnected
    + onSwitchboardAnswer have callback when employee answered script call.
- Other events:
  - Call Quality event: Listen call quality event changed
  ```
  OmicallClient.instance.setCallQualityListener((data) {
      final quality = data["quality"] as int;
      final req = data["stat"]["req"] as double; // time taken mos call,
      final mos = data["stat"]["mos"] as double; // mos call 
      final jitter = data["stat"]["jitter"] as double; // jitter call
      final latency = data["stat"]["latency"] as double; // latency call
      final ppl = data["stat"]["ppl"] as double; // ppl call
      final lcn = data["stat"]["lcn"] as int; // loss connect 
      final lcn = data["isNeedLoading"] as boolean ; // when value is TRUE, you need show loading in your App, because this call have problem with networking
  });
  //we return `quality` key with: 0 is GOOD, 1 is NORMAL, 2 is BAD
  ```
  - Mic event: Listen on/off mic in a call
  ```
  OmicallClient.instance.setSpeakerListener((data) {
      setState(() {
        isSpeaker = data;
      });
  });
  //data is current speaker status.
  ```
  - Mute event: Listen on/off muted in a call
  ```
  OmicallClient.instance.setMuteListener((data) {
      setState(() {
        isMuted = data;
      });
  });
  //data is current muted status.
  ```
  - Remote video ready: Listen remote video ready.
  ```
  OmicallClient.instance.setVideoListener((data) {
      refreshRemoteCamera(); => need refresh camera
      refreshLocalCamera(); => need refresh camera
  });
  ```
  - User tab a missed call notification:
  ```
  OmicallClient.instance.setMissedCallListener((data) {
      final String callerNumber = data["callerNumber"];
      final bool isVideo = data["isVideo"];
      makeCallWithParams(context, callerNumber, isVideo);
  });
  // data is Map. Data has 2 keys: callerNumber, isVideo
  ```
  - User tab a call log (only `iOS`):
  ```
  OmicallClient.instance.setCallLogListener((data) {
      final callerNumber = data["callerNumber"];
      final isVideo = data["isVideo"];
      makeCallWithParams(
        context,
        callerNumber,
        isVideo,
      );
  });
  // data is Map. Data has 2 keys: callerNumber, isVideo
  ```
- Table describing code_end_call status


| Code  | Description |
|-------|-------------|
| `600, 503, 480` | These are the codes of the network operator or the user who did not answer the call |
| `408` | Call request timeout (Each call usually has a waiting time of 30 seconds. If the 30 seconds expire, it will time out) |
| `403` | Your service plan only allows calls to dialed numbers. Please upgrade your service pack |
| `404` | The current number is not allowed to make calls to the carrier |
| `603` | The call was rejected. Please check your account limit or call barring configuration! |
| `850` | Simultaneous call limit exceeded, please try again later |
| `486` | The listener refuses the call and does not answer |
| `601` | Call ended by the customer |
| `602` | Call ended by the other employee |


- Action Name value:
  - `OmiCallEvent.onMuted`: Audio changed.
  - `OmiCallEvent.onSpeaker`: Audio changed.
  - `OmiCallEvent.onClickMissedCall`: Click missed call notification.
  - `OmiCallEvent.onSwitchboardAnswer`: Switchboard sip is listening.
  - `OmiCallEvent.onCallQuality`: The calling quality.
- Data value: We return `callerNumber`, `sip`, `isVideo: true/false` information


- Forward calls to internal staff:
  + You can use function `transferCall` for transfer to staff you want.
    example: 
      transferCall({
        phoneNumber: 102
      })
