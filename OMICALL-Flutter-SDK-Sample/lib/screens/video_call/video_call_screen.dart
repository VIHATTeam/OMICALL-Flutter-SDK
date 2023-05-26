import 'dart:async';
import 'dart:io';

import 'package:calling/screens/home/home_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';
import '../../components/rounded_button.dart';
import '../../constants.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    Key? key,
    required this.status,
  }) : super(key: key);

  final int status;

  @override
  State<StatefulWidget> createState() {
    return VideoCallState();
  }
}

class VideoCallState extends State<VideoCallScreen> {
  RemoteCameraController? _remoteController;
  LocalCameraController? _localController;
  late StreamSubscription _subscription;
  late StreamSubscription _videoSubscription;
  String _callingStatus = '';

  @override
  void initState() {
    _callingStatus = statusToDescription(widget.status);
    OmicallClient.instance.registerVideoEvent();
    super.initState();
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
      if (omiAction.actionName == OmiEventList.onCallStateChanged) {
        final data = omiAction.data;
        final status = data["stauts"] as int;
        updateVideoScreen(null, status);
        if (status == OmiCallState.confirmed.rawValue) {
          if (Platform.isAndroid) {
            refreshRemoteCamera();
          }
        }
        if (status == OmiCallState.disconnected.rawValue) {
          endCall(
            context,
            needShowStatus: true,
            needRequest: false,
          );
          return;
        }
      }
    });
    _videoSubscription = OmicallClient.instance.videoEvent.listen((action) {
      // final name = action["name"];
      // final data = action["data"];
      refreshRemoteCamera();
      refreshLocalCamera();
    });
  }

  @override
  void dispose() {
    OmicallClient.instance.removeVideoEvent();
    _subscription.cancel();
    _videoSubscription.cancel();
    super.dispose();
  }

  void updateVideoScreen(Map<String, dynamic>? callInfo, int? status) {
    setState(() {
      _callingStatus = statusToDescription(status ?? 0);
    });
  }

  Future<void> endCall(
    BuildContext context, {
    bool needRequest = true,
    bool needShowStatus = true,
  }) async {
    if (needRequest) {
      OmicallClient.instance.endCall();
    }
    if (needShowStatus) {
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
  }

  Future<void> outputOptions(BuildContext context) async {
    final data = await OmicallClient.instance.getOutputAudios() as List;
    if (!mounted) {
      return;
    }
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
    if (!mounted) {
      return;
    }
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

  void refreshLocalCamera() {
    _localController?.refresh();
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
              endCall(
                context,
                needShowStatus: false,
              );
            },
          ),
          actions: [
            if (_callingStatus == statusToDescription(OmiCallState.confirmed.rawValue)) ...[
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
          ],
        ),
        body: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: Container(
                color: Colors.grey,
                child: RemoteCameraView(
                  width: double.infinity,
                  height: double.infinity,
                  onCameraCreated: (controller) async {
                    _remoteController = controller;
                    if (_callingStatus == statusToDescription(OmiCallState.confirmed.rawValue) && Platform.isAndroid) {
                      await Future.delayed(const Duration(milliseconds: 200));
                      controller.refresh();
                    }
                  },
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 12,
              right: 16,
              width: width / 3,
              height: (3 * width) / 5,
              child: LocalCameraView(
                width: double.infinity,
                height: double.infinity,
                onCameraCreated: (controller) async {
                  _localController = controller;
                  if (_callingStatus == statusToDescription(OmiCallState.confirmed.rawValue) && Platform.isAndroid) {
                    await Future.delayed(const Duration(milliseconds: 200));
                    controller.refresh();
                  }
                },
                errorWidget: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.white,
                  child: const Center(
                    child: Icon(
                      Icons.remove_red_eye,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
            if (_callingStatus == statusToDescription(OmiCallState.confirmed.rawValue))
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StreamBuilder(
                      initialData: true,
                      stream: OmicallClient.instance.videoEvent,
                      builder: (context, snapshot) {
                        return OptionItem(
                          icon: "video",
                          showDefaultIcon: true,
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
                        endCall(
                          context,
                          needShowStatus: false,
                        );
                      },
                    ),
                    StreamBuilder(
                      initialData: true,
                      stream: OmicallClient.instance.micEvent,
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
            if (_callingStatus == statusToDescription(OmiCallState.calling.rawValue) ||
                _callingStatus == statusToDescription(OmiCallState.early.rawValue))
              Text(
                _callingStatus,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            if (_callingStatus == statusToDescription(OmiCallState.calling.rawValue) ||
                _callingStatus == statusToDescription(OmiCallState.early.rawValue))
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if (_callingStatus == "Ringing")
                      RoundedCircleButton(
                        iconSrc: "assets/icons/call_end.svg",
                        press: () async {
                          final result =
                              await OmicallClient.instance.joinCall();
                          if (result == false && context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        color: kGreenColor,
                        iconColor: Colors.white,
                      ),
                    RoundedCircleButton(
                      iconSrc: "assets/icons/call_end.svg",
                      press: () {
                        endCall(
                          context,
                          needShowStatus: false,
                        );
                      },
                      color: kRedColor,
                      iconColor: Colors.white,
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

  const OptionItem({
    Key? key,
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
