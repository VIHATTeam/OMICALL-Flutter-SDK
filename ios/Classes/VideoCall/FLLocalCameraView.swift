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

class FLLocalCameraFactory: NSObject, FlutterPlatformViewFactory {
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
        return FLLocalCameraView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger
        )
    }
}

class FLLocalCameraView: NSObject, FlutterPlatformView {
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
        methodChannel = FlutterMethodChannel(name: "local_camera_controller/\(viewId)", binaryMessenger: messenger!)
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
        let child = UIView()
        _view.addSubview(child)
        child.frame = _view.bounds
        let topView = UIView()
        child.addSubview(topView)
        let height = child.bounds.height
        let width = child.bounds.width
        topView.frame = CGRect(x: 0, y: 0, width: width, height: height / 2)
        topView.backgroundColor = .yellow
        let bottomView = UIView()
        child.addSubview(bottomView)
        bottomView.frame = CGRect(x: 0, y: height / 2, width: width, height: height / 2)
        bottomView.backgroundColor = .red
        //create text
        let text = UILabel()
        topView.addSubview(text)
        text.text = _arg?["title"] as! String
        text.frame = CGRect(x: 15, y: 15, width: width - 30, height: 20)
        text.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(clickText)))
        text.isUserInteractionEnabled = true
    }
    
    @objc func clickText() {
        print("aaaa")
        if let channel = methodChannel {
            channel.invokeMethod("click", arguments: nil)
        }
    }
    
}
