# 📦 OMICALL SDK FOR Flutter

The OmiKit exposes the 📦 <a href="https://pub.dev/packages/omicall_flutter_plugin">omicall_flutter_plugin</a> library.

The most important part of the framework is :
- ✅ Help to easy integrate with Omicall.
- ✅ Easy custom Call UI/UX.
- ✅ Optimize codec voip for you.
- ✅ Full interface to interactive with core function like sound/ringtone/codec.

### 📝 Status
Currently active maintenance and improve performance


### Running
Install via pubspec.yaml:

```
omicall_flutter_plugin: ^latest_version
```

## Configuration

### 🛠️ STEP 1: Config native file 

#### 🚀 Android:

##### 📌 - Config *gradle* file 

- Add these settings in `build.gradle`:

```gradle 
jcenter() 
maven {
  url "https://maven.pkg.github.com/omicall/OMICall-SDK"
  credentials {
    username = OMI_USER // Please connect with developer OMI for get information 
    password = OMI_TOKEN
  }
  authentication {
    basic(BasicAuthentication)
  }
}
```

```gradle
//in dependencies
classpath 'com.google.gms:google-services:4.3.13' // You can choose the version of google-services to suit your project
```

```gradle
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

If you use the latest Flutter using the build.gradle.kts file, the configuration is as follows:


```kotlin
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/omicall/OMICall-SDK")
            credentials {
                username = project.findProperty("OMI_USER") as? String ?: ""
                password = project.findProperty("OMI_TOKEN") as? String ?: ""
            }
            authentication {
                create<BasicAuthentication>("basic")
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


##### 📌 - Config *AndroidManifest.xml* file 


```xml
//need request this permission
<manifest 
      // ...... 
      xmlns:tools="http://schemas.android.com/tools">
      //  your config  ..... 
    <uses-feature android:name="android.hardware.telephony" android:required="false" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
       // .... your config 

         <application
                android:name=".MainApplication"
           // .... your config 
                android:alwaysRetainTaskState="true"
                android:largeHeap="true"
                android:exported="true"
                android:supportsRtl="true"
                android:allowBackup="false"
                android:fullBackupContent="false"
                android:enableOnBackInvokedCallback="true"
        >
                <activity
                            android:name=".MainActivity"
                 // .... your config 
                            android:windowSoftInputMode="adjustResize"
                            android:showOnLockScreen="true"
                            android:launchMode="singleTask"
                            android:largeHeap="true"
                            android:alwaysRetainTaskState="true"
                            android:supportsPictureInPicture="false"
                            android:showWhenLocked="true"
                            android:turnScreenOn="true"
                            android:exported="true"
                            >
                        // .... your config 
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
                         // .... your config 
                     </activity>
                 // .... your config 
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
               // .... your config 
           </application>
</manifest>
```

##### 📌 -  Config *MainActivity* file 

* In the `MainActivity.kt` file we need you to add the following configurations
```kotlin
import androidx.core.app.ActivityCompat.requestPermissions
import android.app.Activity
import io.flutter.embedding.android.FlutterActivity
import vn.vihat.omicall.omicallsdk.OmicallsdkPlugin
import android.Manifest
import androidx.activity.result.contract.ActivityResultContracts
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.os.Bundle
import android.content.Intent
import android.util.Log
import vn.vihat.omicall.omisdk.utils.SipServiceConstants

class MainActivity: FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        try {
            val callPermissions = arrayOf(Manifest.permission.RECORD_AUDIO)

            if(!isGrantedPermission(Manifest.permission.RECORD_AUDIO)){
                requestPermissions(this,callPermissions,0)
            }

            val isIncomingCall = intent.getBooleanExtra(SipServiceConstants.ACTION_IS_INCOMING_CALL, false)
            OmicallsdkPlugin.onOmiIntent(this, intent)

        } catch (e: Throwable) {
            e.printStackTrace()
        }
    }

    override fun onNewIntent(intent: Intent){
        super.onNewIntent(intent);
        OmicallsdkPlugin.onOmiIntent(this, intent)
    }


    override fun onDestroy() {
        super.onDestroy()
        OmicallsdkPlugin.onDestroy()
    }

    override fun onResume(){
        super.onResume()
        OmicallsdkPlugin.onResume(this);
    }

    fun isGrantedPermission(permission: String): Boolean {
        return ContextCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        OmicallsdkPlugin.onRequestPermissionsResult(requestCode, permissions, grantResults, this)
    }

  // Your config 
}

```

- ✨ Setup push notification : Only support Firebase for remote push notification.
  - ✅ Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - ✅ Add Fire Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - ✅ For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/android-sdk/cau-hinh-push-notification">Config Push for Android</a>


<br>*Now let's continue configuring iOS, let's go 🚀*<br>

#### 🚀 iOS(Object-C):


- 📝 Assets: Add `call_image` into assets folder to update callkit image. We only support png style (*This will help show your application icon on iOS CallKit when a call comes in*)

<br></br>

- 📌 Add variables in *Appdelegate.h*:

```objc
#import <UIKit/UIKit.h>
#import <UserNotifications/UserNotifications.h>
#import <OmiKit/OmiKit-umbrella.h>
#import <OmiKit/Constants.h>
#import <UserNotifications/UserNotifications.h>

PushKitManager *pushkitManager;
CallKitProviderDelegate * provider;
PKPushRegistry * voipRegistry;
```

<br></br>
- 📌 Edit *AppDelegate.m*:

```objc
#import <OmiKit/OmiKit.h>
#import <omicall_flutter_plugin/omicall_flutter_plugin-Swift.h>
```
<br></br>
- 📌 Add these lines into `didFinishLaunchingWithOptions`:
  
```objc
[OmiClient setEnviroment:KEY_OMI_APP_ENVIROMENT_SANDBOX userNameKey:@"extension" maxCall:1 callKitImage: @"callkit_image" typePushVoip:@"default" representName:@"OMICALL"];
provider = [[CallKitProviderDelegate alloc] initWithCallManager: [OMISIPLib sharedInstance].callManager];
voipRegistry = [[PKPushRegistry alloc] initWithQueue:dispatch_get_main_queue()];
pushkitManager = [[PushKitManager alloc] initWithVoipRegistry:voipRegistry];
if (@available(iOS 10.0, *)) {
    [UNUserNotificationCenter currentNotificationCenter].delegate = (id<UNUserNotificationCenterDelegate>) self;
}

```

📝 Notes:
- To custom callkit image, you need add image into assets and paste image name into setEnviroment function.
- The variable representName is not required. If it has a value, when a call comes in, by default this name will be displayed on callKit. If nothing is transmitted, internal calls will display the Employee's name or the employee's internal 
<br></br>


```objc
- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    bool value = [SwiftOmikitPlugin processUserActivityWithUserActivity:userActivity];
    return value;
}
```

```objc
// This action is used to close ongoing calls when the user kills the app
- (void)applicationWillTerminate:(UIApplication *)application {
    @try {
        [OmiClient OMICloseCall];
    }
    @catch (NSException *exception) {

    }
}
```

- 📌  Add these lines into `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Need camera access for video call functions</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need microphone access for make Call</string>
```

- 💡 Save token for `OmiClient`: if you added `firebase_messaging` in your project so you don't need add these lines.

```objc
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

✨ Only use under lines when added `firebase_messaging` plugin in your project
  - ✅ Setup push notification: We only support Firebase for push notification.
  - ✅ Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - ✅ Add Firebase Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - ✅ For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Config Push for iOS</a>

#### 🚀  iOS(Swift):
- 📝 *Notes: The configurations are similar to those for object C above, with only a slight difference in the syntax of the funcs*

- 📌 Add variables in Appdelegate.swift:

```swift
import OmiKit
import PushKit
import NotificationCenter

var pushkitManager: PushKitManager?
var provider: CallKitProviderDelegate?
var voipRegistry: PKPushRegistry?
```

- 📌 Add these lines into `didFinishLaunchingWithOptions`:

```swift
OmiClient.setEnviroment(KEY_OMI_APP_ENVIROMENT_SANDBOX, prefix: "", userNameKey: "extension", maxCall: 1, callKitImage: "callkit_image" typePushVoip:@"default")
provider = CallKitProviderDelegate.init(callManager: OMISIPLib.sharedInstance().callManager)
voipRegistry = PKPushRegistry.init(queue: .main)
pushkitManager = PushKitManager.init(voipRegistry: voipRegistry)

```

```swift
func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
    var value = SwiftOmikitPlugin.processUserActivity(userActivity: userActivity)
    return value
}
```

-  Add these lines into `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Need camera access for video call functions</string>
<key>NSMicrophoneUsageDescription</key>
<string>Need microphone access for make Call</string>
```

- 💡 Save token for `OmiClient`: if you added `firebase_messaging` in your project so you don't need add these lines.

```swift
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

✨ Only use under lines when added `firebase_messaging` plugin in your project
  - ✅ Setup push notification: We only support Firebase for push notification.
  - ✅ Add `google-service.json` in `android/app` (For more information, you can refer <a href="https://pub.dev/packages/firebase_core">firebase_core</a>)
  - ✅ Add Firebase Messaging to receive `fcm_token` (You can refer <a href="https://pub.dev/packages/firebase_messaging">firebase_messaging</a> to setup notification for Flutter)

  - ✅ For more setting information, please refer <a href="https://api.omicall.com/web-sdk/mobile-sdk/ios-sdk/cau-hinh-push-notification">Config Push for iOS</a>

<br></br>
❌ Important release note

```
We support 2 environments. So you need set correct key in Appdelegate.
- KEY_OMI_APP_ENVIROMENT_SANDBOX support on debug mode
- KEY_OMI_APP_ENVIROMENT_PRODUCTION support on release mode
- Visit on web admin to select correct enviroment.   
```
<br></br>

### 🛠️ STEP 2: Integrate into Flutter code  🚀

#### Request permission

- 📌 We need you request permission about call before make call:

```
 + android.permission.CALL_PHONE (for android)
 + Permission.audio
 + Permission.microphone
 + Permission.camera  (if you want to make Video calls)

```


- 📌 Set up for Firebase:

```dart
await Firebase.initializeApp();
// If you only use Firebase on Android. Add these line `if (Platform.isAndroid)`
// Because we use APNS to push notification on iOS so you don't need add Firebase for iOS.
```


- 📌 Important function.

- 📝 Start Serivce: OmiKit need start services and register some events.
  
```dart
  // Call in the root widget
  OmicallClient.instance.startServices();
```
<br></br>
💡 You need to log in to OMI's switchboard system, we provide you with 2 functions with 2 different functions: <br>

📝 Notes: *The information below is taken from the API, you should connect with our Technical team for support*

- ✅ func initCall: This func is for employees. They can call any telecommunications number allowed in your business on the OMI system.

```dart
    String? token = await FirebaseMessaging.instance.getToken();
    if (Platform.isIOS) {
        token = await FirebaseMessaging.instance.getAPNSToken();
    }
    await OmicallClient.instance.initCall(
      userName: String,  // Replace with your username
      password:String, // Replace with your password
      realm: String,  // Replace with your realm
      host: String, // Replace with your host
      isVideo: bool, // true if video call is enabled, otherwise false
      fcmToken: String // For iOS, use APNSToken; for Android, FCM token
      projectId: String // Replace with your Firebase project ID
    );
    // result is true then user login successfully. 
```
<br>

- ✅ func initCallWithApiKey: is usually used for your client, who only has a certain function, calling a fixed number. For example, you can only call your hotline number

```dart
    String? token = await FirebaseMessaging.instance.getToken();
    if (Platform.isIOS) {
        token = await FirebaseMessaging.instance.getAPNSToken();
    }
     await OmicallClient.instance.initCallWithApiKey(
      usrName:String, // Replace with your username
      usrUuid: String, // Replace with your user UUID
      isVideo: bool, // true if video call is enabled, otherwise false
      apiKey:String,  // Replace with your API key
      fcmToken: String // Note: with IOS, we need APNSToken, and android is FCM_Token,
      projectId: String // Replace with your Firebase project ID
    );
    // result is true then user login successfully. 
```

- ✅ Get call when user open app from killed status(only iOS):
```dart
final result = await OmicallClient.instance.getInitialCall();
  ///if result is not equal False => have a calling.
```

- ✅ Config push notification: With iOS, I only support these keys: `prefixMissedCallMessage`, `missedCallTitle`, `userNameKey`. With Android, We don't support `missedCallTitle`:
  ```dart
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

- ✅ OMI Plugin functions:

##### 📌 Call with Phone Number (Mobile Phone or Internal Number)

```dart
// Used to initiate a call, to any number
final result = await OmicallClient.instance.startCall(
    phone,      // phone number
    _isVideoCall // if true, it's a video call; otherwise, it's an audio call.
);

// After calling func, please wait and check the results. Once in state 8 navigate to your ActiveCall screen
```

| **Note**                                                                                                                                                          |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| You must `await` the call. When the result equals **8**, it means the call was started successfully—use this status to trigger navigation or further actions. |
| **OmiStartCallStatus:**                                                                                                                                           |
| - **invalidUuid (0):** The provided UUID is invalid (cannot be found in our system).                                                                              |
| - **invalidPhoneNumber (1):** The SIP user (phone number) is invalid.                                                                                             |
| - **samePhoneNumber (2):** Cannot call the same phone number.                                                                                                     |
| - **maxRetry (3):** We attempted to refresh the call, but we couldn't start it.                                                                                    |
| - **permissionDenied (4):** Check if the audio permission is granted.                                                                                            |
| - **couldNotFindEndpoint (5):** Please log in before making your call.                                                                                           |
| - **accountRegisterFailed (6):** We cannot register your account.                                                                                                |
| - **startCallFailed (7):** We cannot start your call.                                                                                                            |
| - **startCallSuccess (8):** The call has started successfully.                                                                                                   |
| - **haveAnotherCall (9):** Cannot start the call because you are already in another call.                                                                          |

    
##### 📌 Call with UUID (only support with Api key):
    
```dart
  final result = OmicallClient.instance.startCallWithUUID(
      uuid, //your user id
      _isVideoCall, //call video or audio. If true is video call. 
  );
  // Result is the same with startCall
```

##### 📌 Accept a call:
Used to join (pick up) any incoming call
```dart
    OmicallClient.instance.joinCall();
```

##### 📌 End a Call  
When a call ends, an event `endCall` is pushed and the call information is returned.

```dart
OmicallClient.instance.endCall().then((callInfo) {
  // callInfo contains the call details
  print(callInfo);
});

/* Sample output:
{
  "transaction_id": "ea7dff38-cb1e-483d-8576-xxxxxxxxxxxx",
  "direction": "inbound",
  "source_number": 111,
  "destination_number": 110,
  "time_start_to_answer": 1682858097393,
  "time_end": 1682858152181,
  "sip_user": 111,
  "disposition": "answered"
}
*/
```
##### 📌 Toggle the Audio  
Toggle the audio on/off during a call.

```dart
OmicallClient.instance.toggleAudio();
```

---

##### Toggle the Speaker  
📌 Toggle the phone speaker on/off.

```dart
OmicallClient.instance.toggleSpeaker();
```

---

##### 📌 Toggle the Hold  
Used to hold an ongoing call

```dart
OmicallClient.instance.toggleHold();
```

---

##### 📌 Send Character  
Send DTMF characters. Supported characters: `1` to `9`, `*` and `#`.

```dart
OmicallClient.instance.sendDTMF(value);
```

---

##### 📌 Transfer call  
Used to forward the current ongoing call to any employee in your business

```dart
// phoneNumber: String - is number internal employee in your business 
OmicallClient.instance.transferCall(phoneNumber: "101");
```

---

##### 📌 Get Current User Information  
Retrieve information of the current user.

```dart
final user = await OmicallClient.instance.getCurrentUser();
// Sample output:
{
  "extension": "111",
  "full_name": "chau1",
  "avatar_url": "",
  "uuid": "122aaa"
}
```

---

##### 📌 Get Guest User Information  
Retrieve information of the guest user.

```dart
final user = await OmicallClient.instance.getGuestUser();
// Sample output:
{
  "extension": "111",
  "full_name": "chau1",
  "avatar_url": "",
  "uuid": "122aaa"
}
```

---

##### 📌 Get User Information from SIP  
Retrieve user information based on a SIP phone number.

```dart
final user = await OmicallClient.instance.getUserInfo(phone: "111");
// Sample output:
{
  "extension": "111",
  "full_name": "chau1",
  "avatar_url": "",
  "uuid": "122aaa"
}
```

---

##### 📌 Logout  
Log out the current user.

```dart
OmicallClient.instance.logout();
```


##### Video Call Functions   🚀🚀 
>📝  **Note:** These functions support video calls only. Make sure you enable video in the initialization functions and when starting a call.

- 📌 **Switch Front/Back Camera**  
  Use this function to switch between the front and back cameras. By default, the front camera is used for the initial call.
  
  ```dart
  OmicallClient.instance.switchCamera();
  ```

- 📌  **Toggle Video During Call**  
  Turn the video on or off during an active call.
  
  ```dart
  OmicallClient.instance.toggleVideo();
  ```

- 📌 **Register Video Event**  
  Listen for remote video readiness. *(Replace with the actual function if different.)*
  
  ```dart
  OmicallClient.instance.registerVideoEvent();
  ```

- 📌 **Remove Video Event**  
  Remove the remote video event listener.
  
  ```dart
  OmicallClient.instance.removeVideoEvent();
  ```

- 📌 **Local Camera Widget**  
  Display your local camera view during a call.
  
  ```dart
  LocalCameraView(
    width: double.infinity,
    height: double.infinity,
    onCameraCreated: (controller) {
      _localController = controller;
      // The controller can be used for further actions.
    },
  )
  ```

- 📌 **Remote Camera Widget**  
  Display the remote camera view during a call.
  
  ```dart
  RemoteCameraView(
    width: double.infinity,
    height: double.infinity,
    onCameraCreated: (controller) {
      _remoteController = controller;
    },
  )
  ```

- 📌 **Refresh Camera Functions**  
  Use the controllers to refresh the camera views when needed.
  
  ```dart
  // Assume controllers are defined:
  RemoteCameraController? _remoteController;
  LocalCameraController? _localController;
  
  // Refresh the remote camera
  void refreshRemoteCamera() {
    _remoteController?.refresh();
  }
  
  // Refresh the local camera
  void refreshLocalCamera() {
    _localController?.refresh();
  }
  ```
  <br>
#### Event listener ✨:
- 📌 **Important Event: `callStateChangeEvent`**  
  Listen to call state changes. The event returns an `OmiAction` object that contains two variables: `actionName` and `data`.

  ```dart
  OmicallClient.instance.controller.callStateChangeEvent.listen((action) {
    // Process action.actionName and action.data
    debugPrint("Received action: ${action.actionName} with data: ${action.data}");
  });
  ```

  ✅ **Action Name Values:**
  - `onCallStateChanged`: Call state has changed.
  - `onSwitchboardAnswer`: The switchboard SIP is listening.
  
  ✅ **Call State Status:**
  - `unknown (0)`
  - `calling (1)`
  - `incoming (2)`
  - `early (3)`
  - `connecting (4)`
  - `confirmed (5)`
  - `disconnected (6)`
  - `hold (7)`

  ✅ **Details for `onCallStateChanged`:**
  - `isVideo`: `bool` (true for video call)
  - `status`: `number` (matching one of the statuses above)
  - `callerNumber`: Phone number
  - `incoming`: `bool` (indicates incoming or outgoing call)
  - `_id`: (optional, call identifier)

  ✅ **Lifecycle:**
  - **Incoming call:** `incoming` → `connecting` → `confirmed` → `disconnected`
  - **Outgoing call:** `calling` → `early` → `connecting` → `confirmed` → `disconnected`

- 📌 **Other Events:**

  - 📌 **Call Quality Event:**  
    Listen to call quality changes. The event returns a Map with keys such as `quality`, and a nested `stat` object.

    ```dart
    OmicallClient.instance.setCallQualityListener((data) {
      final quality = data["quality"] as int; // 0: GOOD, 1: NORMAL, 2: BAD
      final req = data["stat"]["req"] as double;      // Time taken for the call
      final mos = data["stat"]["mos"] as double;        // MOS value
      final jitter = data["stat"]["jitter"] as double;  // Jitter
      final latency = data["stat"]["latency"] as double;// Latency
      final ppl = data["stat"]["ppl"] as double;        // Packet loss percentage
      final lcn = data["stat"]["lcn"] as int;           // Loss connect count
      final isNeedLoading = data["isNeedLoading"] as bool; // Show loading if true
      debugPrint("Call quality: $quality, req: $req, mos: $mos, jitter: $jitter, latency: $latency, ppl: $ppl, lcn: $lcn, isNeedLoading: $isNeedLoading");
    });
    ```

  - 📌 **Speaker Event:**  
    Listen for speaker status changes.

    ```dart
    OmicallClient.instance.setSpeakerListener((data) {
      setState(() {
        isSpeaker = data;
      });
    });
    // data: current speaker status (bool)
    ```

  - 📌 **Mute Event:**  
    Listen for mute status changes.

    ```dart
    OmicallClient.instance.setMuteListener((data) {
      setState(() {
        isMuted = data;
      });
    });
    // data: current mute status (bool)
    ```
  - 📌 **Hold Event:**  
    Listen for hold status changes.

    ```dart
    OmicallClient.instance.setHoldListener((data) {
      setState(() {
        isHold = data;
      });
    });
    // data: current hold status (bool)
    ```

  - 📌 **Remote Video Ready Event:**  
    Listen for when remote video is ready. Refresh the camera views as needed.

    ```dart
    OmicallClient.instance.setVideoListener((data) {
      refreshRemoteCamera(); // refresh remote camera view
      refreshLocalCamera();  // refresh local camera view
    });
    ```

  - 📌 **Missed Call Notification:**  
    Triggered when a user taps a missed call notification. The event returns a Map with keys `callerNumber` and `isVideo`.

    ```dart
    OmicallClient.instance.setMissedCallListener((data) {
      final String callerNumber = data["callerNumber"];
      final bool isVideo = data["isVideo"];
      makeCallWithParams(context, callerNumber, isVideo);
    });
    // data: Map with "callerNumber" and "isVideo"
    ```

  - 📌 **Call Log Event (iOS Only):**  
    Triggered when the user taps a call log entry.

    ```dart
    OmicallClient.instance.setCallLogListener((data) {
      final String callerNumber = data["callerNumber"];
      final bool isVideo = data["isVideo"];
      makeCallWithParams(context, callerNumber, isVideo);
    });
    // data: Map with "callerNumber" and "isVideo"
    ```

<br>

- 📝 Table describing **code_end_call** status


| Code            | Description                                                                                                           |
| --------------- | --------------------------------------------------------------------------------------------------------------------- |
| `600, 503`  | These are the codes of the network operator or the user who did not answer the call  |
| `408`   | Call request timeout (Each call usually has a waiting time of 30 seconds. If the 30 seconds expire, it will time out) |
| `403`           | Your service plan only allows calls to dialed numbers. Please upgrade your service pack|
| `404`           | The current number is not allowed to make calls to the carrier|
| `480`           | The number has an error, please contact support to check the details |
| `603`           | The call was rejected. Please check your account limit or call barring configuration! |
| `850`           | Simultaneous call limit exceeded, please try again later |
| `486`           | The listener refuses the call and does not answer |
| `601`           | Call ended by the customer |
| `602`           | Call ended by the other employee |
| `603`           | The call was rejected. Please check your account limit or call barring configuration |
| `850`           | Simultaneous call limit exceeded, please try again later |
| `851`           | Call duration limit exceeded, please try again later |
| `852`           | Service package not assigned, please contact the provider |
| `853`           | Internal number has been disabled |
| `854`           | Subscriber is in the DNC list |
| `855`           | Exceeded the allowed number of calls for the trial package |
| `856`           | Exceeded the allowed minutes for the trial package |
| `857`           | Subscriber has been blocked in the configuration |
| `858`           | Unidentified or unconfigured number |
| `859`           | No available numbers for Viettel direction, please contact the provider |
| `860`           | No available numbers for VinaPhone direction, please contact the provider |
| `861`           | No available numbers for Mobifone direction, please contact the provider |
| `862`           | Temporary block on Viettel direction, please try again |
| `863`           | Temporary block on VinaPhone direction, please try again |
| `864`           | Temporary block on Mobifone direction, please try again |
| `865`           | he advertising number is currently outside the permitted calling hours, please try again later |

