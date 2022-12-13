import Flutter
import UIKit
import OmiKit

public class SwiftOmicallsdkPlugin: NSObject, FlutterPlugin {
    private let omiLib = OMISIPLib.sharedInstance()
    private var omiCall: OMICall? // Call
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "omicallsdk", binaryMessenger: registrar.messenger())
        let instance = SwiftOmicallsdkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(call.method != "action") {
            return
        }
        guard  let data =  call.arguments as? [String:Any] , let dataOmi = data["data"] as? [String:Any] , let action = dataOmi["action"] as? String else  {
            return
        }
        
        
        switch(action) {
        case INIT_CALL:
            let userName = dataOmi["userName"] as! String
            let password = dataOmi["password"] as! String
            let realm = dataOmi["realm"] as! String
            OmiClient.initWithUsername(userName, password: password, realm: realm)
            
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(callStateChanged(_:)),
                                                   name: NSNotification.Name(rawValue: "OMICallStateChangedNotification"),
                                                   object: nil)
            
        case START_CALL:
            let phoneNumber = dataOmi["String"] as! String
            OmiClient.startCall(phoneNumber)
        case START_OMI_SERVICE:
            OmiClient.startOmiService(false)
        case HANGUP:
            omiLib.callManager.endAllCalls()
        case TOGGLE_MUTE:
            guard let omicall = OMISIPLib.sharedInstance().getCurrentCall() else {
                return
            }
            
            OMISIPLib.sharedInstance().callManager.toggleMute(for: omicall) { error in
                if error != nil {
                    NSLog("toggle mute error:  \(error))")
                }
            }
        case ON_HOLD:
            guard let omiCall =  omiCall else {return}
            omiLib.callManager.toggleHold(for: omiCall) { error in
                if error != nil {
                    NSLog("Error holding current call: \(error!)")
                    return
                } else {
                    
                }
            }
        case TOGGLE_SPEAK:
            let isSpeaker =  dataOmi["String"] as! Bool
            do{
                if(isSpeaker){
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.none)
                }else{
                    try AVAudioSession.sharedInstance().overrideOutputAudioPort(.speaker)

                }
            }catch (let error){
                NSLog("Error toogleSpeaker current call: \(error)")
            }
            
        default:
            break
        }
    
    }
    
    
    @objc fileprivate func callStateChanged(_ notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let call     = userInfo[OMINotificationUserInfoCallKey] as? OMICall else {
            return;
        }
        omiCall =  call
        
        switch (call.callState) {
        case .calling:
            if (!call.isIncoming) {
                NSLog("Outgoing call, in CALLING state, with UUID \(call.uuid)")
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
                //                        OMICallFlutterPlugin.sharedInstance?.sendEvent("onCallEstablished", [:])
            }
            break
        case .disconnected:
            if (!call.connected) {
                NSLog("Call never connected, in DISCONNECTED state, with UUID: \(call.uuid)")
            } else if (!call.userDidHangUp) {
                NSLog("Call remotly ended, in DISCONNECTED state, with UUID: \(call.uuid)")
            }
            //                    OMICallFlutterPlugin.sharedInstance?.sendEvent("onCallEnd", [:])
            
            break
        case .null:
            break
        case .incoming:
            break
        @unknown default:
            NSLog("Default call state")
        }
    }
    
    
}
