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
    private var lastStatusCall : String?
    private var tempCallInfo : [String: Any]?
    
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
        let user = UserDefaults.standard
        if let title = data["missedCallTitle"] as? String, let message = data["prefixMissedCallMessage"] as? String {
            user.set(title, forKey: "omicall/missedCallTitle")
            user.set(message, forKey: "omicall/prefixMissedCallMessage")
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
                        let title = user.string(forKey: "omicall/missedCallTitle") ?? ""
                        let message = user.string(forKey: "omicall/prefixMissedCallMessage") ?? ""
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
            NotificationCenter.default.addObserver(CallManager.instance!,
                                                   selector: #selector(self.switchBoardAnswer(_:)),
                                                   name: NSNotification.Name.OMICallSwitchBoardAnswer,
                                                   object: nil
            )
            NotificationCenter.default.addObserver(CallManager.instance!, selector: #selector(self.updateNetworkHealth(_:)), name: NSNotification.Name.OMICallNetworkQuality, object: nil)
            self.showMissedCall()
        }
    }
    
    
    @objc func updateNetworkHealth(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let state     = userInfo[OMINotificationNetworkStatusKey] as? Int else {
            return;
        }
        SwiftOmikitPlugin.instance?.sendEvent(CALL_QUALITY, ["quality": state])
        
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
    
    @objc func switchBoardAnswer(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let sip     = userInfo[OMINotificationSIPKey] as? String else {
            return;
        }
        guestPhone = sip
        SwiftOmikitPlugin.instance?.sendEvent(SWITCHBOARD_ANSWER, ["sip": sip])
    }
    
    @objc func callDealloc(_ notification: NSNotification) {
        if (tempCallInfo != nil) {
            tempCallInfo!["status"] = CallState.disconnected.rawValue
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, tempCallInfo!)
        }
    }
    
    @objc fileprivate func callStateChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let call     = userInfo[OMINotificationUserInfoCallKey] as? OMICall,
              let callState = userInfo[OMINotificationUserInfoCallStateKey] as? Int else {
            return;
        }
        print("callid \(call.uuid)")
        switch (callState) {
        case OMICallState.calling.rawValue:
            NSLog("Outgoing call, in calling state, with OmiId \(call.omiId)")
            var callInfo = baseInfoFromCall(call: call)
            callInfo["status"] = CallState.calling.rawValue
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, callInfo)
            break
        case OMICallState.early.rawValue:
            NSLog("Outgoing call, in early state, with OmiId: \(call.omiId)")
            var callInfo = baseInfoFromCall(call: call)
            callInfo["status"] = CallState.early.rawValue
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, callInfo)
            break
        case OMICallState.connecting.rawValue:
            NSLog("Outgoing call, in connecting state, with OmiId \(call.omiId)")
            var callInfo = baseInfoFromCall(call: call)
            callInfo["status"] = CallState.connecting.rawValue
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, callInfo)
            break
        case OMICallState.hold.rawValue:
            print("hooolddddd \(call.uuid)")
            var callInfo = baseInfoFromCall(call: call)
            callInfo["status"] = CallState.hold.rawValue
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, callInfo)
            break
        case OMICallState.confirmed.rawValue:
            NSLog("Outgoing call, in confirmed state, with OmiId: \(call.omiId)")
            if (videoManager == nil && call.isVideo) {
                videoManager = OMIVideoViewManager.init()
            }
            isSpeaker = call.isVideo
            lastStatusCall = "answered"
            var callInfo = baseInfoFromCall(call: call)
            callInfo["status"] = CallState.confirmed.rawValue
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, callInfo)
            SwiftOmikitPlugin.instance.sendMuteStatus()
            break
        case OMICallState.incoming.rawValue:
            NSLog("Outgoing call, in incoming state, with OmiId: \(call.omiId)")
            guestPhone = call.callerNumber ?? ""
            DispatchQueue.main.async {[weak self] in
                guard let self = self else { return }
                let state: UIApplication.State = UIApplication.shared.applicationState
                if (state == .active) {
                    var callInfo = self.baseInfoFromCall(call: call)
                    callInfo["status"] = CallState.incoming.rawValue
                    SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, callInfo)
                }
            }
            break
        case OMICallState.disconnected.rawValue:
            if (!call.connected) {
                NSLog("Call never connected, in DISCONNECTED state, with UUID: \(call.uuid)")
            } else if (!call.userDidHangUp) {
                NSLog("Call remotly ended, in DISCONNECTED state, with UUID: \(call.uuid)")
            }
            tempCallInfo = getCallInfo(call: call)
            print("call infooooo \(tempCallInfo)")
            if (videoManager != nil) {
                videoManager = nil
            }
            lastStatusCall = nil
            guestPhone = ""
            tempCallInfo!["status"] = CallState.disconnected.rawValue
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, tempCallInfo!)
            tempCallInfo = nil
            break
        default:
            NSLog("Default call state")
            break
        }
    }
    
    private func getCallInfo(call: OMICall) -> [String: Any] {
        var direction = "outbound"
        if (guestPhone.count < 10) {
            direction = "inbound"
        }
        let prefs = UserDefaults.standard
        let user = prefs.value(forKey: "User") as? String
        let status = call.callState == .confirmed ? "answered" : "no_answered"
        let timeEnd = Int(Date().timeIntervalSince1970)
        return [
            "transaction_id" : call.omiId,
            "direction" : direction,
            "source_number" : user,
            "destination_number" : guestPhone,
            "time_start_to_answer" : call.createDate,
            "time_end" : timeEnd,
            "sip_user": user,
            "disposition" : lastStatusCall == nil ? "no_answered" : "answered",
        ]
    }
    
    /// Start call
    func startCall(_ phoneNumber: String, isVideo: Bool, completion: @escaping (_ : Int) -> Void) {
        guestPhone = phoneNumber
        OmiClient.startCall(phoneNumber, isVideo: isVideo) { status in
            DispatchQueue.main.async {
                completion(status.rawValue)
            }
        }
    }
    
    /// Start call
    func startCallWithUuid(_ uuid: String, isVideo: Bool, completion: @escaping (_ : Int) -> Void) {
        let phoneNumber = OmiClient.getPhone(uuid)
        if let phone = phoneNumber {
            guestPhone = phoneNumber ?? ""
            OmiClient.startCall(phone, isVideo: isVideo) { status in
                DispatchQueue.main.async {
                    completion(status.rawValue)
                }
            }
            return
        }
        completion(OMIStartCallStatus.invalidUuid.rawValue)
    }
    
    func endAvailableCall() -> [String: Any] {
        guard let call = getAvailableCall() else {
            let callInfo = [
                "status": CallState.disconnected.rawValue,
            ]
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, callInfo)
            return [:]
        }
        print(call.uuid)
        tempCallInfo = getCallInfo(call: call)
        omiLib.callManager.endActiveCall()
        return tempCallInfo!
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
        if let sipAccount = omiLib.firstAccount()?.accountConfiguration.sipAccount as? String {
            getUserInfo(phone: sipAccount, completion: completion)
        }
    }
    
    func getGuestUser(completion: @escaping (([String: Any]) -> Void)) {
        getUserInfo(phone: guestPhone, completion: completion)
    }
    
    func getUserInfo(phone: String, completion: @escaping (([String: Any]) -> Void)) {
        if let account = OmiClient.getAccountInfo(phone) as? [String: Any] {
            completion(account)
        }
    }
    
    private func baseInfoFromCall(call: OMICall) -> [String: Any] {
        return [
            "callerNumber": call.callerNumber,
            "isVideo": call.isVideo,
            "transactionId": call.omiId,
        ]
    }
}

