//
//  CallEventHandler.swift
//  OmiCall Flutter Plugin
//
//  Handles all NotificationCenter observers from OmiKit and forwards events to Flutter
//  via SwiftOmikitPlugin.sendEvent().
//

import Foundation
import UserNotifications
import OmiKit

extension CallManager {

    // MARK: - Observer Registration

    func registerNotificationCenter(showMissedCall: Bool) {
        let nc = NotificationCenter.default
        nc.removeObserver(self)
        nc.addObserver(self, selector: #selector(callStateChanged(_:)), name: NSNotification.Name.OMICallStateChanged, object: nil)
        nc.addObserver(self, selector: #selector(callDealloc(_:)), name: NSNotification.Name.OMICallDealloc, object: nil)
        nc.addObserver(self, selector: #selector(switchBoardAnswer(_:)), name: NSNotification.Name.OMICallSwitchBoardAnswer, object: nil)
        nc.addObserver(self, selector: #selector(updateNetworkHealth(_:)), name: NSNotification.Name.OMICallNetworkQuality, object: nil)
        nc.addObserver(self, selector: #selector(audioChanged(_:)), name: NSNotification.Name.OMICallAudioRouteChange, object: nil)
        if showMissedCall {
            self.showMissedCall()
        }
    }

    func registerVideoEvent() {
        // Remove before add to prevent duplicate observers on repeated calls
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.OMICallVideoInfo, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(videoUpdate(_:)), name: NSNotification.Name.OMICallVideoInfo, object: nil)
    }

    func removeVideoEvent() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.OMICallVideoInfo, object: nil)
    }

    // MARK: - Missed Call

    func showMissedCall() {
        OmiClient.setMissedCall { call in
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }

                let user = UserDefaults.standard
                let title = user.string(forKey: "omicall/missedCallTitle") ?? ""
                let message = user.string(forKey: "omicall/prefixMissedCallMessage") ?? ""
                let representName = user.string(forKey: "omicall/representName")

                var nameCaller = call.callerNumber
                if let rep = representName, rep.count > 0,
                   let callPhone = call.callerNumber, callPhone.count < 8 {
                    nameCaller = rep
                }

                let content = UNMutableNotificationContent()
                content.title = title
                content.body = "\(message) \(nameCaller ?? "")"
                content.sound = .default
                content.userInfo = [
                    "callerNumber": nameCaller as Any,
                    "isVideo": call.isVideo,
                ]

                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
                let request = UNNotificationRequest(
                    identifier: "\(Int.random(in: 0..<10_000_000))",
                    content: content,
                    trigger: trigger
                )
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            }
        }
    }

    // MARK: - OmiKit Notification Callbacks

    @objc func audioChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let audioInfo = userInfo[OMINotificationCurrentAudioRouteKey] as? [[String: String]] else { return }
        SwiftOmikitPlugin.instance?.sendEvent(AUDIO_CHANGE, ["data": audioInfo])
    }

    @objc func updateNetworkHealth(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let state = userInfo[OMINotificationNetworkStatusKey] as? Int else { return }

        let jitter  = userInfo[OMINotificationJitterKey] as? Double
        let mos     = userInfo[OMINotificationMOSKey] as? Double
        let ppl     = userInfo[OMINotificationPPLKey] as? Double
        let latency = userInfo[OMINotificationLatencyKey] as? Double
        let ts      = Int(Date().timeIntervalSince1970 * 1000)

        let stat: [String: Any] = [
            "req": ts,
            "mos": mos as Any,
            "jitter": jitter as Any,
            "latency": latency as Any,
            "ppl": ppl as Any,
            "lcn": 0
        ]
        SwiftOmikitPlugin.instance?.sendEvent(CALL_QUALITY, ["quality": state, "stat": stat, "isNeedLoading": false])
    }

    @objc func videoUpdate(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let state = userInfo[OMIVideoInfoState] as? Int else { return }
        if state == 1 {
            SwiftOmikitPlugin.instance?.sendEvent(REMOTE_VIDEO_READY, [:])
        }
    }

    @objc func switchBoardAnswer(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let sip = userInfo[OMINotificationSIPKey] as? String else { return }
        guestPhone = sip
        SwiftOmikitPlugin.instance?.sendEvent(SWITCHBOARD_ANSWER, ["sip": sip])
    }

    @objc func callDealloc(_ notification: NSNotification) {
        DispatchQueue.main.async {
            guard let userInfo = notification.userInfo as? [String: Any],
                  let endCause = userInfo[OMINotificationEndCauseKey] as? Int else { return }

            let endMessage: String
            switch endCause {
            case 850: endMessage = "CCU_LIMITED"
            case 487: endMessage = "REQUEST_TERMINATED"
            case 486, 480: endMessage = "BUSY"
            case 600, 503: endMessage = "BUSY_EVERYWHERE"
            case 408: endMessage = "REQUEST_TIME_OUT"
            case 403: endMessage = "YOUR_SERVICE_PLAN_ONLY_ALLOW_CALLS_TO_DIALED_NUMBER"
            case 603: endMessage = "THE_CALL_WAS_REJECTED"
            default:  endMessage = "UNKNOW"
            }

            let data: [String: Any] = [
                "status": OMICallState.disconnected.rawValue,
                "_id": "",
                "message": endMessage,
                "codeEndCall": endCause
            ]
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, data)
        }
    }

    @objc func callStateChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let call = userInfo[OMINotificationUserInfoCallKey] as? OMICall,
              let callState = userInfo[OMINotificationUserInfoCallStateKey] as? Int else { return }

        var dataToSend: [String: Any] = [
            "status": callState,
            "callInfo": "",
            "incoming": false,
            "callerNumber": "",
            "isVideo": false,
            "transactionId": "",
            "_id": ""
        ]

        // Remap early → incoming for inbound calls
        if call.isIncoming && callState == OMICallState.early.rawValue {
            dataToSend["status"] = OMICallState.incoming.rawValue
        }
        dataToSend["_id"]           = String(describing: OmiCallModel(omiCall: call).uuid)
        dataToSend["incoming"]      = call.isIncoming
        dataToSend["callerNumber"]  = call.callerNumber
        dataToSend["isVideo"]       = call.isVideo
        dataToSend["transactionId"] = call.omiId

        if callState != OMICallState.disconnected.rawValue {
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, dataToSend)
        }

        switch callState {
        case OMICallState.confirmed.rawValue:
            if videoManager == nil && call.isVideo {
                videoManager = OMIVideoViewManager()
            }
            isSpeaker = call.isVideo
            lastStatusCall = "answered"
            SwiftOmikitPlugin.instance?.sendMuteStatus()

        case OMICallState.incoming.rawValue:
            guestPhone = call.callerNumber ?? ""

        case OMICallState.disconnected.rawValue:
            tempCallInfo = buildCallInfo(call: call)
            videoManager = nil
            lastStatusCall = nil
            guestPhone = ""

            var combined = dataToSend
            if !tempCallInfo.isEmpty {
                combined.merge(tempCallInfo) { _, new in new }
            }
            SwiftOmikitPlugin.instance?.sendEvent(CALL_STATE_CHANGED, combined)
            lastTimeCall = Date()
            tempCallInfo = [:]

        default:
            break
        }
    }

    // MARK: - Call Info Builder

    func buildCallInfo(call: OMICall) -> [String: Any] {
        let sip = OmiClient.getCurrentSip()
        return [
            "transaction_id":       call.omiId,
            "direction":            call.isIncoming ? "inbound" : "outbound",
            "source_number":        sip as Any,
            "destination_number":   guestPhone,
            "time_start_to_answer": call.createDate,
            "time_end":             Int(Date().timeIntervalSince1970),
            "sip_user":             sip as Any,
            "disposition":          lastStatusCall == nil ? "no_answered" : "answered",
            "code_end_call":        call.lastStatus
        ]
    }
}
