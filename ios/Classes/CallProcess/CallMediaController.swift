//
//  CallMediaController.swift
//  OmiCall Flutter Plugin
//
//  Manages audio (speaker, mute, DTMF, audio outputs) and camera controls for an active call.
//

import Foundation
import AVFoundation
import OmiKit

extension CallManager {

    // MARK: - Audio

    func toogleSpeaker() {
        if !isSpeaker {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)
        } else {
            try? AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
        }
        isSpeaker = !isSpeaker
        SwiftOmikitPlugin.instance?.sendSpeakerStatus()
    }

    /// Toggle mute via CallKit so the native call UI (lock screen, banner) stays in sync.
    func toggleMute(completion: ((Error?) -> Void)? = nil) {
        guard let call = omiLib.getCurrentCall() else {
            completion?(nil)
            return
        }
        omiLib.callManager.toggleMute(for: call) { error in
            completion?(error)
        }
    }

    func sendDTMF(character: String) {
        guard let call = getAvailableCall() else { return }
        if OmiClient.isConsulting() {
            // CallKit path: OmiKit routes the tone to the answered consult call
            omiLib.callManager.sendDTMF(for: call, character: character) { _ in }
        } else {
            // Direct path: no CallKit round-trip for the normal single-call case
            try? call.sendDTMF(character)
        }
    }

    func getAudioOutputs() -> [[String: String]] {
        return OmiClient.getAudioInDevices()
    }

    func setAudioOutputs(portType: String) {
        OmiClient.setAudioOutputs(portType)
    }

    func getCurrentAudio() -> [[String: String]] {
        return OmiClient.getCurrentAudio()
    }

    // MARK: - Video (OMIVideoCallManager, see OmiVideoCoordinator)

    func toggleCamera() {
        OmiVideoCoordinator.shared.toggleCamera()
    }

    func getCameraStatus() -> Bool {
        return OmiVideoCoordinator.shared.isCameraOn
    }

    func switchCamera() {
        OmiVideoCoordinator.shared.switchCamera()
    }
}
