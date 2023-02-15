import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class LocalCameraView extends StatelessWidget {
  // This is used in the platform side to register the view.
  final String viewType = 'local_camera_view';

  // Pass parameters to the platform side.
  final Map<String, dynamic> creationParams = <String, dynamic>{};
  final double width;
  final double height;

  LocalCameraView({
    super.key,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: UiKitView(
        viewType: viewType,
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      ),
    );
  }
}
