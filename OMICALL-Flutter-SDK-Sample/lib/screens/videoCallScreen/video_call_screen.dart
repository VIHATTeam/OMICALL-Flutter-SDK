import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

class VideoCallScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return VideoCallState();
  }
}

class VideoCallState extends State<VideoCallScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          SizedBox.expand(
            child: RemoteCameraView(
              width: double.infinity,
              height: double.infinity,
              onCameraCreated: (controller) {
                controller.addListener(
                      (event, arguments) {
                    debugPrint("aaa");
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 32,
            right: 16,
            width: 100,
            height: 160,
            child: LocalCameraView(
              width: double.infinity,
              height: double.infinity,
              onCameraCreated: (controller) {
                controller.addListener(
                  (event, arguments) {
                    debugPrint("aaa");
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
