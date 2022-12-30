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
import OmiKit

class CallManager {
    
    static var instance: CallManager? = nil // Instance
    var account: OMIAccount! // Account
    var call: OMICall? // Call
    var pingTime: Int = 0 // Ping time
    private var numberRetry: Int = 0
    var isCallError: Bool = false  // check when call error
    private let omiClient = OmiClient.self
    private let omiLib = OMISIPLib.sharedInstance()
    private var isSpeaker = false
    var currentConfirmedCall : OMICall?
    
    
    /// Get instance
    static func shareInstance() -> CallManager {
        if (instance == nil) {
            instance = CallManager()
        }
        return instance!
    }
    
    
    public func initEndpoint(params: [String: String]){
        OmiClient.initWithUsername(params["userName"]!, password: params["password"]!, realm: params["realm"]!)
        omiLib.callManager.audioController.configureAudioSession()
//        OmiClient.startOmiService(true)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(callStateChanged(_:)),
                                               name: NSNotification.Name(rawValue: SwiftOmikitPlugin.OMICallStateChangedNotification),
                                               object: nil
        )
        
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
                SwiftOmikitPlugin.instance?.sendEvent(onRinging, [:])
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
            if (!call.isIncoming) {
                NSLog("Outgoing call, in CONFIRMED state, with UUID: \(call.uuid)")
                SwiftOmikitPlugin.instance?.sendEvent(onCallEstablished, [:])
                SwiftOmikitPlugin.instance?.sendEvent(onMuted, ["isMuted": call.muted])
                currentConfirmedCall = call
            }
            break
        case .disconnected:
            if (!call.connected) {
                NSLog("Call never connected, in DISCONNECTED state, with UUID: \(call.uuid)")
            } else if (!call.userDidHangUp) {
                NSLog("Call remotly ended, in DISCONNECTED state, with UUID: \(call.uuid)")
            }
            print(omiLib.getCurrentCall()?.uuid.uuidString)
            print(call.uuid.uuidString)
            if let currentActiveCall = currentConfirmedCall, currentActiveCall.uuid.uuidString == call.uuid.uuidString {
                SwiftOmikitPlugin.instance?.sendEvent(onCallEnd, [:])
                currentConfirmedCall = nil
                break
            }
            if currentConfirmedCall == nil {
                SwiftOmikitPlugin.instance?.sendEvent(onCallEnd, [:])
                break
            }
            print(omiLib.getNewestCall()?.uuid.uuidString)
            break
        case .incoming:
            SwiftOmikitPlugin.instance?.sendEvent(incomingReceived, [
                "callerId": call.callId,
                "phoneNumber": call.callerNumber
            ])
            break
        case .muted:
            SwiftOmikitPlugin.instance?.sendEvent(onMuted, ["isMuted": call.muted])
            break
        case .hold:
            SwiftOmikitPlugin.instance?.sendEvent(onHold, ["isHold": call.onHold])
        @unknown default:
            NSLog("Default call state")
        }
    }
    
    /// Start call
    func startCall(_ phoneNumber: String) {
        OmiClient.startCall(phoneNumber);
    }
    
    /// End call
    func endNewestCall() {
        guard let call = omiLib.getNewestCall() else {
            return
        }
        omiLib.callManager.end(call) { error in
            if error != nil {
                NSLog("error hanging up call(\(call.uuid.uuidString)): \(error!)")
            }
        }
        guard let call = omiLib.getCurrentCall() else {
            endNewestCall()
            return
        }
        
    }
    
    func sendDTMF(character: String) {
        guard let call = omiLib.getCurrentCall() else {
            return
        }
        try? call.sendDTMF(character)
    }
    
    func endCurrentConfirmCall() {
        guard let call = omiLib.getCurrentCall() else {
            endNewestCall()
            return
        }
        omiLib.callManager.end(call) { error in
            if error != nil {
                NSLog("error hanging up call(\(call.uuid.uuidString)): \(error!)")
            }
        }
    }
    
    
    func endAllCalls() {
        omiLib.callManager.endAllCalls()
        SwiftOmikitPlugin.instance?.sendEvent("onCallEnd", [:])

    }
    
    /// Toogle mtue
    func toggleMute(completion: @escaping () -> Void?) {
        guard let omicall = OMISIPLib.sharedInstance().getCurrentCall() else {
            return
        }
        
        omiLib.callManager.toggleMute(for: omicall) { error in
            if error != nil {
                NSLog("toggle mute error:  \(error))")
            }
        }
        
    }
    
    /// Toogle hold
    func toggleHold(completion: @escaping () -> Void?) {
        guard let omicall = OMISIPLib.sharedInstance().getCurrentCall() else {
            return
        }
        DispatchQueue.main.async {[weak self] in
            guard let self = self else { return }
            self.omiLib.callManager.toggleHold(for: omicall) { error in
                if error != nil {
                    NSLog("Error holding current call: \(error!)")
                    return
                } else {
                    completion()
                }
            }
        }
    }
    
    
    /// Toogle speaker
    func toogleSpeaker() {
        do{
            if (!isSpeaker) {
                isSpeaker = true
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
                
            } else {
                isSpeaker = true
                try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
            }
        }catch (let error){
            NSLog("Error toogleSpeaker current call: \(error)")

        }
    }
}

