import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:easy_dialog/easy_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/constant/events.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';
import 'package:omicall_flutter_plugin/video_call/local_camera_view.dart';
import 'package:omicall_flutter_plugin/video_call/remote_camera_view.dart';

import '../../../components/dial_user_pic.dart';
import '../../../components/option_item.dart';
import '../../../components/rounded_button.dart';
import '../../../constants.dart';
import '../../video_call/video_call_screen.dart';
part 'video_indirect_vm_mixin.dart';

class VideoInDirectView extends StatefulWidget {
  final int status;
  final bool isOutGoingCall;
  const VideoInDirectView({
    Key? key,
    required this.status,
    required this.isOutGoingCall,
  }) : super(key: key);

  @override
  State<VideoInDirectView> createState() => VideoInDirectViewState();
}

class VideoInDirectViewState extends State<VideoInDirectView>
    with VideoInDirectViewModel {
  @override
  void initState() {
    _callStatus = widget.status;
    initializeControllers();
    super.initState();
  }

  @override
  void dispose() {
    OmicallClient.instance.removeVideoEvent();
    OmicallClient.instance.removeMuteListener();
    OmicallClient.instance.removeAudioChangedListener();
    _subscription.cancel();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return WillPopScope(
      child: Scaffold(
        backgroundColor: const Color(0xFF1e3150),
        body: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFF1e3150),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_callStatus ==
                                    OmiCallState.confirmed.rawValue ||
                                _callStatus == OmiCallState.connecting.rawValue)
                              RemoteCameraView(
                                width: double.infinity,
                                height: MediaQuery.of(context).size.height,
                                onCameraCreated: (controller) async {
                                  _remoteController = controller;
                                  if (_callStatus ==
                                          OmiCallState.confirmed.rawValue &&
                                      Platform.isAndroid) {
                                    await Future.delayed(
                                        const Duration(milliseconds: 200));
                                    controller.refresh();
                                  }
                                },
                              ),
                            if (_callStatus !=
                                    OmiCallState.confirmed.rawValue ||
                                _callStatus == OmiCallState.unknown.rawValue)
                              Column(
                                children: [
                                  Text(
                                    _phoneNumberController.text.isEmpty
                                        ? "..."
                                        : "${guestUser?["extension"] ?? "..."}",
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium!
                                        .copyWith(
                                            color: Colors.grey, fontSize: 24),
                                  ),
                                  const SizedBox(
                                    height: 16,
                                  ),
                                  Center(
                                    child: DialUserPic(
                                      size: 200,
                                      image: guestUser?["avatar_url"] != "" &&
                                              guestUser?["avatar_url"] != null
                                          ? guestUser!["avatar_url"]
                                          : "assets/images/calling_face.png",
                                    ),
                                  ),
                                ],
                              ),
                            if (_callStatus == OmiCallState.unknown.rawValue)
                              Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height *
                                        0.85),
                                child: RoundedCircleButton(
                                  iconSrc: "assets/icons/call_end.svg",
                                  press: () async {
                                    if (_phoneNumberController
                                        .text.isNotEmpty) {
                                      makeCall(context);
                                    }
                                  },
                                  color: _phoneNumberController.text.isNotEmpty
                                      ? kGreenColor
                                      : kSecondaryColor,
                                  iconColor: Colors.white,
                                ),
                              ),
                            if (_callStatus == OmiCallState.confirmed.rawValue)
                              Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height *
                                        0.85),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
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
                                _callStatus == OmiCallState.early.rawValue ||
                                _callStatus == OmiCallState.connecting.rawValue)
                              Padding(
                                padding: EdgeInsets.only(
                                    top: MediaQuery.of(context).size.height *
                                        0.85),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    if ((_callStatus ==
                                                OmiCallState.early.rawValue ||
                                            _callStatus ==
                                                OmiCallState
                                                    .incoming.rawValue) &&
                                        _isOutGoingCall == false)
                                      RoundedCircleButton(
                                        iconSrc: "assets/icons/call_end.svg",
                                        press: () async {
                                          final result = await OmicallClient
                                              .instance
                                              .joinCall();
                                          if (result == false && mounted) {
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_callStatus == OmiCallState.confirmed.rawValue)
              Positioned(
                right: 15,
                top: 50,
                child: Padding(
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
              ),
            if (_callStatus == OmiCallState.confirmed.rawValue)
              Positioned(
                top: MediaQuery.of(context).padding.top + kToolbarHeight + 30,
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
                top: MediaQuery.of(context).viewPadding.top + 30,
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

  Widget callButtonWidget(int statusCall) {
    if (statusCall == OmiCallState.unknown.rawValue) {
      return RoundedCircleButton(
        iconSrc: "assets/icons/call_end.svg",
        press: () async {
          if (_phoneNumberController.text.isNotEmpty) {
            makeCall(context);
          }
        },
        color: _phoneNumberController.text.isNotEmpty
            ? kGreenColor
            : kSecondaryColor,
        iconColor: Colors.white,
      );
    } else if (statusCall == OmiCallState.incoming.rawValue) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RoundedCircleButton(
            iconSrc: "assets/icons/call_end.svg",
            press: () async {
              final result = await OmicallClient.instance.joinCall();
              if (result == false && mounted) {
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
                needShowStatus: true,
              );
            },
            color: kRedColor,
            iconColor: Colors.white,
          ),
        ],
      );
    } else if (statusCall == OmiCallState.calling.rawValue ||
        statusCall == OmiCallState.early.rawValue ||
        statusCall == OmiCallState.connecting.rawValue) {
      return RoundedCircleButton(
        iconSrc: "assets/icons/call_end.svg",
        press: () {
          endCall(
            needShowStatus: true,
          );
        },
        color: kRedColor,
        iconColor: Colors.white,
      );
    } else if (statusCall == OmiCallState.confirmed.rawValue) {
      return Row(
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
                needShowStatus: true,
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
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
