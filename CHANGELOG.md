@omicall_flutter_plugin

All notable changes to this project will be documented in this file.

## 3.3.2 [05/03/2026]

### Changed
- **[MAJOR]** Updated OMI Android SDK: `2.3.22-v2` → `2.6.4`
- **[MAJOR]** Updated OmiKit iOS: `1.8.44` → `1.10.34`
- **[MAJOR]** Maven repository changed: `vn.vihat.omicall:omi-sdk` → `io.omicrm.vihat:omi-sdk`
- **[MAJOR]** Support Google 16 KB page size policy.
- Upgraded Kotlin: `1.6.10` → `1.9.24`
- Upgraded Android Gradle Plugin: `7.1.2` → `8.1.4`
- Upgraded compileSdk and targetSdk: `33` → `35` (Android 15 support)
- Upgraded Java compatibility: `1.8` → `11`
- Added support for Android 15-16 ConnectionService for incoming calls
- Removed deprecated `jcenter()` repository
- `OmiClient.getInstance(context)` → `OmiClient.getInstance(context, needRegister)`

### Added
- **Network error surfacing for `initCall*` methods**: Both `initCallWithUserPassword` and `initCallWithApiKey` now perform a network check before attempting SDK registration. Returns `NETWORK_UNAVAILABLE` if no connectivity.
- **Descriptive init result**: `initCallWithUserPassword` / `initCallWithApiKey` now return a JSON string `{"status": Int, "message": String}` instead of `Bool`, letting integrators know exactly why initialization failed.
- **`OmiStartCallStatus` enum** — added two new values:
  - `noNetwork` (Android: `status=408`, iOS: `status=11`) — no network when starting a call
  - `accountTurnOffNumberInternal` (iOS: `status=10`) — internal call disabled for this account
- **`startCall()` message mapping** — added `NO_NETWORK` and `ACCOUNT_TURN_OFF_NUMBER_INTERNAL` to both Android and iOS `messageCall()` helpers
- **Call Quality Monitoring**: `CallQualityTracker` and `CallQualityInfo` helper classes for parsing call quality data (MOS, LCN, jitter, latency, packet loss)
- **Android 14+ Permissions** (API 34+):
  - `FOREGROUND_SERVICE_MICROPHONE` - Required for audio calls
  - `FOREGROUND_SERVICE_PHONE_CALL` - Required for call functionality
- **Android 13+ Permissions** (API 33+):
  - `POST_NOTIFICATIONS` - Required for call notifications
- **Android 15-16 Support**:
  - `MANAGE_OWN_CALLS` - Required for ConnectionService
- `NotificationService` with `foregroundServiceType="microphone|phoneCall"`
- `FirebaseMessageReceiver` with `foregroundServiceType="remoteMessaging"`
- `<uses-feature android:name="android.hardware.telephony" android:required="false" />`

### Fixed
- **[CRITICAL]** Explicitly removed `FOREGROUND_SERVICE_CAMERA` permission (crashes on Android 14-15 devices without camera)
- **[CRITICAL]** Removed KAPT plugin and `kapt "com.github.bumptech.glide:compiler"` (caused OutOfMemoryError, KSP conflicts)
- Fixed type casting bug in call quality listener (`Map<String, dynamic>` → `Map<dynamic, dynamic>`) that caused crash on iOS
- Fixed DNS network issues (Android SDK 2.5.15-2.5.17)
- Fixed crash on Firebase message received (Android SDK 2.5.11)
- Fixed crash on `startForeground` (Android SDK 2.5.11)
- Fixed race condition when logout & login (Android SDK 2.5.9)
- Fixed ANR register timeout for MIUI on Xiaomi devices (Android SDK 2.5.7)
- Improved video call stability (Android SDK 2.5.11)
- Hardcoded GitHub token removed from example `build.gradle.kts` (now reads from `local.properties`)

### Breaking Changes
- **`initCallWithUserPassword` / `initCallWithApiKey` return type changed**: `Future<bool>` → `Future<dynamic>` (JSON string). Code checking `result == true/false` must be updated — see migration guide Step 9.
- **Maven repository changed**: `vn.vihat.omicall:omi-sdk` → `io.omicrm.vihat:omi-sdk`
- **Permission updates required**: Must add `FOREGROUND_SERVICE_MICROPHONE` + `FOREGROUND_SERVICE_PHONE_CALL` permissions
- **Camera permission must be removed**: `<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" tools:node="remove" />`
- **Service declaration updated**: `NotificationService` requires `android:foregroundServiceType="microphone|phoneCall"`
- **`OmiClient.getInstance()` signature changed**: Now requires `needRegister` parameter

### Dependencies
| Package | 3.2.4 | 3.3.2 |
|---------|-------|-------|
| Android OMI SDK | 2.3.22-v2 | 2.6.4 |
| iOS OmiKit | 1.8.44 | 1.10.34 |
| Kotlin | 1.6.10 | 1.9.24 |
| AGP | 7.1.2 | 8.1.4 |
| compileSdk / targetSdk | 33 | 35 |
| Java | 1.8 | 11 |
| OkHttp | 5.0.0-alpha.11 | 4.12.0 |
| Kotlin Coroutines | 1.7.2 | 1.8.1 |
| Firebase Messaging | 23.2.1 | 24.1.0 |
| Material Design | 1.9.0 | 1.12.0 |
| Retrofit | 2.9.0 | 2.11.0 |
| Gson | 2.10.1 | 2.11.0 |
| Glide | 4.15.1 | 4.16.0 |
| AppCompat | 1.6.1 | 1.7.0 |
| Lifecycle Process | 2.6.2 | 2.8.7 |
| Work Runtime | 2.8.1 | 2.9.0 |
| Hilt | 2.39.1 | 2.48 |


## 3.2.4 [24/07/2025]
- Update OMI core Android to version 2.3.22-v2
- Remove FOREGROUND_SERVICE_TYPE_DATA_SYNC at androidManifest

- Update OMI core iOS to version 1.8.44
- Improve quality call iOS 


## 3.2.3
- Update OMI core iOS to version 1.8.11
  

## 3.2.2
- Update OMI core iOS to version 1.8.9
- Update OMI core Android to version 2.3.22
- Fix Audio Call iOS
- Update codec

## 3.2.1
- Update readme 
- Add func transfer call 

## 3.2.0
- Pump OMI core IOS to version 1.8.5
- Pump OMI core Android to version 2.3.19
- Add func Hold call 

## 3.1.39, 3.1.40
- Change repo maven

## 3.1.38
- Pump OMI core IOS to version 1.7.25
- Fix missed omi_id off incoming call ios

## 3.1.37
- Pump OMI core Android version 2.2.83
- Remove permission in AndroidManifest

## 3.1.36
- Pump OMI core Android version 2.2.82
- Pump OMI core IOS to version 1.7.23
- Improve quality call
- Improve FCM call for android

## 3.1.35
- Pump OMI core IOS to version 1.7.18
- Fix callkit bug when forwarding multiple times back to self

## 3.1.34
- Pump OMI core Android version 2.2.34
- Fix bug crash android

## 3.1.33
- Pump OMI core Android version 2.2.24
- Fix bug crash android

## 3.1.32
- Pump OMI core Android version 2.2.24
- Fix bug crash android


## 3.1.31
- Pump OMI core Android version 2.2.23
- Fix bug crash android

## 3.1.30
- Pump OMI core Android version 2.2.22 
- Fix bug crash android

## 3.1.29
- Pump OMI core IOS version 1.6.57

## 3.1.28
- Pump OMI core IOS version 1.6.56



## 3.1.27
- Pump OMI core Android version 2.2.18
- Pump OMI core IOS version 1.6.55
- Thêm params vào api lưu thông tin cuộc gọi

## 3.1.26
- Pump OMI core Android version 2.2.12
- Fix lỗi crash android 

## 3.1.25
- Pump OMI core IOS version 1.6.54
- Fix lỗi logIn với API KEY fail trên ios

## 3.1.24
- Pump OMI core android version 2.2.11
- Add field isUseIntentFilter cho option có sử dụng intent Filter của Omi hay không

## 3.1.23
- Pump OMI core android version 2.2.10
- Pump OMI core IOS version 1.6.51
- Fix crash SDK 
- Change params request off API
- Add func clear All Call when kill app in ios. 

## 3.1.22
- Pump OMI core android version 2.2.0
- Fix lỗi show popup cuộc gọi nhỡ trong android.

## 3.1.21
- Pump OMI core android version 2.1.86
- Fix lỗi leak memory cho các cuộc gọi dài trên android.
- Cập nhật flow nhận cuộc gọi trong android. 

## 3.1.20
- Pump OMI core ios version 1.6.45
- Pump OMI core android version 2.1.81

## 3.1.19
- Pump OMI core ios version 1.6.44
- Added option to show business name in CallKit
- Pump OMI core android version 2.1.73
- Add event networking for ios. 

## 3.1.18
- Pump OMI core ios version 1.6.43
- Fix URL get info call ios
- Fix add networking event

## 3.1.17
- Pump OMI core ios version 1.6.42
- Update OMI core android to version 2.1.56


## 3.1.16
- Update tag

## 3.1.15
- Pump core ios version 1.6.40. 
- Fix incorrect display of prefixes on the web.
- Fix params API add MOS of IOS

## 3.1.14
- Fix convert sendDtmf data to string

## 3.1.13
- Commit file missed

## 3.1.12
- Update OMI core android to version 2.1.51
- Save data in SharedPreferences when initializing EncryptedSharedPreferences fails.


## 3.1.11
- Update OMI core android to version 2.1.48
- Remove Throw RuntimeException off PrefManager.


## 3.1.9
- Update OMI core android to version 2.1.39
- Remove flag excludeFromRecents , taskAffinity in AndroidMainifest.
- Fix notification error when calling and shutting down the application.


## 3.1.8
- Update core android to version 2.1.27
- Update ios to version 1.6.34
- Remove feature Foreground Service off Android
- Update audio and call quality off Android.
- Fix crash error related to NAT in iOS


## 3.1.7
- Pump core ios version 1.6.23
- Tối ưu hiệu suất âm thanh cuộc gọi ở iOS.
- Tối ưu khả năng kết nối ở IOS.
- Fix lỗi crash về networking ở các dòng iPhone: 7 Plus (iOS 15.7.6), 6s(iOS 15.6.0), 8 Plus (iOS 15.7.6)

## 3.1.6
- Remove lib voismart (android)
- Cấu hình rung android.
- Fix âm thanh android.
- Fix connect iOS
- Pump core android version 2.0.87
- Pump core ios version 1.6.18

## 3.1.5
- Update README
- Pump core android version 2.0.75
- Pump core ios version 1.6.10

## 3.1.4
- Update README
- Pump core android version 2.0.73
- Pump core ios version 1.6.8
- Fix bug sound in android


## 3.1.2
- Update README, 
- Remove function updateToken,
- Add params Token when innit account.

## 3.1.1

- Increase ios core to version 1.6.4
- Increase ios android to version 2.0.52

## 3.1.0

- Increase ios core to version 1.5.98
- Increase ios android to version 2.0.43
- Fix Call UDP IOS
- Fix call UDP Android
- Fix continuous calling error on iOS

## 3.0.26
- Increase ios core
- Increase ios android

## 3.0.25
- Increase ios core


## 3.0.24
- Increase android core
- Update params off function initCallWithUserPassword, initCallWithApiKey

## 3.0.23
- Increase android core

## 3.0.22

- Increase android core


## 3.0.21

- Fix Status accept call 


## 3.0.20

- Fix Status call android 

## 3.0.19

- Fix Click Notification Call 


## 3.0.18

- Fix Status call android 

## 3.0.17

- Fix Status call android 

## 3.0.16

- Fix Status call android 

## 3.0.15

- Increase ios core
- Increase android core
- Fix open app from Notification



- Increase ios core
- Increase android core

## 3.0.13

- Increase android core


## 3.0.12
- Fix status call in android 
- Increase android core
- Update Readme 

## 3.0.11
- Fix status call in android 
## 3.0.10
- Increase android core
- Fix status call 

## 3.0.9
- Increase android core
- Remove request permission when innit user in ios 

## 3.0.8
- Increase android core

## 3.0.7
-  Increase android core

## 3.0.6
- Optimal make call in ios  


## 3.0.5
- Fix issues call 503 in ios 


## 3.0.4
- Format data android/ios

## 3.0.3
- Add information when end call in ios


## 3.0.2
- Increase ios core
- Add more field for android/ios 

## 3.0.1
  - Add more info call when end call in ios  



## 3.0.0
  - Increase android core
  - Hot fix flow android / ios 

## 2.9.9
- Increase ios core
- Add call info when start call, callStateChanged 
## 2.9.8
  - Increase ios core

## 2.9.7
  - Increase android core
  - Update sample

## 2.9.6
  - Increase core
  - Allow to custom call description
  - Allow to custom callkit icon
  - Update sample

## 2.9.5
  - Increase 1.5.63 version for iOS core

## 2.9.4
  - Increase iOS core

## 2.9.3
  - Increase Android core

## 2.9.2
  - Increase iOS core

## 2.9.1
  - Support kotlin 1.6.10

## 2.9.0
  - Increase android/iOS core
  - Support to listen audio change, get current audio
  - Optimize call function

## 2.8.3+2
  - Increase android core
  - Fix endTime for android
  - Update sample

## 2.8.3+1
  - Increase android core
  - Fix sendDTMF code for android
  - Update sample

## 2.8.3
  - Increase android core
  - Update sample

## 2.8.2
  - Increase ios core
  - Improve `getCurrentUser` function
  - Remove logs
  - Update sample

## 2.8.1
  - Increase android core
  - Update document

## 2.8.0
- **BREAKING CHANGE**
  - We only use stream for `callStateChange` event, we replace stream to callback for another events
  - Support click callLog on iOS (`setCallLogListener`)
  - Increase ios/android core
  - We add more `haveAnotherCall` on `startCall`
  - Update sample

## 2.7.3
  - Increase ios/android core
  - We return error code on `startCall`
  - Update sample and readme

## 2.7.2
  - Increase ios/android core
  - Improve `startCall` performance

## 2.7.1
  - Increase ios core
  - Improve startCall function
  - Update readme

## 2.7.0
- **BREAKING CHANGE**
  - Increase android/ios core
  - Support Swift document
  - Support to return `outgoing`, `ringing`, `connecting`, `calling` status
  - Fix null point on release mode Android
  - Improve performance
  - Update sample

## 2.6.6
  - Increase android/ios core
  - Support to get call quality
  - Update sample

## 2.6.5
  - Increase android core
  - Kill all services when user logout
  - Support to change channel id in the call notification
  - Update sample

## 2.6.4
  - Increase android core
  - Fix null phone number in missing call
  - Support to change network on Android

## 2.6.3
   - Increase android core
   - Improve background and kill app state on Android

## 2.6.2
  - Increase android/ios core
  - Fix return true when login have some error on iOS.
  - Support custom title on notification and show user avatar.
  - Update sample

## 2.6.1
  - Increase android core
  - Improve set camera for Android
  - Support dart 3.0.0
  - Update sample

## 2.6.0
  - Increase android/iOS core
  - Support to receive switchboard
  - Update sample

## 2.5.4
  - Increase android core
  - Change requests: allow to set images for the incoming notification.

## 2.5.3
  - Increase android core
  - Fix bug: Local video is not showing.

## 2.5.2
  - Increase android/ ios core
  - Support to change notification icon on Android
  - Update sample

## 2.5.1
  - Increase android core
  - Fix incoming notification activity show empty screen, correct sip number in established call.

## 2.5.0
- **BREAKING CHANGE**
  - We return call information after the call ending.
  - Add `getCurrentUser`, `getGuestUser` and `getUserInfo` to get user information.
  - Update sample.

## 2.4.2
  - Check microphone when user `startCall`
  - Update sample and document

## 2.4.1
  - Return `transactionId` in `establisedCall` listener
  - Update sample and document

## 2.4.0
- **BREAKING CHANGE**
  - We replace `FMService` to `FirebaseMessageReceiver`
  - Increase iOS/Android core
  - Update video widget for iOS
  - Update sample

## 2.3.2
  - Fix keep alive state speaker and mute

## 2.3.0
- **BREAKING CHANGE**
  - We replace camera event to video event. 
  - Add `registerVideoEvent` and `removeVideoEvent` to register video event.
  - Support the missed call
  - We add more input in `configPushNotification`
  - Increase Android/iOS core version
  - Update sample

## 2.2.4
  - Increase Android/iOS core version
  - Add `logout` function
  - Remove appId and deviceId in `updateToken`
  - Update sample

## 2.2.3
  - Increase Android core version
  - Add initial call for iOS
  - Update sample

## 2.2.2
  - Increase Android core version
  - Update sample

## 2.2.1
- **BREAKING CHANGE**
  - We support call with uuid `Omiclient.instance.startCallWithUUID`
  - Increase Android core version (fix crash on some devices)
  - Update sample

## 2.1.0
- **BREAKING CHANGE**
  - We support config notification `Omiclient.instance.configPushNotification`, But it doesn't support on iOS
  - Increase Android core version
  - Update sample

## 2.0.2
- Fix crash on release mode: login and update notification for Android
- Increase core version
- Add `startServices` function

## 2.0.1
- Support API for SDK
- Increase core version
- Update documents

## 2.0.0
- Support App - to - App
- Support Video Call
- Improve performance and logic

## 1.0.12

- Support iOS 11,12
- Support minSDK from 21.

## 1.0.11

- Add more event list
- Refactor code


## 1.0.10

* Improve for iOS

