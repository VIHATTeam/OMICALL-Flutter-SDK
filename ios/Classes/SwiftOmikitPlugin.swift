import Flutter
import UIKit
import CallKit
import AVFoundation
import OmiKit
import PushKit
import UserNotifications

public class SwiftOmikitPlugin: NSObject, FlutterPlugin {

    @objc public static var instance: SwiftOmikitPlugin!
    static let OMICallStateChangedNotification = "OMICallStateChangedNotification";

    private var channel: FlutterMethodChannel!
    private var callManager: CallManager? = nil
    private var sharedProvider: CXProvider? = nil
    private var data: Data?
    private var isFromPushKit: Bool = false


  public static func register(with registrar: FlutterPluginRegistrar) {
      if (instance == nil) {
          instance = SwiftOmikitPlugin()
      }
      instance!.channel = FlutterMethodChannel(name: "omicallsdk", binaryMessenger: registrar.messenger())
      registrar.addMethodCallDelegate(instance, channel: instance!.channel)
      let factory = FLLocalCameraFactory(messenger: registrar.messenger())
      registrar.register(factory, withId: "local_camera_view")
      
  }


  func sendEvent(_ event: String, _ body: [String : Any]) {
      channel.invokeMethod(event, arguments: body)
  }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if(call.method != "action") {
          return
      }
      print(call.arguments)
      guard  let data =  call.arguments as? [String:Any] else  {
          return
      }
      print(data["data"])
      guard let dataOmi = data["data"] as? [String:Any] else {
          return
      }
      print(data["actionName"])
      guard let action = data["actionName"] as? String else {
          return
      }

      switch(action) {
      case INIT_CALL:
          CallManager.shareInstance().initEndpoint(params: dataOmi as! [String: String])
          break
      case START_CALL:
          let phoneNumber = dataOmi["phoneNumber"] as! String
          CallManager.shareInstance().startCall(phoneNumber)
          break
      case HANGUP:
          CallManager.shareInstance().endAllCalls()
          break
      case END_CALL:
          CallManager.shareInstance().endCurrentConfirmCall()
          break
      case TOGGLE_MUTE:
          CallManager.shareInstance().toggleMute {
              NSLog("done toggleMute")
          }
      case ON_HOLD:
          result(FlutterMethodNotImplemented)
      case TOGGLE_SPEAK:
          CallManager.shareInstance().toogleSpeaker()
          break
      case SEND_DTMF:
          CallManager.shareInstance().sendDTMF(character: dataOmi["character"] as! String)
      default:
          break
      }

  }
}


class EventCallbackHandler: FlutterStreamHandler {
    private var eventSink: FlutterEventSink?

    public func send(_ event: String, _ body: Any) {
        let data: [String : Any] = [
            "event": event,
            "body": body
        ]
        eventSink?(data)
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}


@objc public extension FlutterAppDelegate {
    func registerOmicall(enviroment: String, supportVideoCall: Bool = false) -> PushKitManager? {
        OmiClient.setEnviroment(enviroment)
        _ = CallKitProviderDelegate.init(callManager: OMISIPLib.sharedInstance().callManager)
        let voipRegistry = PKPushRegistry.init(queue: DispatchQueue.main)
        let result = PushKitManager.init(voipRegistry: voipRegistry)
        UserDefaults.standard.set("vh.omicrm.com", forKey: "SIPProxy")
        OmiClient.startOmiService(supportVideoCall)
        requestNotification()
        return result
    }

    func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
            if (granted) {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
    }

}
