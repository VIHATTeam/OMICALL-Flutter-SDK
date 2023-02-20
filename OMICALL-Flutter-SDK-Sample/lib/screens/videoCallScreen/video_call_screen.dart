import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return VideoCallState();
  }
}

class VideoCallState extends State<VideoCallScreen> {
  RemoteCameraController? _remoteController;

  @override
  void initState() {
    super.initState();
  }

  void refreshRemoteCamera() {
    _remoteController?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          color: Colors.black,
          icon: Icon(
            Icons.arrow_back_rounded,
            size: 24,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            onPressed: () {},
            color: Colors.black,
            icon: Icon(
              Icons.cameraswitch_rounded,
              size: 24,
              color: Colors.white,
            ),
          ),
          const SizedBox(
            width: 16,
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox.expand(
            child: Container(
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
              color: Colors.grey,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            width: MediaQuery.of(context).size.width / 3,
            height: MediaQuery.of(context).size.height / 3,
            child: RemoteCameraView(
              width: double.infinity,
              height: double.infinity,
              onCameraCreated: (controller) {
                _remoteController = controller;
              },
            ),
          ),
        ],
      ),
    );
  }
}
