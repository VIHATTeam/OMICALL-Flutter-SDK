import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../components/dial_user_pic.dart';
import '../../components/rounded_button.dart';
import '../../constants.dart';

class VideoCallScreen extends StatefulWidget {
  const VideoCallScreen({
    Key? key,
    required this.status,
    required this.isOutGoingCall,
  }) : super(key: key);

  final int status;
  final bool isOutGoingCall;

  @override
  State<StatefulWidget> createState() {
    return VideoCallState();
  }
}

class VideoCallState extends State<VideoCallScreen> {
  RemoteCameraController? _remoteController;
  LocalCameraController? _localController;
  late StreamSubscription _subscription;
  int _callStatus = 0;
  bool isMuted = false;
  Map? _currentAudio;
  String _callQuality = "";
  TextEditingController _phoneNumberController = TextEditingController();
  Map? guestUser;

  Future<void> getGuestUser() async {
    final user = await OmicallClient.instance.getGuestUser();
    if (user != null) {
      setState(() {
        guestUser = user;
      });
    }
  }

  @override
  void initState() {
    _callStatus = widget.status;
    initializeControllers();
    super.initState();
  }

  Future<void> initializeControllers() async {
    OmicallClient.instance.registerVideoEvent();
    await getGuestUser();
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
      if (omiAction.actionName == OmiEventList.onCallStateChanged) {
        final data = omiAction.data;
        final status = data["status"] as int;
        updateVideoScreen(status);
        if (status == OmiCallState.confirmed.rawValue) {
          if (Platform.isAndroid) {
            refreshRemoteCamera();
            refreshLocalCamera();
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
    OmicallClient.instance.setVideoListener((data) {
      refreshRemoteCamera();
      refreshLocalCamera();
    });
    OmicallClient.instance.setMuteListener((p0) {
      setState(() {
        isMuted = p0;
      });
    });
    OmicallClient.instance.setAudioChangedListener((newAudio) {
      setState(() {
        _currentAudio = newAudio.first;
      });
    });
    OmicallClient.instance.getCurrentAudio().then((value) {
      setState(() {
        _currentAudio = value.first;
      });
    });
    OmicallClient.instance.setCallQualityListener((data) {
      final quality = data["quality"] as int;
      setState(() {
        if (quality == 0) {
          _callQuality = "GOOD";
        }
        if (quality == 1) {
          _callQuality = "NORMAL";
        }
        if (quality == 2) {
          _callQuality = "BAD";
        }
      });
    });
  }

  @override
  void dispose() {
    OmicallClient.instance.removeVideoEvent();
    OmicallClient.instance.removeMuteListener();
    OmicallClient.instance.removeAudioChangedListener();
    _subscription.cancel();
    super.dispose();
  }

  void updateVideoScreen(int status) {
    setState(() {
      _callStatus = status;
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

  void refreshRemoteCamera() {
    _remoteController?.refresh();
  }

  void refreshLocalCamera() {
    _localController?.refresh();
  }

  String get _audioImage {
    final name = _currentAudio!["name"] as String;
    if (name == "Receiver") {
      return "ic_iphone";
    }
    if (name == "Speaker") {
      return "ic_speaker";
    }
    return "ic_airpod";
  }

  Future<void> toggleAndCheckDevice() async {
    final audioList = await OmicallClient.instance.getOutputAudios();
    if (!mounted) {
      return;
    }
    if (audioList.length > 2) {
      //show selection
      showCupertinoModalPopup(
        context: context,
        builder: (_) => CupertinoActionSheet(
          actions: audioList.map((e) {
            String name = e["name"];
            if (name == "Receiver") {
              name = "iPhone";
            }
            return CupertinoActionSheetAction(
              onPressed: () {
                OmicallClient.instance.setOutputAudio(portType: e["type"]);
                Navigator.pop(context);
              },
              child: Text(name),
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
    } else {
      if (_currentAudio!["name"] == "Receiver") {
        final speaker =
            audioList.firstWhere((element) => element["name"] == "Speaker");
        OmicallClient.instance.setOutputAudio(portType: speaker["type"]);
      } else {
        final receiver =
            audioList.firstWhere((element) => element["name"] == "Receiver");
        OmicallClient.instance.setOutputAudio(portType: receiver["type"]);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(
      String text,
      IconData? icon,
    ) {
      return InputDecoration(
        labelText: text,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        hintText: text,
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          size: MediaQuery.of(context).size.width * 0.06,
          color: Colors.grey,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.01),
          ),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: BorderSide(
            color: Colors.red,
            width: MediaQuery.of(context).size.width * 0.01,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 225, 121, 243),
            width: MediaQuery.of(context).size.width * 0.008,
          ),
        ),
      );
    }

    final width = MediaQuery.of(context).size.width;
    // var correctWidth = (width - 20) / 4;
    // if (correctWidth > 100) {
    //   correctWidth = 100;
    // }
    return WillPopScope(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.deepPurple,
        // appBar: AppBar(
        //   backgroundColor: Colors.transparent,
        //   elevation: 0,
        //   leading: IconButton(
        //     color: Colors.black,
        //     icon: const Icon(
        //       Icons.arrow_back_rounded,
        //       size: 24,
        //       color: Colors.white,
        //     ),
        //     onPressed: () {
        //       endCall(
        //         context,
        //         needShowStatus: false,
        //       );
        //     },
        //   ),
        //   actions: [
        //     if (_callStatus == OmiCallState.confirmed.rawValue) ...[
        //       IconButton(
        //         onPressed: () {
        //           OmicallClient.instance.switchCamera();
        //         },
        //         color: Colors.black,
        //         icon: const Icon(
        //           Icons.cameraswitch_rounded,
        //           size: 24,
        //           color: Colors.white,
        //         ),
        //       ),
        //       const SizedBox(
        //         width: 16,
        //       ),
        //     ],
        //   ],
        // ),
        body: Stack(
          //alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: Container(
                color: Colors.grey,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    RemoteCameraView(
                      width: double.infinity,
                      height: double.infinity,
                      onCameraCreated: (controller) async {
                        _remoteController = controller;
                        if (_callStatus == OmiCallState.confirmed.rawValue &&
                            Platform.isAndroid) {
                          await Future.delayed(
                              const Duration(milliseconds: 200));
                          controller.refresh();
                        }
                      },
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: MediaQuery.of(context).size.height * 0.35),
                      child: Column(
                        children: [
                          Text(
                            _phoneNumberController.text.isEmpty
                                ? "..."
                                : "${guestUser?["extension"] ?? "..."}",
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium!
                                .copyWith(color: Colors.grey, fontSize: 24),
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          DialUserPic(
                            size: 200,
                            image: guestUser?["avatar_url"] != "" &&
                                    guestUser?["avatar_url"] != null
                                ? guestUser!["avatar_url"]
                                : "assets/images/calling_face.png",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 50),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      await endCall(
                        context,
                        needShowStatus: true,
                        needRequest: false,
                      );
                       Navigator.of(context).pop();
                    },
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.all(
                        Radius.circular(
                            MediaQuery.of(context).size.width * 0.1),
                      ),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(
                          MediaQuery.of(context).size.width * 0.1),
                      child: TextFormField(
                        controller: _phoneNumberController,
                        keyboardType: TextInputType.phone,
                        decoration:
                            inputDecoration('Phone Number', Icons.phone),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'This field cannot be empty';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  if (_callStatus == OmiCallState.confirmed.rawValue)
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: GestureDetector(
                        onTap: () async {
                          OmicallClient.instance.switchCamera();
                        },
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.all(
                            Radius.circular(
                                MediaQuery.of(context).size.width * 0.1),
                          ),
                          child: Container(
                            width: 52,
                            height: 52,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: const Icon(
                              Icons.cameraswitch_rounded,
                              size: 25,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
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
                  if (_callStatus == OmiCallState.confirmed.rawValue &&
                      Platform.isAndroid) {
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
            if (_callStatus == OmiCallState.confirmed.rawValue)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OptionItem(
                      icon: "video",
                      showDefaultIcon: true,
                      callback: () {
                        OmicallClient.instance.toggleVideo();
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
                    OptionItem(
                      icon: "mic",
                      showDefaultIcon: isMuted,
                      callback: () {
                        OmicallClient.instance.toggleAudio();
                      },
                    ),
                    if (_currentAudio != null)
                      OptionItem(
                        icon: _audioImage,
                        showDefaultIcon: true,
                        color: Colors.white,
                        callback: () {
                          toggleAndCheckDevice();
                        },
                      ),
                  ],
                ),
              ),
            if (_callStatus == OmiCallState.calling.rawValue ||
                _callStatus == OmiCallState.incoming.rawValue ||
                _callStatus == OmiCallState.early.rawValue)
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).padding.bottom + 32,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    if ((_callStatus == OmiCallState.early.rawValue ||
                            _callStatus == OmiCallState.incoming.rawValue) &&
                        widget.isOutGoingCall == false)
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
            Positioned(
              top: MediaQuery.of(context).viewPadding.top + 16,
              left: 12,
              right: 12,
              child: Text(
                _callQuality,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
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
  final Color? color;

  const OptionItem({
    Key? key,
    required this.icon,
    this.showDefaultIcon = true,
    required this.callback,
    this.color,
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
            color: color,
          ),
        ),
      ),
    );
  }
}
