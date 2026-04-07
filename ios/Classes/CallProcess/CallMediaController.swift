//
//  CallMediaController.swift
//  OmiCall Flutter Plugin
//
//  Manages audio (speaker, mute, DTMF, audio outputs) and video (camera toggle,
//  switch, local/remote preview views) for an active call.
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

    func toggleMute() {
        guard let call = omiLib.getCurrentCall() else { return }
        try? call.toggleMute()
    }

    func sendDTMF(character: String) {
        guard let call = getAvailableCall() else { return }
        try? call.sendDTMF(character)
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

    // MARK: - Video

    func toggleCamera() {
        videoManager?.toggleCamera()
    }

    func getCameraStatus() -> Bool {
        return videoManager?.isCameraOn ?? false
    }

    func switchCamera() {
        videoManager?.switchCamera()
    }

    func getLocalPreviewView(frame: CGRect) -> UIView? {
        return videoManager?.createView(forVideoLocal: frame)
    }

    func getRemotePreviewView(frame: CGRect) -> UIView? {
        return videoManager?.createView(forVideoRemote: frame)
    }
}
