import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return VideoCallState();
  }
}

class VideoCallState extends State<VideoCallScreen> {
  RemoteCameraController? _remoteController;
  LocalCameraController? _localController;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    _subscription =
        OmicallClient.instance.controller.eventTransferStream.listen((omiAction) {
          if (omiAction.actionName == OmiEventList.onCallEstablished) {
            refreshRemoteCamera();
            localRemoteCamera();
          }
          if (omiAction.actionName == OmiEventList.onCallEnd) {
            // endCall(context);
            return;
          }
        });
  }

  Future<void> outputOptions(BuildContext context) async {
    final data = await OmicallClient.instance.getOutputAudios() as List;
    if (!mounted) { return; }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: data.map((e) {
          return CupertinoActionSheetAction(
            onPressed: () {
              OmicallClient.instance.setOutputAudio(id: "${e["id"]}");
              Navigator.pop(context);
            },
            child: Text(e["name"]),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ),
    );
  }

  Future<void> inputOptions(BuildContext context) async {
    final data = await OmicallClient.instance.getInputAudios() as List;
    if (!mounted) { return; }
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: data.map((e) {
          return CupertinoActionSheetAction(
            onPressed: () {
              OmicallClient.instance.setInputAudio(id: "${e["id"]}");
              Navigator.pop(context);
            },
            child: Text(e["name"]),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ),
    );
  }

  Future<void> moreOption(BuildContext context) async {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              outputOptions(context);
            },
            child: const Text("Outputs"),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              inputOptions(context);
            },
            child: const Text("Inputs"),
          )
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Close'),
        ),
      ),
    );
  }

  void refreshRemoteCamera() {
    _remoteController?.refresh();
  }

  void localRemoteCamera() {
    _localController?.refresh();
  }

  endCall(BuildContext context) {
    OmicallClient.instance.endCall();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return WillPopScope(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            color: Colors.black,
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 24,
              color: Colors.white,
            ),
            onPressed: () {
              endCall(context);
            },
          ),
          actions: [
            IconButton(
              onPressed: () {
                OmicallClient.instance.switchCamera();
              },
              color: Colors.black,
              icon: const Icon(
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
                color: Colors.grey,
                child: LocalCameraView(
                  width: double.infinity,
                  height: double.infinity,
                  onCameraCreated: (controller) {
                    _localController = controller;
                    controller.addListener(
                      (event, arguments) {
                        debugPrint("aaa");
                      },
                    );
                  },
                ),
              ),
            ),
            // Positioned(
            //   top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
            //   right: 16,
            //   width: width / 3,
            //   height: (3 * width) / 5,
            //   child: RemoteCameraView(
            //     width: double.infinity,
            //     height: double.infinity,
            //     onCameraCreated: (controller) {
            //       _remoteController = controller;
            //     },
            //   ),
            // ),
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  StreamBuilder(
                    initialData: true,
                    stream: OmicallClient.instance.cameraEvent(),
                    builder: (context, snapshot) {
                      final cameraStatus = snapshot.data as bool;
                      return OptionItem(
                        icon: "video",
                        showDefaultIcon: cameraStatus,
                        callback: () {
                          OmicallClient.instance.toggleVideo();
                        },
                      );
                    },
                  ),
                  OptionItem(
                    icon: "hangup",
                    showDefaultIcon: true,
                    callback: () {
                      endCall(context);
                    },
                  ),
                  StreamBuilder(
                    initialData: true,
                    stream: OmicallClient.instance.onMicEvent(),
                    builder: (context, snapshot) {
                      final micStatus = snapshot.data as bool;
                      return OptionItem(
                        icon: "mic",
                        showDefaultIcon: micStatus,
                        callback: () {
                          OmicallClient.instance.toggleAudio();
                        },
                      );
                    },
                  ),
                  OptionItem(
                    icon: "more",
                    showDefaultIcon: true,
                    callback: () {
                      moreOption(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      onWillPop: () async => false,
    );
  }
}

class OptionItem extends StatelessWidget {
  final String icon;
  final bool showDefaultIcon;
  final VoidCallback callback;

  const OptionItem({Key? key,
    required this.icon,
    this.showDefaultIcon = true,
    required this.callback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: callback,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: Colors.black,
        ),
        child: Center(
          child: Image.asset(
            "assets/images/${showDefaultIcon ? icon : "$icon-off"}.png",
            width: 30,
            height: 30,
          ),
        ),
      ),
    );
  }
}
