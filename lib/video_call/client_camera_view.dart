import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class ClientCameraView extends StatelessWidget {
  // This is used in the platform side to register the view.
  final String viewType = 'client_camera_view';
  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};

  ClientCameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return UiKitView(
      viewType: viewType,
      layoutDirection: TextDirection.ltr,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );
  }
}