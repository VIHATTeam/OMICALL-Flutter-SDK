import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

typedef LocalCameraCreatedCallback = void Function(
  LocalCameraController controller,
);

class LocalCameraView extends StatefulWidget {
  final LocalCameraCreatedCallback? onCameraCreated;

  final double width;
  final double height;
  final Widget? errorWidget;

  const LocalCameraView({
    Key? key,
    required this.width,
    required this.height,
    this.onCameraCreated,
    this.errorWidget,
  }) : super(key: key);

  @override
  State<LocalCameraView> createState() => _LocalCameraViewState();
}

class _LocalCameraViewState extends State<LocalCameraView> {
  // This is used in the platform side to register the view.
  final String viewType = 'omicallsdk/local_camera_view';

  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};
  late final LocalCameraController _controller;
  bool? _hasPermission;

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
    _controller = LocalCameraController._(id);
    widget.onCameraCreated?.call(_controller);
    checkCameraPermission();
  }

  Future<void> checkCameraPermission() async {
    final result = await _controller.isGrantedCameraPermission();
    setState(() {
      _hasPermission = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const SizedBox.expand(),
          cameraPlatformView,
          if (_hasPermission == false) widget.errorWidget ?? const SizedBox(),
        ],
      ),
    );
  }
}

class LocalCameraController {
  LocalCameraController._(int id)
      : _channel = MethodChannel('omicallsdk/local_camera_controller/$id');

  final MethodChannel _channel;

  MethodChannel get channel => _channel;

  void addListener(Function(String, dynamic) callback) {
    _channel.setMethodCallHandler((method) async {
      callback(method.method, method.arguments);
    });
  }

  Future<bool> isGrantedCameraPermission() async {
    final result = await _channel.invokeMethod<bool>("permission");
    return result ?? false;
  }

  void refresh() {
    _channel.invokeMethod("refresh");
  }
}
