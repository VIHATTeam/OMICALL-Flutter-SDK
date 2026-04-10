//
//  CallManager.swift
//  OmiCall Flutter Plugin
//
//  Central coordinator and shared state for call lifecycle.
//  Specific concerns are split into extensions:
//    - CallSipInitializer.swift  — SIP registration (API key / username-password)
//    - CallEventHandler.swift    — OmiKit NotificationCenter observers → Flutter events
//    - CallMediaController.swift — Audio (speaker, mute, DTMF) and video (camera)
//

import Foundation
import OmiKit

class CallManager {

    // MARK: - Singleton

    private static let sharedInstance = CallManager()

    static func shareInstance() -> CallManager {
        return sharedInstance
    }

    // MARK: - Shared State (accessed by extensions)

    let omiLib = OMISIPLib.sharedInstance()
    var videoManager: OMIVideoViewManager?
    var isSpeaker = false
    var guestPhone: String = ""
    var lastStatusCall: String?
    var tempCallInfo: [String: Any] = [:]
    var lastTimeCall: Date = Date()

    // Serial queue + flag used by CallSipInitializer to serialize init calls
    let initQueue = DispatchQueue(label: "com.omicall.sdk.init", qos: .userInitiated)
    var isInitializing = false

    // MARK: - Call Access

    func getAvailableCall() -> OMICall? {
        return omiLib.getCurrentConfirmCall() ?? omiLib.getNewestCall()
    }

    // MARK: - Call Control

    /// Start call — OmiClient.startCall is already async, no DispatchQueue needed
    func startCall(_ phoneNumber: String, isVideo: Bool, completion: @escaping (String) -> Void) {
        guestPhone = phoneNumber
        // Run on background thread to avoid blocking UI when SIP connection is slow
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            OmiClient.startCall(phoneNumber, isVideo: isVideo) { statusCall in
                var data: [String: Any] = [
                    "status": statusCall.rawValue,
                    "_id": "",
                    "message": self.messageCall(type: statusCall.rawValue)
                ]
                if let current = self.omiLib.getCurrentCall() {
                    data["_id"] = String(describing: OmiCallModel(omiCall: current).uuid)
                }
                completion(self.convertDictionaryToJson(dictionary: data) ?? "Conversion to JSON failed")
            }
        }
    }

    /// Start call with UUID — getPhone is async (HTTP/cache), startCall runs on background thread
    func startCallWithUuid(_ uuid: String, isVideo: Bool, completion: @escaping (String) -> Void) {
        OmiClient.getPhone(uuid) { [weak self] phone in
            guard let self = self else { return }
            guard let phone = phone else {
                // Must call completion to avoid hanging the Flutter await
                completion(self.convertDictionaryToJson(dictionary: [
                    "status": 0, "_id": "", "message": "INVALID_UUID"
                ]) ?? "Conversion to JSON failed")
                return
            }
            self.guestPhone = phone
            // Run on background thread to avoid blocking UI when SIP connection is slow
            DispatchQueue.global(qos: .userInitiated).async {
                OmiClient.startCall(phone, isVideo: isVideo) { statusCall in
                    var data: [String: Any] = [
                        "status": statusCall.rawValue,
                        "_id": "",
                        "message": self.messageCall(type: statusCall.rawValue)
                    ]
                    if let current = self.omiLib.getCurrentCall() {
                        data["_id"] = String(describing: OmiCallModel(omiCall: current).uuid)
                    }
                    completion(self.convertDictionaryToJson(dictionary: data) ?? "Conversion to JSON failed")
                }
            }
        }
    }

    func endAvailableCall() -> [String: Any] {
        guard let call = getAvailableCall() else {
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, ["status": CallState.disconnected.rawValue])
            return [:]
        }
        tempCallInfo = buildCallInfo(call: call)
        omiLib.callManager.endActiveCall()
        return tempCallInfo
    }

    func endAllCalls() {
        omiLib.callManager.endAllCalls()
    }

    func joinCall() {
        guard let call = getAvailableCall() else { return }
        OmiClient.answerIncommingCall(call.uuid)
    }

    func toggleHold() -> Bool {
        guard let call = getAvailableCall() else { return false }
        do {
            try call.toggleHold()
            return true
        } catch {
            print("Error toggling hold: \(error)")
            return false
        }
    }

    func transferCall(_ phoneNumber: String) -> Bool {
        guard let call = omiLib.getCurrentConfirmCall(), call.callState != .disconnected else {
            print("No active call or call is disconnected.")
            return false
        }
        call.blindTransferCall(withNumber: phoneNumber)
        return true
    }

    // MARK: - User Info

    func updateToken(params: [String: Any]) {
        if let apnsToken = params["apnsToken"] as? String {
            OmiClient.setUserPushNotificationToken(apnsToken)
        }
    }

    func configNotification(data: [String: Any]) {
        let defaults = UserDefaults.standard
        if let title = data["missedCallTitle"] as? String,
           let message = data["prefixMissedCallMessage"] as? String {
            defaults.set(title, forKey: "omicall/missedCallTitle")
            defaults.set(message, forKey: "omicall/prefixMissedCallMessage")
        }
    }

    func getCurrentUser(completion: @escaping ([String: Any]) -> Void) {
        guard let sip = OmiClient.getCurrentSip() else {
            completion([:])
            return
        }
        getUserInfo(phone: sip, completion: completion)
    }

    func getGuestUser(completion: @escaping ([String: Any]) -> Void) {
        getUserInfo(phone: guestPhone, completion: completion)
    }

    func getUserInfo(phone: String, completion: @escaping ([String: Any]) -> Void) {
        if let account = OmiClient.getAccountInfo(phone) as? [String: Any] {
            completion(account)
        } else {
            completion([:])
        }
    }

    func logout() {
        OmiClient.logout()
    }

    // MARK: - Helpers

    func convertDictionaryToJson(dictionary: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary),
              let str = String(data: data, encoding: .utf8) else { return nil }
        return str
    }

    func messageCall(type: Int) -> String {
        switch type {
        case 0:  return "INVALID_UUID"
        case 1:  return "INVALID_PHONE_NUMBER"
        case 2:  return "SAME_PHONE_NUMBER_WITH_PHONE_REGISTER"
        case 3:  return "MAX_RETRY"
        case 4:  return "PERMISSION_DENIED"
        case 5:  return "COULD_NOT_FIND_END_POINT"
        case 6:  return "REGISTER_ACCOUNT_FAIL"
        case 7:  return "START_CALL_FAIL"
        case 9:  return "HAVE_ANOTHER_CALL"
        case 10: return "ACCOUNT_TURN_OFF_NUMBER_INTERNAL"
        case 11: return "NO_NETWORK"
        default: return "START_CALL_SUCCESS"
        }
    }
}
