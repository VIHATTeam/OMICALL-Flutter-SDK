import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef RemoteCameraCreatedCallback = void Function(
  RemoteCameraController controller,
);

class RemoteCameraView extends StatelessWidget {
  // This is used in the platform side to register the view.
  final String viewType = 'omicallsdk/remote_camera_view';
  final RemoteCameraCreatedCallback? onCameraCreated;

  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};
  final double width;
  final double height;
  late final RemoteCameraController _controller;

  RemoteCameraView({
    Key? key,
    required this.width,
    required this.height,
    this.onCameraCreated,
  }) : super(key: key);

  Widget get cameraPlatformView {
    if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      );
    }
    return AndroidView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
  }

  // Callback method when platform view is created
  void _onPlatformViewCreated(int id) {
    _controller = RemoteCameraController._(id);
    onCameraCreated?.call(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: cameraPlatformView,
    );
  }
}

class RemoteCameraController {
  RemoteCameraController._(int id)
      : _channel = MethodChannel('omicallsdk/remote_camera_controller/$id');

  final MethodChannel _channel;

  void addListener(Function(String, dynamic) callback) {
    _channel.setMethodCallHandler((method) async {
      callback(method.method, method.arguments);
    });
  }

  Future<bool> checkPermission() async {
    return true;
  }

  void refresh() {
    _channel.invokeMethod("refresh");
  }
}
