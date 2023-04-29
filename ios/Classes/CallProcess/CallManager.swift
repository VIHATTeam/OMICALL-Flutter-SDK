//
//  CallUtils.swift
//  OMICall Contact Center
//
//  Created by Tuan on 22/03/2022.
//

import Foundation
import AVFoundation
import MediaPlayer
import SwiftUI
import AVFoundation
import OmiKit

class CallManager {
    
    static private var instance: CallManager? = nil // Instance
    private let omiLib = OMISIPLib.sharedInstance()
    var videoManager: OMIVideoViewManager?
    var isSpeaker = false
    private var guestPhone : String = ""
    
    /// Get instance
    static func shareInstance() -> CallManager {
        if (instance == nil) {
            instance = CallManager()
        }
        return instance!
    }
    
    func getAvailableCall() -> OMICall? {
        var currentCall = omiLib.getCurrentConfirmCall()
        if (currentCall == nil) {
            currentCall = omiLib.getNewestCall()
        }
        return currentCall
    }
    
    func updateToken(params: [String: Any]) {
        if let apnsToken = params["apnsToken"] as? String {
            OmiClient.setUserPushNotificationToken(apnsToken)
        }
    }
    
    func configNotification(data: [String: Any]) {
        if let title = data["missedCallTitle"] as? String, let message = data["prefixMissedCallMessage"] as? String {
            let user = UserDefaults.standard
            user.set(title, forKey: "missedCallTitle")
            user.set(message, forKey: "prefixMissedCallMessage")
        }
    }
    
    private func requestPermission(isVideo: Bool) {
        AVCaptureDevice.requestAccess(for: .audio) { _ in
            print("request audio")
        }
        if isVideo {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                print("request video")
            }
        }
    }
    
    func initWithApiKeyEndpoint(params: [String: Any]) -> Bool {
        //request permission
        var result = true
        if let usrUuid = params["usrUuid"] as? String, let fullName = params["fullName"] as? String, let apiKey = params["apiKey"] as? String {
            result = OmiClient.initWithUUID(usrUuid, fullName: fullName, apiKey: apiKey)
        }
        let isVideo = (params["isVideo"] as? Bool) ?? true
        requestPermission(isVideo: isVideo)
        return result
    }
    
    func initWithUserPasswordEndpoint(params: [String: Any]) -> Bool {
        if let userName = params["userName"] as? String, let password = params["password"] as? String, let realm = params["realm"] as? String, let host = params["host"] as? String {
            OmiClient.initWithUsername(userName, password: password, realm: realm)
        }
        let isVideo = (params["isVideo"] as? Bool) ?? true
        requestPermission(isVideo: isVideo)
        return true
    }
    
    func showMissedCall() {
        OmiClient.setMissedCall { call in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                switch settings.authorizationStatus {
                    case .notDetermined:
                       break
                    case .authorized, .provisional:
                        let user = UserDefaults.standard
                        let title = user.string(forKey: "missedCallTitle") ?? ""
                        let message = user.string(forKey: "prefixMissedCallMessage") ?? ""
                        let content      = UNMutableNotificationContent()
                        content.title    = title
                        content.body = "\(message) \(call.callerNumber!)"
                        content.sound    = .default
                        content.userInfo = [
                            "callerNumber": call.callerNumber,
                            "isVideo": call.isVideo,
                        ]
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                        //getting the notification request
                        let id = Int.random(in: 0..<10000000)
                        let request = UNNotificationRequest(identifier: "\(id)", content: content, trigger: trigger)
                        //adding the notification to notification center
                        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                    default:
                        break // Do nothing
                }
            }
        }
    }
    
    func registerNotificationCenter() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.removeObserver(CallManager.instance!)
            NotificationCenter.default.addObserver(CallManager.instance!,
                                                   selector: #selector(self.callStateChanged(_:)),
                                                   name: NSNotification.Name.OMICallStateChanged,
                                                   object: nil
            )
            NotificationCenter.default.addObserver(CallManager.instance!,
                                                   selector: #selector(self.callDealloc(_:)),
                                                   name: NSNotification.Name.OMICallDealloc,
                                                   object: nil
            )
            self.showMissedCall()
        }
    }
    
    func registerVideoEvent() {
        DispatchQueue.main.async {
            NotificationCenter.default.addObserver(CallManager.instance!,
                                                   selector: #selector(self.videoUpdate(_:)),
                                                   name: NSNotification.Name.OMICallVideoInfo,
                                                   object: nil
            )
        }
    }
    
    @objc func videoUpdate(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let state     = userInfo[OMIVideoInfoState] as? Int else {
            return;
        }
        switch (state) {
        case 0:
            SwiftOmikitPlugin.instance?.sendEvent(LOCAL_VIDEO_READY, [:])
            break
        case 1:
            SwiftOmikitPlugin.instance?.sendEvent(REMOTE_VIDEO_READY, [:])
            break
        default:
            break
        }
    }
    
    func removeVideoEvent() {
        DispatchQueue.main.async {
            NotificationCenter.default.removeObserver(CallManager.instance!, name: NSNotification.Name.OMICallVideoInfo, object: nil)
        }
    }
    
    @objc func callDealloc(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let call     = userInfo[OMINotificationUserInfoCallKey] as? OMICall else {
            return;
        }
        if (call.callState == .disconnected) {
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                if (self.videoManager != nil) {
                    self.videoManager = nil
                }
                self.guestPhone = ""
                SwiftOmikitPlugin.instance?.sendEvent(CALL_END, [:])
            }
        }
    }
    
    @objc fileprivate func callStateChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let call     = userInfo[OMINotificationUserInfoCallKey] as? OMICall else {
            return;
        }
        print("call state")
        print(call.callState)
        switch (call.callState) {
        case .calling:
            if (!call.isIncoming) {
                NSLog("Outgoing call, in CALLING state, with UUID \(call.uuid)")
                //                SwiftOmikitPlugin.instance?.sendEvent(onRinging, [:])
            }
            break
        case .early:
            if (!call.isIncoming) {
                NSLog("Outgoing call, in EARLY state, with UUID: \(call.uuid)")
            }
            break
        case .connecting:
            if (!call.isIncoming) {
                NSLog("Outgoing call, in CONNECTING state, with UUID: \(call.uuid)")
            }
            break
        case .confirmed:
            NSLog("Outgoing call, in CONFIRMED state, with UUID: \(call)")
            if (videoManager == nil && call.isVideo) {
                videoManager = OMIVideoViewManager.init()
            }
            isSpeaker = call.isVideo
            SwiftOmikitPlugin.instance?.sendEvent(CALL_ESTABLISHED, ["isVideo": call.isVideo, "callerNumber": call.callerNumber, "transactionId": call.omiId])
            SwiftOmikitPlugin.instance.sendMuteStatus()
            break
        case .disconnected:
            if (!call.connected) {
                NSLog("Call never connected, in DISCONNECTED state, with UUID: \(call.uuid)")
            } else if (!call.userDidHangUp) {
                NSLog("Call remotly ended, in DISCONNECTED state, with UUID: \(call.uuid)")
            }
            print(call.uuid.uuidString)
            if (videoManager != nil) {
                videoManager = nil
            }
            guestPhone = ""
            SwiftOmikitPlugin.instance?.sendEvent(CALL_END, [:])
            break
        case .incoming:
            guestPhone = call.callerNumber ?? ""
            DispatchQueue.main.async {
                let state: UIApplication.State = UIApplication.shared.applicationState
                if (state == .active) {
                    SwiftOmikitPlugin.instance?.sendEvent(INCOMING_RECEIVED, ["isVideo": call.isVideo, "callerNumber": call.callerNumber ?? ""])
                }
            }
            break
        default:
            NSLog("Default call state")
            break
        }
    }
    
    /// Start call
    func startCall(_ phoneNumber: String, isVideo: Bool) -> Bool {
        guestPhone = phoneNumber
        //check permission
        let auth = AVAudioSession.sharedInstance().recordPermission
        if (auth == .granted) {
            if (isVideo) {
                return OmiClient.startVideoCall(phoneNumber)
            }
            return OmiClient.startCall(phoneNumber)
        }
        return false
    }
    
    /// Start call
    func startCallWithUuid(_ uuid: String, isVideo: Bool) -> Bool {
        let auth = AVAudioSession.sharedInstance().recordPermission
        if (auth == .granted) {
            let phoneNumber = OmiClient.getPhone(uuid)
            if let phone = phoneNumber {
                guestPhone = phoneNumber ?? ""
                if (isVideo) {
                    return OmiClient.startVideoCall(phone)
                }
                return OmiClient.startCall(phone)
            }
        }
        return false
    }
    
    func endAvailableCall() {
        guard let call = getAvailableCall() else {
            SwiftOmikitPlugin.instance?.sendEvent(CALL_END, [:])
            return
        }
        omiLib.callManager.end(call)
    }
    
    
    func endAllCalls() {
        omiLib.callManager.endAllCalls()
    }
    
    func joinCall() {
        guard let call = getAvailableCall() else {
            return
        }
        OmiClient.answerIncommingCall(call.uuid)
    }
    
    func sendDTMF(character: String) {
        guard let call = getAvailableCall() else {
            return
        }
        try? call.sendDTMF(character)
    }
    
    /// Toogle mtue
    func toggleMute() {
        guard let call = getAvailableCall() else {
            return
        }
        try? call.toggleMute()
    }
    
    /// Toogle hold
    func toggleHold() {
        guard let call = getAvailableCall() else {
            return
        }
        try? call.toggleHold()
    }
    
    /// Toogle speaker
    func toogleSpeaker() {
        if !isSpeaker {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } else {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        }
        isSpeaker = !isSpeaker
        SwiftOmikitPlugin.instance.sendSpeakerStatus()
    }
    
    
    func inputs() -> [[String: String]] {
          let inputs = AVAudioSession.sharedInstance().availableInputs ?? []
          let results = inputs.map { item in
              return [
                  "name": item.portName,
                  "id": item.uid,
              ]
          }
          return results
    }
      
    func setInput(id: String) {
        let inputs = AVAudioSession.sharedInstance().availableInputs ?? []
        if let newOutput = inputs.first(where: {$0.uid == id}) {
            try? AVAudioSession.sharedInstance().setPreferredInput(newOutput)
        }
    }
    
    func outputs() -> [[String: String]] {
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        var results = outputs.map { item in
           return [
              "name": item.portName,
              "id": item.uid,
           ]
        }
        let hasSpeaker = results.contains{ $0["name"] == "Speaker" }
        if (!hasSpeaker) {
            results.append([
                "name": "Speaker",
                "id": "Speaker",
            ])
        } else {
            results.append([
                "name": "Off Speaker",
                "id": "Off Speaker",
            ])
        }
        return results
    }
    
    func setOutput(id: String) {
        if (id == "Speaker") {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
            return
        }
        if (id == "Off Speaker") {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            return
        }
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        if let newOutput = outputs.first(where: {$0.uid == id}) {
            try? AVAudioSession.sharedInstance().setPreferredInput(newOutput)
        }
    }
    
    //video call
    func toggleCamera() {
        if let videoManager = videoManager {
            videoManager.toggleCamera()
        }
    }
    
    func getCameraStatus() -> Bool {
        guard let videoManager = videoManager else { return false }
        return videoManager.isCameraOn
    }
    
    func switchCamera() {
        if let videoManager = videoManager {
            videoManager.switchCamera()
        }
    }
    
    func getLocalPreviewView(frame: CGRect) -> UIView? {
        guard let videoManager = videoManager  else { return nil}
        return videoManager.createView(forVideoLocal: frame)
    }
    
    func getRemotePreviewView(frame: CGRect) -> UIView?  {
        guard let videoManager = videoManager  else { return nil }
        return videoManager.createView(forVideoRemote: frame)
    }
    
    func logout() {
        OmiClient.logout()
    }
    
    func getCurrentUser(completion: @escaping (([String: Any]) -> Void)) {
        let prefs = UserDefaults.standard
        if let user = prefs.value(forKey: "User") as? String {
            getUserInfo(phone: user, completion: completion)
        }
    }
    
    func getGuestUser(completion: @escaping (([String: Any]) -> Void)) {
        getUserInfo(phone: guestPhone, completion: completion)
    }
    
    private func getUserInfo(phone: String, completion: @escaping (([String: Any]) -> Void)) {
        print("account info of begin call \(phone)")
        print("account info of begin call has account")
        if let account = OmiClient.getAccountInfo(phone) as? [String: Any] {
            print("account info of \(phone) \(account)")
            completion(account)
        }
    }
}


