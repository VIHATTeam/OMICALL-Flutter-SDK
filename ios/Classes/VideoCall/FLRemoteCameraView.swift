//
//  LocalCameraView.swift
//  omicall_flutter_plugin
//
//  Created by PRO 2019 16' on 15/02/2023.
//

import Foundation
import Flutter
import WebKit
import UIKit

class FLRemoteCameraFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger

    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
    
    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return FLRemoteCameraView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
}

class FLRemoteCameraView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var _arg : [String : Any]?
    private let methodChannel: FlutterMethodChannel?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        _arg = args as? [String: Any]
        methodChannel = FlutterMethodChannel(name: "remote_camera_controller/\(viewId)", binaryMessenger: messenger!)
        super.init()
        methodChannel?.setMethodCallHandler(onMethodCall)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {[weak self] in
            guard let self = self else { return }
            self.setupViews()
        })
    }
    
    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
            switch(call.method){
            case "":
                break
            default:
                result(FlutterMethodNotImplemented)
            }
        }

    func view() -> UIView {
        return _view
    }

    func setupViews() {
        CallManager.instance?.getRemotePreviewView(callback: {[weak self] previewView in
            guard let self = self else { return }
            self._view.addSubview(previewView)
            print(self._view.bounds)
            previewView.frame = self._view.bounds
        })
    }
    
    @objc func clickText() {
        if let channel = methodChannel {
            channel.invokeMethod("click", arguments: nil)
        }
    }
    
}
