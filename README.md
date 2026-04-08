# 📦 OMICALL SDK FOR Flutter

The OmiKit exposes the 📦 <a href="https://pub.dev/packages/omicall_flutter_plugin">omicall_flutter_plugin</a> library.

The most important part of the framework is :
- ✅ Help to easy integrate with Omicall.
- ✅ Easy custom Call UI/UX.
- ✅ Optimize codec voip for you.
- ✅ Full interface to interactive with core function like sound/ringtone/codec.
- ✅ Built-in Call Quality Monitoring (MOS score tracking)

### 📝 Status
Currently active maintenance and improve performance

---

## 📚 Table of Contents

- [Quick Start](#quick-start)
- [Architecture Overview](#architecture-overview)
- [Configuration](#configuration)
  - [Android Setup](#-android)
  - [iOS Setup](#-iosobject-c)
  - [Flutter Integration](#️-step-2-integrate-into-flutter-code--)
- [Call Flow Lifecycle](#call-flow-lifecycle)
- [API Reference](#api-reference)
  - [Core Functions](#core-functions)
  - [Call Control](#call-control)
  - [Video Call Functions](#video-call-functions--)
  - [Call Quality Monitoring](#-call-quality-monitoring-new)
- [Event Listeners](#event-listener-)
- [Error Codes](#error-codes)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

---

## Quick Start

Install via pubspec.yaml:

```yaml
dependencies:
  omicall_flutter_plugin: ^latest_version
```

Minimum setup:

```dart
// 1. Start services
await OmicallClient.instance.startServices();

// 2. Login
await OmicallClient.instance.initCall(
  userName: "your_username",
  password: "your_password",
  realm: "your_realm",
  host: "your_host",
  isVideo: false,
  fcmToken: fcmToken,
  projectId: "your_firebase_project_id"
);

// 3. Make a call
final result = await OmicallClient.instance.startCall(phoneNumber, false);
```

---

## Architecture Overview

### 📐 System Architecture

```
┌──────────────────────────────────────────────────────────────────┐
│                        Flutter Layer                             │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Your Flutter App (UI/UX)                                  │  │
│  │  ┌─────────────┐  ┌──────────────┐  ┌──────────────────┐   │  │
│  │  │ Call Screen │  │ Dial Screen  │  │ Settings Screen  │   │  │
│  │  └──────┬──────┘  └──────┬───────┘  └────────┬─────────┘   │  │
│  └─────────┼─────────────────┼────────────────────┼───────────┘  │
│            │                 │                    │              │
│            └─────────────────┴────────────────────┘              │
│                              │                                   │
├──────────────────────────────┼───────────────────────────────────┤
│                    OmicallClient API                             │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │  • startCall()        • toggleAudio()   • getCurrentUser() │  │
│  │  • endCall()          • toggleSpeaker() • getGuestUser()   │  │
│  │  • joinCall()         • toggleHold()    • getUserInfo()    │  │
│  │  • sendDTMF()         • toggleVideo()   • logout()         │  │
│  │  • switchCamera()     • transferCall()                     │  │
│  └────────────────────────────────────────────────────────────┘  │
│                              │                                   │
│  ┌──────────────────────────┴─────────────────────────────────┐  │
│  │              Event Listeners & Helpers                     │  │
│  │  • callStateChangeEvent  • CallQualityTracker              │  │
│  │  • setCallQualityListener • CallQualityInfo                │  │
│  │  • setMuteListener       • VideoController                 │  │
│  │  • setSpeakerListener    • CameraView                      │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬───────────────────────────────────┘
                               │ Method Channel
┌──────────────────────────────┴───────────────────────────────────┐
│                   Flutter Plugin Bridge                          │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Platform: Android (Kotlin)    Platform: iOS (Swift/ObjC)  │  │
│  │  • OmicallsdkPlugin            • SwiftOmikitPlugin         │  │
│  │  • Event Broadcasting          • Event Broadcasting        │  │
│  │  • Permission Handling         • CallKit Integration       │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬───────────────────────────────────┘
                               │
┌──────────────────────────────┴───────────────────────────────────┐
│                    Native SDK Layer                              │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Android SDK (vn.vihat.omicall.omisdk)                     │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │  │
│  │  │ SipService   │  │ CallManager  │  │ AudioManager     │  │  │
│  │  │ (OMISIP)      │  │              │  │                  │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  iOS SDK (OmiKit)                                          │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │  │
│  │  │ OMISIPLib    │  │ CallManager  │  │ PushKitManager   │  │  │
│  │  │ (OMISIP)      │  │              │  │                  │  │  │
│  │  └──────────────┘  └──────────────┘  └──────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                               │
                    ┌──────────┴──────────┐
                    │   Network Layer     │
                    │  • SIP Protocol     │
                    │  • RTP/SRTP         │
                    │  • STUN/TURN        │
                    └─────────────────────┘
```

### 🔄 Data Flow

```
User Action → Flutter UI → OmicallClient → Platform Channel
           → Native SDK → SIP Server → Remote Peer

Remote Peer → Native SDK → Event Broadcast → OmicallClient
           → Flutter Listeners → UI Update
```

---

## Call Flow Lifecycle

### 📞 Outgoing Call Flow

```
┌─────────┐
│ Flutter │ startCall(phoneNumber, isVideo)
│   App   │ ─────────────────────────────────────────┐
└─────────┘                                          │
                                                     ▼
┌──────────────────────────────────────────────────────────────┐
│                    Call State Changes                        │
│                                                              │
│  UNKNOWN (0)                                                 │
│      │                                                       │
│      ├─── Check permissions & account status                 │
│      │                                                       │
│      ▼                                                       │
│  CALLING (1) ◄─ startCallSuccess (status=8)                  │
│      │           "Initiating call..."                        │
│      │           ⏱️  Ring tone starts                        │
│      │                                                       │
│      ▼                                                       │
│  EARLY (3)                                                   │
│      │           "Ringing..."                                │
│      │           ⏱️  Waiting for remote peer                 │
│      │                                                       │
│      ▼                                                       │
│  CONNECTING (4)                                              │
│      │           "Connecting..."                             │
│      │           🔊 Remote peer answered                     │
│      │                                                       │
│      ▼                                                       │
│  CONFIRMED (5)                                               │
│      │           "Active call"                               │
│      │           📊 Call quality monitoring starts           │
│      │           ⏱️  Call timer starts                       │
│      │           🎙️  Audio/Video stream active               │
│      │                                                       │
│      │  ┌──────────────────────────────────┐                 │
│      │  │  User can perform:               │                 │
│      │  │  • toggleAudio() - Mute/Unmute   │                 │
│      │  │  • toggleSpeaker() - Speaker on  │                 │
│      │  │  • toggleHold() - Hold/Unhold    │                 │
│      │  │  • toggleVideo() - Video on/off  │                 │
│      │  │  • sendDTMF() - Send numbers     │                 │
│      │  │  • transferCall() - Transfer     │                 │
│      │  │  • endCall() - Hang up           │                 │
│      │  └──────────────────────────────────┘                 │
│      │                                                       │
│      ▼                                                       │
│  DISCONNECTED (6)                                            │
│      │           "Call ended"                                │
│      │           📊 Call info returned                       │
│      │           ⏱️  Final duration calculated               │
│      │           🧹 Cleanup resources                        │
│      │                                                       │
│      ▼                                                       │
│  UNKNOWN (0)                                                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Timeline Example:
─────────────────────────────────────────────────────────────►
0s        2s        4s        7s        45s       47s
│         │         │         │         │         │
UNKNOWN   CALLING   EARLY     CONNECTING CONFIRMED DISCONNECTED
          "Dialing" "Ringing" "Answered" "Talking" "Ended"
```

### 📲 Incoming Call Flow

```
┌─────────────┐
│ Push Notif  │ Firebase/APNS Push
│ or CallKit  │ ───────────────────────────────────────┐
└─────────────┘                                        │
                                                       ▼
┌──────────────────────────────────────────────────────────────┐
│                    Call State Changes                        │
│                                                              │
│  UNKNOWN (0)                                                 │
│      │                                                       │
│      ▼                                                       │
│  INCOMING (2)                                                │
│      │           "Incoming call from XXX"                    │
│      │           🔔 Ringtone plays                           │
│      │           📱 CallKit/Notification shows               │
│      │                                                       │
│      │  ┌──────────────────────────────────┐                 │
│      │  │  User Actions:                   │                 │
│      │  │  • joinCall() ────┐              │                 │
│      │  │  • endCall() ─────┼────┐         │                 │
│      │  └──────────────────────────────────┘                 │
│      │                      │    │                           │
│      │  ◄───────────────────┘    │                           │
│      ▼                            │                          │
│  CONNECTING (4)                   │                          │
│      │           "Answering..."  │                           │
│      │           🔊 Audio setup   │                          │
│      │                            │                          │
│      ▼                            │                          │
│  CONFIRMED (5)                    │                          │
│      │           "Active call"   │                           │
│      │           📊 Quality monitoring                       │
│      │           🎙️  Audio stream active                     │
│      │                            │                          │
│      │  [Same actions as         │                           │
│      │   outgoing call]           │                          │
│      │                            │                          │
│      ▼                            ▼                          │
│  DISCONNECTED (6) ◄───────── DISCONNECTED (6)                │
│      │           "Answered & Ended" "Rejected"               │
│      │           📊 Call duration    📊 No duration          │
│      │                                                       │
│      ▼                                                       │
│  UNKNOWN (0)                                                 │
│                                                              │
└──────────────────────────────────────────────────────────────┘

Timeline Example (Answer):
─────────────────────────────────────────────────────────────►
0s        1s        3s        30s       32s
│         │         │         │         │
UNKNOWN   INCOMING  CONNECTING CONFIRMED DISCONNECTED
          "Ringing" "Answered" "Talking" "Ended"

Timeline Example (Reject):
─────────────────────────────────────────────────────────────►
0s        1s        4s
│         │         │
UNKNOWN   INCOMING  DISCONNECTED
          "Ringing" "Rejected"
```

### 🔁 Hold State Flow

```
CONFIRMED (5)
     │
     ├─ toggleHold() ──►  HOLD (7)
     │                       │
     │                       ├─ "Call on hold"
     │                       ├─ 🔇 Audio muted for both
     │                       │
     │  ◄──── toggleHold() ──┤
     │
     ▼
CONFIRMED (5)
     │
     ├─ "Call resumed"
     ├─ 🔊 Audio restored
```

---

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

**⚠️ IMPORTANT:** This configuration is required for Android 13+ (API 33+) and Android 14+ (API 34+). Missing permissions will cause crashes or prevent calls from working.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <!-- Hardware features - telephony is optional for VoIP apps -->
    <uses-feature
        android:name="android.hardware.telephony"
        android:required="false" />

    <!-- Basic permissions -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="com.google.android.c2dm.permission.RECEIVE" />
    <uses-permission android:name="android.permission.WAKE_LOCK" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE" />

    <!-- Android 14+ (API 34+) - REQUIRED for foreground service types -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_PHONE_CALL" />

    <!-- Android 13+ (API 33+) - REQUIRED for notifications -->
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

    <!-- CRITICAL: Explicitly remove FOREGROUND_SERVICE_CAMERA to prevent crashes on Android 14-15 -->
    <!-- See CHANGELOG 2.3.78: This permission causes crashes on devices without camera -->
    <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" tools:node="remove" />

    <!-- Connection Service for Android 15-16 -->
    <uses-permission android:name="android.permission.MANAGE_OWN_CALLS" />

    <application
        android:name=".MainApplication"
        android:label="Your App Name"
        android:enableOnBackInvokedCallback="true"
        android:alwaysRetainTaskState="true"
        android:largeHeap="true"
        android:exported="true"
        android:supportsRtl="true"
        android:allowBackup="false"
        android:fullBackupContent="false"
        android:icon="@mipmap/ic_launcher">

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:showWhenLocked="true"
            android:turnScreenOn="true"
            android:windowSoftInputMode="adjustResize"
            android:showOnLockScreen="true"
            android:launchMode="singleTask"
            android:largeHeap="true"
            android:alwaysRetainTaskState="true"
            android:supportsPictureInPicture="false">

            <!-- Your theme configuration -->
            <meta-data
                android:name="io.flutter.embedding.android.NormalTheme"
                android:resource="@style/NormalTheme" />

            <!-- Main launcher intent -->
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>

            <!-- Incoming call intent -->
            <intent-filter>
                <action android:name="android.intent.action.CALL" />
                <category android:name="android.intent.category.DEFAULT" />
                <data
                    android:host="incoming_call"
                    android:scheme="omisdk" />
            </intent-filter>

        </activity>

        <!-- Firebase Message Receiver -->
        <receiver
            android:name="vn.vihat.omicall.omisdk.receiver.FirebaseMessageReceiver"
            android:exported="true"
            android:enabled="true"
            android:foregroundServiceType="remoteMessaging"
            tools:replace="android:exported"
            android:permission="com.google.android.c2dm.permission.SEND">
            <intent-filter>
                <action android:name="com.google.android.c2dm.intent.RECEIVE" />
            </intent-filter>
        </receiver>

        <!-- Notification Service -->
        <service
            android:name="vn.vihat.omicall.omisdk.service.NotificationService"
            android:enabled="true"
            android:exported="false"
            android:foregroundServiceType="microphone|phoneCall">
            <!-- IMPORTANT: Only microphone|phoneCall, NO camera (see CHANGELOG 2.3.78) -->
        </service>

        <!-- Flutter plugin metadata -->
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />

    </application>
</manifest>
```

**📝 Critical Notes:**

1. **FOREGROUND_SERVICE_CAMERA removal is REQUIRED:**
   ```xml
   <uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" tools:node="remove" />
   ```
   - Without `tools:node="remove"`, app **WILL CRASH** on Android 14-15 devices without camera
   - See CHANGELOG 2.3.78 for details

2. **Android 14+ requires foregroundServiceType:**
   - NotificationService: `android:foregroundServiceType="microphone|phoneCall"` (NOT camera)
   - FirebaseMessageReceiver: `android:foregroundServiceType="remoteMessaging"`

3. **Android 13+ requires POST_NOTIFICATIONS:**
   - Request this permission at runtime for notifications to work
   - Add to your permissions request flow

4. **Android 15-16 requires MANAGE_OWN_CALLS:**
   - For connection service integration

5. **Optional — Disable saving calls to device call history (`WRITE_CALL_LOG`):**
   By default the SDK may request `WRITE_CALL_LOG` to log calls in the native call history. If your app does **not** want calls saved to the device's call history, explicitly remove this permission:
   ```xml
   <uses-permission android:name="android.permission.WRITE_CALL_LOG" tools:node="remove" />
   ```
   > **Note:** `xmlns:tools="http://schemas.android.com/tools"` must be declared in the `<manifest>` tag (already included in the manifest template above).

**Runtime Permission Request Example:**
```kotlin
// In your MainActivity or permissions handler
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
    requestPermissions(arrayOf(
        Manifest.permission.POST_NOTIFICATIONS
    ), REQUEST_CODE_NOTIFICATIONS)
}
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
import 'dart:convert';

String? token = await FirebaseMessaging.instance.getToken();
if (Platform.isIOS) {
    token = await FirebaseMessaging.instance.getAPNSToken();
}

final initResult = await OmicallClient.instance.initCallWithUserPassword(
  userName: String,
  password: String,
  realm: String,
  host: String,
  isVideo: bool,
  fcmToken: token,
  projectId: String,
);

// Parse JSON response
final initJson = initResult is String ? jsonDecode(initResult) as Map : {};
final status = initJson['status'] as int? ?? 0;
final message = initJson['message'] as String? ?? '';

if (status != 200) {
  // message: NETWORK_UNAVAILABLE | MISSING_PARAMS | INIT_FAILED
  showError(message);
  return;
}
// Login successful — proceed
```
<br>

- ✅ func initCallWithApiKey: is usually used for your client, who only has a certain function, calling a fixed number. For example, you can only call your hotline number

```dart
import 'dart:convert';

String? token = await FirebaseMessaging.instance.getToken();
if (Platform.isIOS) {
    token = await FirebaseMessaging.instance.getAPNSToken();
}

final initResult = await OmicallClient.instance.initCallWithApiKey(
  usrName: String,
  usrUuid: String,
  isVideo: bool,
  apiKey: String,
  fcmToken: token,
  projectId: String,
);

// Parse JSON response
final initJson = initResult is String ? jsonDecode(initResult) as Map : {};
final status = initJson['status'] as int? ?? 0;
final message = initJson['message'] as String? ?? '';

if (status != 200) {
  // message: NETWORK_UNAVAILABLE | MISSING_PARAMS | INIT_FAILED
  showError(message);
  return;
}
// Login successful — proceed
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

---

## API Reference

### Core Functions

#### 📌 Authentication

##### initCallWithUserPassword
Login for employees (can call any number allowed in business)

```dart
final initResult = await OmicallClient.instance.initCallWithUserPassword(
  userName: String,
  password: String,
  realm: String,
  host: String,
  isVideo: bool,
  fcmToken: String,
  projectId: String,
);
```

**Returns** `Future<dynamic>` — JSON string `{"status": Int, "message": String}`

| `status` | `message` | Meaning |
|----------|-----------|---------|
| `200` | `INIT_SUCCESS` | Login successful |
| `400` | `MISSING_PARAMS` | Required fields missing |
| `500` | `INIT_FAILED` | Wrong credentials or SDK error |
| `600` | `NETWORK_UNAVAILABLE` | No internet connection |

##### initCallWithApiKey
Login for clients (call fixed number, e.g., hotline)

```dart
final initResult = await OmicallClient.instance.initCallWithApiKey(
  usrName: String,
  usrUuid: String,
  isVideo: bool,
  apiKey: String,
  fcmToken: String,
  projectId: String,
);
```

**Returns** `Future<dynamic>` — same JSON format as `initCallWithUserPassword` above.

##### logout
Logout current user

```dart
OmicallClient.instance.logout();
```

---

### Call Control

##### 📌 Start Call (Phone Number)
Initiate outgoing call to any number

```dart
final result = await OmicallClient.instance.startCall(
    phone,      // phone number
    _isVideoCall // if true, it's a video call; otherwise, it's an audio call.
);
```

**Return values (OmiStartCallStatus):**

| Status | Code | Description |
|--------|------|-------------|
| `invalidUuid` | 0 | UUID không hợp lệ (không tìm thấy trong hệ thống) |
| `invalidPhoneNumber` | 1 | Số điện thoại SIP không hợp lệ |
| `samePhoneNumber` | 2 | Không thể gọi cùng số điện thoại |
| `maxRetry` | 3 | Hết lượt retry, không thể khởi tạo cuộc gọi |
| `permissionDenied` | 4 | Quyền audio bị từ chối |
| `couldNotFindEndpoint` | 5 | Vui lòng đăng nhập trước khi gọi |
| `accountRegisterFailed` | 6 | Không thể đăng ký tài khoản |
| `startCallFailed` | 7 | Không thể bắt đầu cuộc gọi |
| **`startCallSuccess`** | **8** | **Cuộc gọi bắt đầu thành công** ⬅️ Use this to navigate |
| `haveAnotherCall` | 9 | Đang có cuộc gọi khác |
| `accountTurnOffNumberInternal` | 10 | Tài khoản đã tắt tính năng gọi nội bộ |
| `noNetwork` | 11 | Không có kết nối mạng |

> **Note (Android/iOS difference):** The `status` code differs by platform (`408` on Android, `11` on iOS). Use `message` field instead for cross-platform handling: `jsonMap['message'] == 'NO_NETWORK'`.

**Important:** Wait for status **8** before navigating to call screen!

##### 📌 Start Call (UUID)
Call using user UUID (API key only)

```dart
final result = OmicallClient.instance.startCallWithUUID(
    uuid,         // user id
    _isVideoCall  // call video or audio
);
```

##### 📌 Join Call
Answer incoming call

```dart
OmicallClient.instance.joinCall();
```

##### 📌 End Call
Hang up current call

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

##### 📌 Toggle Audio (Mute/Unmute)
Toggle microphone on/off

```dart
OmicallClient.instance.toggleAudio();
```

##### 📌 Toggle Speaker
Switch between earpiece and speaker

```dart
OmicallClient.instance.toggleSpeaker();
```

##### 📌 Toggle Hold
Hold/Unhold current call

```dart
OmicallClient.instance.toggleHold();
```

##### 📌 Send DTMF
Send number characters (1-9, *, #)

```dart
OmicallClient.instance.sendDTMF(value);
```

##### 📌 Transfer Call
Forward call to another employee

```dart
OmicallClient.instance.transferCall(phoneNumber: "101");
```

##### 📌 Get Current User
Retrieve logged-in user information

```dart
final user = await OmicallClient.instance.getCurrentUser();
// Output: { "extension": "111", "full_name": "John", "avatar_url": "", "uuid": "122aaa" }
```

##### 📌 Get Guest User
Retrieve remote user information

```dart
final user = await OmicallClient.instance.getGuestUser();
// Output: { "extension": "111", "full_name": "Jane", "avatar_url": "", "uuid": "456bbb" }
```

##### 📌 Get User Info (SIP)
Lookup user by phone number

```dart
final user = await OmicallClient.instance.getUserInfo(phone: "111");
// Output: { "extension": "111", "full_name": "Alice", "avatar_url": "", "uuid": "789ccc" }
```

---

### Video Call Functions   🚀🚀
>📝  **Note:** These functions support video calls only. Make sure you enable video in the initialization functions and when starting a call.

##### 📌 Switch Camera
Toggle between front/back camera

```dart
OmicallClient.instance.switchCamera();
```

##### 📌 Toggle Video
Turn video on/off during call

```dart
OmicallClient.instance.toggleVideo();
```

##### 📌 Register Video Event
Listen for remote video readiness

```dart
OmicallClient.instance.registerVideoEvent();
```

##### 📌 Remove Video Event
Remove video event listener

```dart
OmicallClient.instance.removeVideoEvent();
```

##### 📌 Local Camera Widget
Display your camera view

```dart
LocalCameraView(
  width: double.infinity,
  height: double.infinity,
  onCameraCreated: (controller) {
    _localController = controller;
  },
)
```

##### 📌 Remote Camera Widget
Display remote camera view

```dart
RemoteCameraView(
  width: double.infinity,
  height: double.infinity,
  onCameraCreated: (controller) {
    _remoteController = controller;
  },
)
```

##### 📌 Refresh Camera
Refresh camera views when needed

```dart
// Refresh remote camera
_remoteController?.refresh();

// Refresh local camera
_localController?.refresh();
```

---

### 📊 Call Quality Monitoring (NEW)

The SDK provides built-in call quality tracking using **MOS (Mean Opinion Score)** and **LCN (Loss Connect Number)** metrics.

#### Quick Setup

```dart
import 'package:omicall_flutter_plugin/omicall.dart';
import 'package:omicall_flutter_plugin/models/call_quality_info.dart';
import 'package:omicall_flutter_plugin/utils/call_quality_tracker.dart';

class MyCallScreen extends StatefulWidget {
  @override
  State<MyCallScreen> createState() => _MyCallScreenState();
}

class _MyCallScreenState extends State<MyCallScreen> {
  final CallQualityTracker _qualityTracker = CallQualityTracker();
  String callQuality = "";

  @override
  void initState() {
    super.initState();

    // Set up call quality listener
    OmicallClient.instance.setCallQualityListener((data) {
      // Parse call quality data using helper
      final info = _qualityTracker.parseCallQuality(data);

      debugPrint("CallQualityInfo => $info");

      // Handle loading indicator (network issue detection)
      if (info.shouldShowLoading) {
        EasyLoading.show(); // Show loading when network stuck
      } else if (info.isNetworkRecovered || info.lcn == 0) {
        EasyLoading.dismiss(); // Dismiss when network recovers
      }

      // Display MOS score
      setState(() {
        callQuality = info.mosDisplay; // "4.5", "3.2", etc.
      });
    });
  }

  @override
  void dispose() {
    _qualityTracker.reset(); // Reset tracker when screen closes
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: [
            Text("Call Quality: $callQuality"),
            // Display quality level: "Excellent", "Good", "Fair", "Poor", "Bad"
          ],
        ),
      ),
    );
  }
}
```

#### CallQualityInfo Properties

| Property | Type | Description |
|----------|------|-------------|
| `mos` | `double` | MOS score (1.0-5.0) - call quality metric |
| `mosDisplay` | `String` | Formatted MOS for display (e.g., "4.5") |
| `qualityText` | `String` | Quality level: "Excellent", "Good", "Fair", "Poor", "Bad" |
| `lcn` | `int` | Loss Connect Number (connection loss tracking) |
| `quality` | `int` | Quality level (0=good, 1=normal, 2=bad) |
| `jitter` | `double` | Jitter in milliseconds |
| `latency` | `double` | Latency in milliseconds |
| `packetLoss` | `double` | Packet loss percentage |
| `shouldShowLoading` | `bool` | Whether to show loading indicator |
| `isNetworkRecovered` | `bool` | Whether network has recovered |
| `consecutiveSameLcnCount` | `int` | Current consecutive same LCN count |

#### MOS Score Scale

| MOS Range | Quality Level | Description |
|-----------|---------------|-------------|
| **≥ 4.0** | **Excellent** | Xuất sắc - Perfect call quality |
| **3.5-4.0** | **Good** | Tốt - High quality |
| **3.0-3.5** | **Fair** | Chấp nhận được - Acceptable |
| **2.0-3.0** | **Poor** | Kém - Low quality |
| **< 2.0** | **Bad** | Rất kém - Very poor |

#### Loading Logic (Network Issue Detection)

The loading indicator is automatically shown/hidden based on LCN tracking:

```
Show Loading:
  ├─ LCN value stays the same for ≥3 consecutive events
  └─ Indicates network stuck/frozen

Hide Loading:
  ├─ LCN value changes (network recovered)
  └─ LCN value is 0 (no connection loss)
```

**Timeline Example:**
```
Event 1: LCN=5 → Count=0 → No loading
Event 2: LCN=5 → Count=1 → No loading
Event 3: LCN=5 → Count=2 → No loading
Event 4: LCN=5 → Count=3 → ⚠️ SHOW LOADING (network stuck!)
Event 5: LCN=6 → Count=0 → ✅ HIDE LOADING (network recovered!)
```

#### Benefits

✅ **Clean Code**: No manual parsing logic in UI code
✅ **Consistent**: Same logic across all screens
✅ **Maintainable**: Update logic in one place
✅ **Type Safe**: Strongly typed data
✅ **Testable**: Easy to unit test
✅ **Automatic**: Loading logic handled automatically

For more details, see [lib/utils/README.md](lib/utils/README.md)

---

## Event Listener ✨

### 📌 Call State Change Event (IMPORTANT)

Listen to all call state changes:

```dart
OmicallClient.instance.callStateChangeEvent.listen((action) {
  debugPrint("Action: ${action.actionName}, Data: ${action.data}");
});
```

#### Action Names

| Action Name | Description |
|-------------|-------------|
| `onCallStateChanged` | Call state has changed |
| `onSwitchboardAnswer` | Switchboard SIP is listening |

#### Call States

| State | Code | Description |
|-------|------|-------------|
| `unknown` | 0 | Unknown state |
| `calling` | 1 | Outgoing call initiated |
| `incoming` | 2 | Incoming call |
| `early` | 3 | Ringing |
| `connecting` | 4 | Connecting |
| `confirmed` | 5 | Active call |
| `disconnected` | 6 | Call ended |
| `hold` | 7 | Call on hold |

#### Event Data (onCallStateChanged)

```dart
{
  "isVideo": bool,          // true for video call
  "status": int,            // call state code (0-7)
  "callerNumber": String,   // phone number
  "incoming": bool,         // true if incoming
  "_id": String,            // (optional) call identifier
  // Only present when status == disconnected (6):
  "code_end_call": int,     // SIP/OMI end reason code — see Call End Codes table
}
```

#### State Lifecycle

**Outgoing Call:**
```
CALLING (1) → EARLY (3) → CONNECTING (4) → CONFIRMED (5) → DISCONNECTED (6)
```

**Incoming Call:**
```
INCOMING (2) → CONNECTING (4) → CONFIRMED (5) → DISCONNECTED (6)
```

---

### 📌 Other Event Listeners

#### Call Quality Listener (Recommended: Use CallQualityTracker)

```dart
OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);

  // Use parsed info
  print(info.mosDisplay);      // "4.5"
  print(info.qualityText);     // "Excellent"
  print(info.shouldShowLoading); // true/false
});
```

**Raw data format (if not using helper):**
```dart
{
  "quality": int,        // 0: GOOD, 1: NORMAL, 2: BAD
  "stat": {
    "req": double,       // Request time
    "mos": double,       // MOS score (1.0-5.0)
    "jitter": double,    // Jitter (ms)
    "latency": double,   // Latency (ms)
    "ppl": double,       // Packet loss (%)
    "lcn": int          // Loss connect count
  },
  "isNeedLoading": bool  // (Deprecated: Use CallQualityTracker instead)
}
```

#### Speaker Listener

```dart
OmicallClient.instance.setSpeakerListener((isSpeakerOn) {
  setState(() {
    isSpeaker = isSpeakerOn;
  });
});
```

#### Mute Listener

```dart
OmicallClient.instance.setMuteListener((isMuted) {
  setState(() {
    this.isMuted = isMuted;
  });
});
```

#### Hold Listener

```dart
OmicallClient.instance.setHoldListener((isOnHold) {
  setState(() {
    this.isHold = isOnHold;
  });
});
```

#### Remote Video Ready Listener

```dart
OmicallClient.instance.setVideoListener((data) {
  refreshRemoteCamera(); // Refresh remote camera view
  refreshLocalCamera();  // Refresh local camera view
});
```

#### Missed Call Listener

Triggered when user taps missed call notification:

```dart
OmicallClient.instance.setMissedCallListener((data) {
  final String callerNumber = data["callerNumber"];
  final bool isVideo = data["isVideo"];
  makeCallWithParams(context, callerNumber, isVideo);
});
```

#### Call Log Listener (iOS Only)

Triggered when user taps call log entry:

```dart
OmicallClient.instance.setCallLogListener((data) {
  final String callerNumber = data["callerNumber"];
  final bool isVideo = data["isVideo"];
  makeCallWithParams(context, callerNumber, isVideo);
});
```

---

## Error Codes

### Call End Codes (`code_end_call`)

The `code_end_call` field is included in the event data when `status == disconnected (6)`. It indicates why the call ended.

#### How to handle end-call reasons

```dart
OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
  if (omiAction.actionName != OmiEventList.onCallStateChanged) return;
  final data = omiAction.data;
  final status = data['status'] as int;

  if (status == OmiCallState.disconnected.rawValue) {
    final code = data['code_end_call'] as int?;
    final reason = _endCallReason(code);
    if (reason != null) {
      // Show toast or dialog to user
      showToast(reason);
    }
  }
});

String? _endCallReason(int? code) {
  switch (code) {
    case null:
    case 0:
    case 200:  // Normal BYE — both sides hung up
    case 487:  // Caller cancelled before answer
      return null;
    case 408: return 'No answer. The call was not answered.';
    case 480: return 'Callee is temporarily unavailable.';
    case 486: return 'Line busy. Please try again later.';
    case 503: return 'Service unavailable.';
    default:  return 'Call ended (code: $code).';
  }
}
```

#### Standard OMISIP Codes

| Code | Meaning | Action for user |
|------|---------|-----------------|
| `200` | Normal call end (BYE) | No toast needed |
| `403` | Forbidden — service plan restricts this number | Upgrade service plan |
| `404` | Number not found or not allowed to call carrier | Check number |
| `408` | Request timeout — callee did not answer | Notify: no answer |
| `480` | Temporarily unavailable — callee offline/busy | Notify: unavailable |
| `486` | Busy here — callee rejected / busy | Notify: line busy |
| `487` | Request terminated — caller cancelled | No toast needed |
| `503` | Service unavailable | Notify: service error |
| `601` | Call ended by customer |
| `602` | Call ended by another employee |
| `603` | Call rejected — check account limit or call barring |
| `850` | Simultaneous call limit exceeded |
| `851` | Call duration limit exceeded |
| `852` | Service package not assigned |
| `853` | Internal number disabled |
| `854` | Subscriber in DNC (Do Not Call) list |
| `855` | Exceeded allowed calls for trial package |
| `856` | Exceeded allowed minutes for trial package |
| `857` | Subscriber blocked in configuration |
| `858` | Unidentified or unconfigured number |
| `859` | No available numbers for Viettel direction |
| `860` | No available numbers for VinaPhone direction |
| `861` | No available numbers for Mobifone direction |
| `862` | Temporary block on Viettel direction |
| `863` | Temporary block on VinaPhone direction |
| `864` | Temporary block on Mobifone direction |
| `865` | Advertising number outside permitted calling hours |

---

## Troubleshooting

### Common Issues

#### 1. Call Not Starting (startCall returns error)

**Symptom:** `startCall()` returns status other than 8

**Solutions:**

```dart
// Check result and handle errors
final result = await OmicallClient.instance.startCall(phone, false);
final jsonMap = json.decode(result);
final status = jsonMap['status'];

// Use 'message' field for cross-platform handling (status code differs between Android/iOS)
final message = jsonMap['message'];

switch(message) {
  case 'START_CALL_SUCCESS':
    navigateToCallScreen();
    break;
  case 'NO_NETWORK':
    // Android: status=408 / iOS: status=11
    print("No network connection - check internet");
    showNoNetworkDialog();
    break;
  case 'PERMISSION_DENIED':
    print("Microphone permission denied");
    await requestMicrophonePermission();
    break;
  case 'COULD_NOT_FIND_END_POINT':
    print("Not logged in - call initCall() first");
    break;
  case 'HAVE_ANOTHER_CALL':
    print("Already in a call");
    break;
  case 'SWITCHBOARD_NOT_CONNECTED':
    print("Switchboard not connected - check account");
    break;
  case 'SWITCHBOARD_REGISTERING':
    // status=8 on Android, call is being registered
    navigateToCallScreen();
    break;
  case 'ACCOUNT_TURN_OFF_NUMBER_INTERNAL':
    print("Internal call feature is disabled for this account");
    break;
}
```

#### 2. No Incoming Call Notification

**Android:**
- ✅ Check `google-services.json` exists in `android/app/`
- ✅ Verify FCM token is registered: `OmicallClient.instance.initCall(..., fcmToken: token)`
- ✅ Check `AndroidManifest.xml` has `FirebaseMessageReceiver`
- ✅ Ensure app has notification permissions

**iOS:**
- ✅ Check APNS certificate is configured on Firebase
- ✅ Verify APNS token: `FirebaseMessaging.instance.getAPNSToken()`
- ✅ Check `PushKitManager` is initialized in `AppDelegate`
- ✅ Verify VoIP push certificate in Apple Developer Portal

#### 3. Call Quality Issues (Low MOS Score)

**Symptom:** MOS < 3.0 or frequent loading indicators

**Debugging:**

```dart
OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);

  print("MOS: ${info.mos}");           // Target: ≥ 4.0
  print("Jitter: ${info.jitter}ms");   // Target: < 30ms
  print("Latency: ${info.latency}ms"); // Target: < 150ms
  print("Packet Loss: ${info.packetLoss}%"); // Target: < 1%
  print("LCN: ${info.lcn}");           // Target: 0 or changing

  if (info.mos < 3.0) {
    // Poor call quality detected
    if (info.jitter > 50) {
      print("High jitter - check network stability");
    }
    if (info.latency > 200) {
      print("High latency - check internet speed");
    }
    if (info.packetLoss > 3) {
      print("Packet loss - check WiFi signal");
    }
  }

  if (info.shouldShowLoading) {
    print("Network stuck - LCN frozen at ${info.lcn}");
  }
});
```

**Solutions:**
- Switch from WiFi to cellular or vice versa
- Close bandwidth-heavy apps
- Move closer to WiFi router
- Check internet speed (minimum 100kbps recommended)

#### 4. Video Call Issues

**No Remote Video:**
```dart
// Register video event listener
OmicallClient.instance.setVideoListener((data) {
  // Refresh camera views when remote video ready
  _remoteController?.refresh();
  _localController?.refresh();
});
```

**Camera Not Switching:**
```dart
// Ensure camera is created before switching
if (_localController != null) {
  OmicallClient.instance.switchCamera();
}
```

**Black Screen:**
- ✅ Check camera permissions
- ✅ Ensure `isVideo: true` in `initCall()` and `startCall()`
- ✅ Call `registerVideoEvent()` before call starts
- ✅ Refresh camera views when state changes

#### 5. Audio Issues

**No Audio During Call:**
```dart
// Check if muted
OmicallClient.instance.setMuteListener((isMuted) {
  if (isMuted) {
    OmicallClient.instance.toggleAudio(); // Unmute
  }
});

// Check speaker status
OmicallClient.instance.setSpeakerListener((isSpeakerOn) {
  print("Speaker: $isSpeakerOn");
});
```

**Echo or Feedback:**
- Use headphones/earphones
- Enable speaker phone
- Check microphone sensitivity

---

## Migration Guide

### Upgrading from 2.x.x to 3.x.x

#### Breaking Changes

1. **getInstance() Removed**

❌ **Old Code:**
```dart
OmicallClient.getInstance(context).startCall(phone, false);
```

✅ **New Code:**
```dart
OmicallClient.instance.startCall(phone, false);
```

2. **Call Quality Monitoring**

❌ **Old Code (Manual Parsing):**
```dart
OmicallClient.instance.setCallQualityListener((data) {
  final quality = data["quality"] as int;
  final stat = data["stat"] as Map<String, dynamic>;
  final lcn = stat["lcn"] as int? ?? 0;
  final mos = stat["mos"] as double? ?? 0.0;

  // Manual LCN tracking
  if (lcn == lastLcn && lcn != 0) {
    consecutiveCount++;
    if (consecutiveCount >= 3) {
      showLoading();
    }
  }
});
```

✅ **New Code (Using Helper):**
```dart
final _qualityTracker = CallQualityTracker();

OmicallClient.instance.setCallQualityListener((data) {
  final info = _qualityTracker.parseCallQuality(data);

  if (info.shouldShowLoading) {
    EasyLoading.show();
  } else if (info.isNetworkRecovered) {
    EasyLoading.dismiss();
  }

  setState(() {
    callQuality = info.mosDisplay; // "4.5"
  });
});
```

3. **Package Name Changes**

Update imports if you were using internal classes:

❌ **Old:**
```dart
import 'package:omicall_flutter_plugin/some_internal_class.dart';
```

✅ **New:**
```dart
import 'package:omicall_flutter_plugin/omicall.dart';
import 'package:omicall_flutter_plugin/models/call_quality_info.dart';
import 'package:omicall_flutter_plugin/utils/call_quality_tracker.dart';
```

#### New Features in 3.x.x

1. **CallQualityTracker Helper**
   - Automatic MOS parsing
   - Built-in LCN tracking
   - Network recovery detection
   - See [Call Quality Monitoring](#-call-quality-monitoring-new)

2. **Enhanced Error Handling**
   - Better error messages in `startCall()`
   - Detailed error codes
   - See [Error Codes](#error-codes)

3. **Improved Documentation**
   - ASCII architecture diagrams
   - Call flow lifecycle charts
   - Comprehensive troubleshooting

---

## Support

- 📧 Email: contact@omicall.com
- 📱 Hotline: 0272 7777 787
- 🌐 Website: https://omicall.com
- 📖 API Docs: https://omicrm.io/post/detail/omicall-apis-post76

---

## License

Copyright © 2021 VIHAT Team. All rights reserved.
