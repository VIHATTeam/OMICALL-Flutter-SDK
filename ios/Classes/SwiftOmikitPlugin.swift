import Flutter
import UIKit
import CallKit
import AVFoundation
import OmiKit
import PushKit
import UserNotifications

public class SwiftOmikitPlugin: NSObject, FlutterPlugin {

    @objc public static var instance: SwiftOmikitPlugin!
    private var channel: FlutterMethodChannel!
    private var callManager: CallManager? = nil
    private var sharedProvider: CXProvider? = nil
    private var data: Data?
    private var isFromPushKit: Bool = false
    private var cameraEvent: FlutterEventSink?
    private var micEvent: FlutterEventSink?


  public static func register(with registrar: FlutterPluginRegistrar) {
      if (instance == nil) {
          instance = SwiftOmikitPlugin()
      }
      instance!.channel = FlutterMethodChannel(name: "omicallsdk", binaryMessenger: registrar.messenger())
      registrar.addMethodCallDelegate(instance, channel: instance!.channel)
      let cameraEventChannel = FlutterEventChannel(name: "event/camera", binaryMessenger: registrar.messenger())
      cameraEventChannel.setStreamHandler(instance)
      let micEventChannel = FlutterEventChannel(name: "event/mic", binaryMessenger: registrar.messenger())
      micEventChannel.setStreamHandler(instance)
      let localFactory = FLLocalCameraFactory(messenger: registrar.messenger())
      registrar.register(localFactory, withId: "local_camera_view")
      let remoteFactory = FLRemoteCameraFactory(messenger: registrar.messenger())
      registrar.register(remoteFactory, withId: "remote_camera_view")
  }


  func sendEvent(_ event: String, _ body: [String : Any]) {
      channel.invokeMethod(event, arguments: body)
  }
    
  func sendCameraEvent() {
      if let cameraEvent = cameraEvent {
          let cameraStatus = CallManager.shareInstance().videoManager?.isCameraOn ?? false
          cameraEvent(cameraStatus)
      }
  }
    
  func sendMicStatus() {
      if let micEvent = micEvent {
          let micStatus = OmiClient.getFirstActiveCall()?.muted ?? true
          micEvent(micStatus)
      }
  }


  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
      if(call.method != "action") {
          return
      }
      print("\(call.arguments)")
      guard  let data =  call.arguments as? [String:Any] else  {
          return
      }
      print("\(data["data"])")
      guard let dataOmi = data["data"] as? [String:Any] else {
          return
      }
      print("\(data["actionName"])")
      guard let action = data["actionName"] as? String else {
          return
      }

      switch(action) {
      case UPDATE_TOKEN:
          CallManager.shareInstance().updateToken(params: dataOmi)
          break
      case INIT_CALL:
          CallManager.shareInstance().initEndpoint(params: dataOmi)
          break
      case START_CALL:
          let phoneNumber = dataOmi["phoneNumber"] as! String
          var isVideo = false
          if let isVideoCall = dataOmi["isVideo"] as? Bool {
              isVideo = isVideoCall
          }
          CallManager.shareInstance().startCall(phoneNumber, isVideo: isVideo)
          sendMicStatus()
          sendCameraEvent()
          break
      case HANGUP:
          CallManager.shareInstance().endAllCalls()
          break
      case END_CALL:
          CallManager.shareInstance().endCurrentConfirmCall()
          break
      case TOGGLE_MUTE:
          CallManager.shareInstance().toggleMute {[weak self] in
//              guard let self = self else { return }
              NSLog("done toggle mute")
          }
          sendMicStatus()
          break
      case ON_HOLD:
          result(FlutterMethodNotImplemented)
      case TOGGLE_SPEAK:
          CallManager.shareInstance().toogleSpeaker()
          break
      case SEND_DTMF:
          CallManager.shareInstance().sendDTMF(character: dataOmi["character"] as! String)
          break
      case SWITCH_CAMERA:
          CallManager.shareInstance().switchCamera()
          break
      case CAMERA_STATUS:
          let status = CallManager.shareInstance().getCameraStatus()
          result(status)
          break
      case TOGGLE_VIDEO:
          let _ = CallManager.shareInstance().toggleCamera()
          sendCameraEvent()
          break
      case INPUTS:
          let inputs = CallManager.shareInstance().inputs()
          result(inputs)
          break
      case OUTPUTS:
          let outputs = CallManager.shareInstance().outputs()
          result(outputs)
          break
      case SETOUTPUT:
          let id = dataOmi["id"] as! String
          CallManager.shareInstance().setOutput(id: id)
          break
      case SETINPUT:
          let id = dataOmi["id"] as! String
          CallManager.shareInstance().setInput(id: id)
          break
      default:
          break
      }

  }
}

extension SwiftOmikitPlugin : FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        if let arguments = arguments as? [String: Any], let name = arguments["name"] as? String {
            if (name == "camera") {
                cameraEvent = events
            }
            if (name == "mic") {
                micEvent = events
            }
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.cameraEvent = nil
        self.micEvent = nil
        return nil
    }
}

@objc public extension FlutterAppDelegate {
    func requestNotification() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                break
            case .denied:
                break
            case .notDetermined:
                center.delegate = self
                center.requestAuthorization(options:[.badge, .alert, .sound]) { (granted, error) in
                    if (granted) {
                        DispatchQueue.main.async {
                            UIApplication.shared.registerForRemoteNotifications()
                        }
                    }
                }
            default: break
            }
        }
    }

}

