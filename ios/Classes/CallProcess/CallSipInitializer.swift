//
//  CallSipInitializer.swift
//  OmiCall Flutter Plugin
//
//  Handles SIP/API-key registration flows on a background thread to avoid UI freeze.
//  All public methods call completion on the main thread.
//

import Foundation
import OmiKit

extension CallManager {

    // MARK: - Init with API Key

    func initWithApiKeyEndpoint(params: [String: Any], completion: @escaping (String) -> Void) {
        // Skip re-initialization if a call is currently active to avoid destroying the SIP stack mid-call
        if let activeCall = omiLib.getCurrentCall(), activeCall.callState != .disconnected {
            completion(initResultJson(status: 200, message: "INIT_SUCCESS"))
            return
        }

        guard let usrUuid = params["usrUuid"] as? String,
              let fullName = params["fullName"] as? String,
              let apiKey = params["apiKey"] as? String,
              let phone = params["phone"] as? String,
              let fcmToken = params["fcmToken"] as? String else {
            completion(initResultJson(status: 400, message: "MISSING_PARAMS"))
            return
        }

        // isNetworkAvailable uses cached Reachability — safe to call on any thread
        if !OmiClient.isNetworkAvailable() {
            completion(initResultJson(status: 600, message: "NETWORK_UNAVAILABLE"))
            return
        }

        // Serialize on initQueue: if a previous init is still running, skip this call
        // to prevent concurrent HTTP + SIP init causing race conditions / crashes
        initQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.isInitializing else {
                DispatchQueue.main.async {
                    completion(self.initResultJson(status: 200, message: "INIT_SUCCESS"))
                }
                return
            }

            self.isInitializing = true
            defer { self.isInitializing = false }

            if let projectId = params["projectId"] as? String, !projectId.isEmpty {
                OmiClient.setFcmProjectId(projectId)
            }

            // Blocking SDK calls: HTTP request → parse SIP credentials → SIP init → middleware HTTP
            let success = OmiClient.initWithUUIDAndPhone(
                usrUuid,
                fullName: fullName,
                apiKey: apiKey,
                phone: phone
            )
            OmiClient.setUserPushNotificationToken(fcmToken)

            let json = success
                ? self.initResultJson(status: 200, message: "INIT_SUCCESS")
                : self.initResultJson(status: 500, message: "INIT_FAILED")

            DispatchQueue.main.async { completion(json) }
        }
    }

    // MARK: - Init with Username/Password

    func initWithUserPasswordEndpoint(params: [String: Any], completion: @escaping (String) -> Void) {
        // Skip re-initialization if a call is currently active to avoid destroying the SIP stack mid-call
        if let activeCall = omiLib.getCurrentCall(), activeCall.callState != .disconnected {
            completion(initResultJson(status: 200, message: "INIT_SUCCESS"))
            return
        }

        guard
            let userName = params["userName"] as? String,
            let password = params["password"] as? String,
            let realm = params["realm"] as? String,
            let fcmToken = params["fcmToken"] as? String
        else {
            completion(initResultJson(status: 400, message: "MISSING_PARAMS"))
            return
        }

        // isNetworkAvailable uses cached Reachability — safe to call on any thread
        if !OmiClient.isNetworkAvailable() {
            completion(initResultJson(status: 600, message: "NETWORK_UNAVAILABLE"))
            return
        }

        // Serialize on initQueue: if a previous init is still running, skip this call
        // to prevent concurrent NSUserDefaults writes and SIP init causing data corruption
        initQueue.async { [weak self] in
            guard let self = self else { return }

            guard !self.isInitializing else {
                DispatchQueue.main.async {
                    completion(self.initResultJson(status: 200, message: "INIT_SUCCESS"))
                }
                return
            }

            self.isInitializing = true
            defer { self.isInitializing = false }

            if let projectId = params["projectId"] as? String, !projectId.isEmpty {
                OmiClient.setFcmProjectId(projectId)
            }

            // Blocking SDK calls: writes SIP credentials to NSUserDefaults → SIP init → middleware HTTP
            OmiClient.initWithUsername(userName, password: password, realm: realm, proxy: "vh.omicrm.com:5222")
            OmiClient.setUserPushNotificationToken(fcmToken)

            DispatchQueue.main.async {
                completion(self.initResultJson(status: 200, message: "INIT_SUCCESS"))
            }
        }
    }

    // MARK: - Helpers

    func initResultJson(status: Int, message: String) -> String {
        let dict: [String: Any] = ["status": status, "message": message]
        if let data = try? JSONSerialization.data(withJSONObject: dict),
           let str = String(data: data, encoding: .utf8) {
            return str
        }
        return "{\"status\":\(status),\"message\":\"\(message)\"}"
    }
}
