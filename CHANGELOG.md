# Changelog

All notable changes to this project will be documented in this file.

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

