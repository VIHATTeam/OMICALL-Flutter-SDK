//
//  LocalCameraView.swift
//  omicall_flutter_plugin
//
//  Created by PRO 2019 16' on 15/02/2023.
//

import Foundation
import Flutter
import UIKit
import OmiKit

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
    // Host only: the coordinator re-parents its persistent video container in here
    private let _view = UIView(frame: .zero)
    private let methodChannel: FlutterMethodChannel?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        methodChannel = messenger.map {
            FlutterMethodChannel(name: "omicallsdk/remote_camera_controller/\(viewId)", binaryMessenger: $0)
        }
        super.init()
        OmiVideoCoordinator.shared.host(remote: true, in: _view)
        methodChannel?.setMethodCallHandler { [weak self] call, result in
            self?.onMethodCall(call: call, result: result)
        }
    }

    func onMethodCall(call: FlutterMethodCall, result: FlutterResult) {
        switch call.method {
            case "refresh":
                // Kept for compatibility: the SDK handles display itself, so only make sure
                // setup ran (never prepareForVideoDisplay — see OmiVideoCoordinator)
                OmiVideoCoordinator.shared.refresh()
                result(true)
            default:
                result(FlutterMethodNotImplemented)
        }
    }

    func view() -> UIView {
        return _view
    }
}
