//
//  OmiVideoCoordinator.swift
//  OmiCall Flutter Plugin
//
//  Video calls through OMIVideoCallManager (OmiKit 1.11.30+), following the production
//  OMI iOS app (OmiVideoCallViewController / VideoCallWindow):
//    - the SDK owns rendering, background/foreground, re-INVITE recovery, PiP and the
//      remote-connection overlay; the plugin only hands it two container views;
//    - setup() once per call, when both containers have a size and the call is video
//      (video media can flow before CONFIRMED, so do not wait for it);
//    - never call prepareForVideoDisplay() (setup() schedules its own) and never cleanup()
//      mid-call (it kills the live stream) — only at call end, on main, outside SDK callbacks;
//    - the two containers are owned here and reused, so a rebuilt Flutter widget re-parents
//      them instead of forcing a second setup() mid-call (which recreates the video views).
//

import Foundation
import UIKit
import OmiKit

/// Plain container handed to the SDK; reports its first real layout.
final class OmiVideoContainerView: UIView {
    var onLayout: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        clipsToBounds = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width > 0 && bounds.height > 0 { onLayout?() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil { setNeedsLayout() }
    }
}

final class OmiVideoCoordinator: NSObject, OMIVideoCallManagerDelegate {

    static let shared = OmiVideoCoordinator()

    // Persistent containers handed to the SDK; platform views only host them
    private let remoteContainer = OmiVideoContainerView(frame: .zero)
    private let localContainer = OmiVideoContainerView(frame: .zero)
    private var isSetup = false
    private var isRemoteVideoReadySent = false

    /// Overlay text per state name (see `stateName`), from Dart. Empty → SDK Vietnamese text.
    private var overlayTexts: [String: String] = [:]

    private var manager: OMIVideoCallManager { OMIVideoCallManager.shared() }

    private override init() {
        super.init()
        remoteContainer.isUserInteractionEnabled = false
        remoteContainer.onLayout = { [weak self] in self?.trySetup() }
        localContainer.onLayout = { [weak self] in self?.trySetup() }
    }

    /// Plugin registration: set the delegate before any call so callbacks of a call answered
    /// in the background are not missed (same as the app does at launch).
    func start() {
        manager.delegate = self
        manager.remoteConnectionOverlayTextProvider = { [weak self] state in
            guard let text = self?.overlayTexts[OmiVideoCoordinator.stateName(state)], !text.isEmpty else {
                return nil
            }
            return text
        }
    }

    // MARK: - Containers

    /// Move the persistent container into a (new) platform view; frame-based, no Auto Layout.
    func host(remote: Bool, in wrapper: UIView) {
        let container = remote ? remoteContainer : localContainer
        container.removeFromSuperview()
        container.frame = wrapper.bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapper.addSubview(container)
    }

    /// Set the SDK up once per call, when both containers are on screen with a size and the
    /// current call is video. Main thread only.
    func trySetup() {
        guard !isSetup,
              isReady(remoteContainer), isReady(localContainer),
              let call = OMISIPLib.sharedInstance().getCurrentCall(),
              call.isVideo, call.callState != .disconnected else { return }
        manager.setup(withRemoteView: remoteContainer, localView: localContainer)
        isSetup = true
    }

    private func isReady(_ view: UIView) -> Bool {
        return view.window != nil && view.bounds.width > 0 && view.bounds.height > 0
    }

    /// Dart refreshed a view. No event replay: apps call refresh() from setVideoListener.
    func refresh() {
        trySetup()
    }

    // MARK: - Call lifecycle (from CallEventHandler, inside the SDK notification stack)

    func callStateChanged(_ call: OMICall, state: Int) {
        let isVideo = call.isVideo
        // Leave the SDK/PJSIP callback stack (possibly a worker thread holding PJSUA locks)
        // before touching UIKit or the video manager
        performOnMainRunLoop { [weak self] in
            guard let self = self else { return }
            if state == OMICallState.disconnected.rawValue {
                self.endCall()
            } else if isVideo {
                // Video can start before CONFIRMED: set up as soon as the containers are ready
                self.trySetup()
            }
        }
    }

    /// Main thread, outside SDK callbacks.
    private func endCall() {
        isRemoteVideoReadySent = false
        guard isSetup else { return }
        isSetup = false
        manager.cleanup()
    }

    /// CFRunLoopPerformBlock + wake: plain main.async blocks were seen being dropped on the
    /// call-end path in the store app.
    private func performOnMainRunLoop(_ block: @escaping () -> Void) {
        CFRunLoopPerformBlock(CFRunLoopGetMain(), CFRunLoopMode.commonModes.rawValue, block)
        CFRunLoopWakeUp(CFRunLoopGetMain())
    }

    private func sendRemoteVideoReadyOnce() {
        guard !isRemoteVideoReadySent else { return }
        isRemoteVideoReadySent = true
        SwiftOmikitPlugin.instance?.sendEvent(REMOTE_VIDEO_READY, [:])
    }

    // MARK: - Controls

    var isCameraOn: Bool { manager.isCameraOn }

    func toggleCamera() { manager.toggleCamera() }

    func switchCamera() { manager.switchCamera() }

    /// Must be set before setup() to take effect for that call. Returns device support.
    func setPictureInPictureEnabled(_ enabled: Bool) -> Bool {
        manager.pictureInPictureEnabled = enabled
        return manager.isPictureInPictureSupported
    }

    func setOverlayTexts(_ texts: [String: String]) {
        overlayTexts = texts
    }

    // MARK: - OMIVideoCallManagerDelegate

    func videoCallManagerDidReceiveRemoteVideo(_ manager: OMIVideoCallManager) {
        sendRemoteVideoReadyOnce()
    }

    /// Video that arrived before setup() (answered from the lock screen) only reports this one
    func videoCallManagerDidStartVideo(_ manager: OMIVideoCallManager) {
        sendRemoteVideoReadyOnce()
    }

    func videoCallManager(_ manager: OMIVideoCallManager, pictureInPictureDidChange active: Bool) {
        SwiftOmikitPlugin.instance?.sendEvent(PICTURE_IN_PICTURE_CHANGED, ["isActive": active])
    }

    func videoCallManager(_ manager: OMIVideoCallManager,
                          remoteConnectionDidChange state: OMIRemoteConnectionState,
                          duration: TimeInterval) {
        SwiftOmikitPlugin.instance?.sendEvent(REMOTE_CONNECTION_CHANGED, [
            "state": state.rawValue,
            "duration": duration,
        ])
    }

    func videoCallManagerDidEndCall(_ manager: OMIVideoCallManager) {
        performOnMainRunLoop { [weak self] in self?.endCall() }
    }

    // MARK: - Helpers

    static func stateName(_ state: OMIRemoteConnectionState) -> String {
        switch state {
        case .connected: return "connected"
        case .videoPaused: return "videoPaused"
        case .weak: return "weak"
        case .reconnecting: return "reconnecting"
        case .localReconnecting: return "localReconnecting"
        case .networkSwitching: return "networkSwitching"
        case .uplinkPoor: return "uplinkPoor"
        @unknown default: return "unknown"
        }
    }
}
