# Changelog

All notable changes to this project will be documented in this file.

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

