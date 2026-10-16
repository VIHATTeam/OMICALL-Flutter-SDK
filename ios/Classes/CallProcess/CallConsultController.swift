//
//  CallConsultController.swift
//  OmiCall Flutter Plugin
//
//  Reject / drop of a ringing call and consult (attended) transfer (OmiKit 1.12.0).
//  Consult events are forwarded to Flutter with the same payload as Android.
//

import Foundation
import OmiKit

extension CallManager {

    // MARK: - Reject / Drop

    /// Ringing incoming call → 486 Busy Here; otherwise end the call through CallKit.
    func rejectCall() -> Bool {
        return declineOrEnd { call in try call.decline(withBusyHere: true) }
    }

    /// Ringing incoming call → 603 Decline (stops ringing on every device); otherwise end it.
    func dropCall() -> Bool {
        return declineOrEnd { call in try call.drop() }
    }

    private func declineOrEnd(_ decline: (OMICall) throws -> Void) -> Bool {
        guard let call = omiLib.getCurrentCall(), call.callState != .disconnected else { return false }
        do {
            if call.isIncoming && call.callState != .confirmed {
                try decline(call)
            } else {
                omiLib.callManager.end(call, completion: nil)
            }
            return true
        } catch {
            print("Error rejecting call: \(error)")
            return false
        }
    }

    // MARK: - Consult Transfer

    func startConsultCall(_ extensionNumber: String, extraHeaders: [String: String]?, completion: @escaping (Int) -> Void) {
        // Callback is delivered on the main queue by OmiKit
        OmiClient.startConsultCall(extensionNumber, extraHeaders: extraHeaders) { status in
            completion(status.rawValue)
        }
    }

    func getActiveCalls() -> [[String: Any]] {
        return OmiClient.getActiveCalls().map { call in
            [
                "callId": call.callId,
                "uuid": call.uuid,
                "number": call.number,
                "state": call.state,
                "isHold": call.isHold,
                "isConsult": call.isConsult,
            ]
        }
    }

    // MARK: - Consult Events

    func registerConsultEvents() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(consultStateChanged(_:)),
                       name: NSNotification.Name.OMIConsultStateChanged, object: nil)
        nc.addObserver(self, selector: #selector(transferStatusChanged(_:)),
                       name: NSNotification.Name.OMITransferStatus, object: nil)
        nc.addObserver(self, selector: #selector(callHoldChanged(_:)),
                       name: NSNotification.Name.OMICallHoldChanged, object: nil)
    }

    @objc func consultStateChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        var data = callIdentity(userInfo)
        data["state"] = (userInfo[OMINotificationConsultStateKey] as? NSNumber)?.intValue ?? 0
        data["statusCode"] = (userInfo[OMINotificationStatusCodeKey] as? NSNumber)?.intValue ?? 0
        SwiftOmikitPlugin.instance?.sendEvent(CONSULT_STATE_CHANGED, data)
    }

    @objc func transferStatusChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        var data = callIdentity(userInfo)
        data["statusCode"] = (userInfo[OMINotificationStatusCodeKey] as? NSNumber)?.intValue ?? 0
        data["isFinal"] = (userInfo[OMINotificationIsFinalKey] as? NSNumber)?.boolValue ?? false
        SwiftOmikitPlugin.instance?.sendEvent(TRANSFER_STATUS, data)
    }

    @objc func callHoldChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        var data = callIdentity(userInfo)
        let isHold = (userInfo[OMINotificationIsHoldKey] as? NSNumber)?.boolValue ?? false
        data["isHold"] = isHold
        SwiftOmikitPlugin.instance?.sendEvent(CALL_HOLD_CHANGED, data)
        // Customer call: also the legacy HOLD event, now with the confirmed state (as Android onHold)
        if let uuid = data["uuid"] as? String, uuid == getAvailableCall()?.uuid.uuidString {
            SwiftOmikitPlugin.instance?.sendEvent(HOLD, ["isHold": isHold])
        }
    }

    private func callIdentity(_ userInfo: [AnyHashable: Any]) -> [String: Any] {
        var data: [String: Any] = [
            "callId": (userInfo[OMINotificationCallIdKey] as? NSNumber)?.intValue ?? -1
        ]
        if let uuid = userInfo[OMINotificationCallUUIDKey] as? String {
            data["uuid"] = uuid
        }
        return data
    }
}
