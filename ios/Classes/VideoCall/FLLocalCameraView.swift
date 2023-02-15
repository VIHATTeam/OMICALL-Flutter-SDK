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

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?
    ) {
        _view = UIView()
        super.init()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {[weak self] in
            guard let self = self else { return }
            self.setupViews()
        })
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
    }
    
}
