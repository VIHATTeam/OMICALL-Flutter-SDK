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
    private var onSpeakerStatus = false
    private var isFromPushKit: Bool = false
    private var cameraEvent: FlutterEventSink?
    private var onMuteEvent: FlutterEventSink?
    private var onMicEvent: FlutterEventSink?


  public static func register(with registrar: FlutterPluginRegistrar) {
      if (instance == nil) {
          instance = SwiftOmikitPlugin()
      }
      instance!.channel = FlutterMethodChannel(name: "omicallsdk", binaryMessenger: registrar.messenger())
      registrar.addMethodCallDelegate(instance, channel: instance!.channel)
      let cameraEventChannel = FlutterEventChannel(name: "event/camera", binaryMessenger: registrar.messenger())
      cameraEventChannel.setStreamHandler(instance)
      let onMuteEventChannel = FlutterEventChannel(name: "event/on_mute", binaryMessenger: registrar.messenger())
      onMuteEventChannel.setStreamHandler(instance)
      let onMicEventChannel = FlutterEventChannel(name: "event/on_mic", binaryMessenger: registrar.messenger())
      onMicEventChannel.setStreamHandler(instance)
      let localFactory = FLLocalCameraFactory(messenger: registrar.messenger())
      registrar.register(localFactory, withId: "local_camera_view")
      let remoteFactory = FLRemoteCameraFactory(messenger: registrar.messenger())
      registrar.register(remoteFactory, withId: "remote_camera_view")
  }


  func sendEvent(_ event: String, _ body: [String : Any]) {
      DispatchQueue.main.async {[weak self] in
          guard let self = self else { return }
          self.channel.invokeMethod(event, arguments: body)
      }
  }
    
  func sendCameraEvent() {
      if let cameraEvent = cameraEvent {
          let cameraStatus = CallManager.shareInstance().videoManager?.isCameraOn ?? false
          cameraEvent(cameraStatus)
      }
  }
    
  func sendOnMuteStatus() {
      if let call = CallManager.shareInstance().getAvailableCall() {
          if let isMuted = call.muted as? Bool, let onMuteEvent = onMuteEvent {
              print("muteeeeed \(isMuted)")
              onMuteEvent(isMuted)
          }
      }
  }
    
  func sendOnSpeakerStatus() {
      if let onMicEvent = onMicEvent {
        onMicEvent(CallManager.shareInstance().isSpeaker)
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
          result(true)
          break
      case INIT_CALL:
          CallManager.shareInstance().initEndpoint(params: dataOmi)
          result(true)
          break
      case START_CALL:
          let phoneNumber = dataOmi["phoneNumber"] as! String
          var isVideo = false
          if let isVideoCall = dataOmi["isVideo"] as? Bool {
              isVideo = isVideoCall
          }
          CallManager.shareInstance().startCall(phoneNumber, isVideo: isVideo)
          sendOnMuteStatus()
          result(true)
          break
      case END_CALL:
          CallManager.shareInstance().endAvailableCall()
          result(true)
          break
      case TOGGLE_MUTE:
          CallManager.shareInstance().toggleMute()
          sendOnMuteStatus()
          result(true)
          break
      case TOGGLE_SPEAK:
          CallManager.shareInstance().toogleSpeaker()
          result(true)
          sendOnSpeakerStatus()
          break
      case SEND_DTMF:
          CallManager.shareInstance().sendDTMF(character: dataOmi["character"] as! String)
          result(true)
          break
      case SWITCH_CAMERA:
          CallManager.shareInstance().switchCamera()
          result(true)
          break
      case CAMERA_STATUS:
          let status = CallManager.shareInstance().getCameraStatus()
          result(status)
          break
      case TOGGLE_VIDEO:
          let _ = CallManager.shareInstance().toggleCamera()
          sendCameraEvent()
          result(true)
          break
      case INPUTS:
          let inputs = CallManager.shareInstance().inputs()
          result(inputs)
          break
      case OUTPUTS:
          let outputs = CallManager.shareInstance().outputs()
          result(outputs)
          break
      case SET_OUTPUT:
          let id = dataOmi["id"] as! String
          CallManager.shareInstance().setOutput(id: id)
          result(true)
          break
      case SET_INPUT:
          let id = dataOmi["id"] as! String
          CallManager.shareInstance().setInput(id: id)
          result(true)
          break
      case JOIN_CALL:
          CallManager.shareInstance().joinCall()
          result(true)
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
            if (name == "on_mute") {
                onMuteEvent = events
            }
            if (name == "on_mic") {
                onMicEvent = events
            }
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
//        self.cameraEvent = nil
//        self.onMuteEvent = nil
//        self.onMicEvent = nil
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

