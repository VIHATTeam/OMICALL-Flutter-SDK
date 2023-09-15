import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:calling/extensions/int_extensions.dart';
import 'package:easy_dialog/easy_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/constant/events.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';

import '../../../components/dial_button.dart';
import '../../../components/dial_user_pic.dart';
import '../../../components/rounded_button.dart';
import '../../../components/textfield_custom_widget.dart';
import '../../../constants.dart';
import '../../../local_storage/local_storage.dart';
import '../../../main.dart';
import '../../../numeric_keyboard/numeric_keyboard.dart';
import '../../HomeLoginScreen.dart';
import '../direct_call_screen.dart';

part 'dial_direct_vm_mixin.dart';

class DialDirectView extends StatefulWidget {
  final String? phoneNumber;
  // final bool isVideo;
  final int status;
  final bool isOutGoingCall;
  const DialDirectView({
    Key? key,
    this.phoneNumber = '',
    // required this.isVideo,
    required this.status,
    required this.isOutGoingCall,
  }) : super(key: key);

  @override
  State<DialDirectView> createState() => _DialDirectViewState();
}

class _DialDirectViewState extends State<DialDirectView>
    with DialDirectViewModel {
  @override
  void initState() {
    phoneNumberController = TextEditingController(text: widget.phoneNumber);
    isOutGoingCall = widget.isOutGoingCall;
    callStatus = widget.status;
    initializeControllers(callStatus);
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stopWatch();
    phoneNumberController.clear();
    phoneNumberController.dispose();
    OmicallClient.instance.removeCallQualityListener();
    OmicallClient.instance.removeMuteListener();
    OmicallClient.instance.removeAudioChangedListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWith = MediaQuery.of(context).size.width;
    var correctWidth = (screenWith - 20) / 4;
    if (correctWidth > 100) {
      correctWidth = 100;
    }

    return WillPopScope(
      child: Scaffold(
        body: Stack(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Image.asset(
                "assets/images/signIn01.png",
                width: MediaQuery.of(context).size.width * 0.9,
              ),
            ),
            Align(
              alignment: Alignment.bottomLeft,
              child: Image.asset(
                "assets/images/signIn02.png",
                height: MediaQuery.of(context).size.height * 0.28,
              ),
            ),
            SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 150),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              children: [
                                Text(
                                  "${currentUser?["extension"] ?? "..."}",
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium!
                                      .copyWith(
                                          color: Colors.grey, fontSize: 24),
                                ),
                                const SizedBox(
                                  height: 16,
                                ),
                                DialUserPic(
                                  size: correctWidth,
                                  image: (currentUser?["avatar_url"] != "" &&
                                          currentUser?["avatar_url"] != null)
                                      ? currentUser!["avatar_url"]
                                      : "assets/images/calling_face.png",
                                ),
                              ],
                            ),
                            const SizedBox(
                              width: 16,
                            ),
                            Column(
                              children: [
                                Text(
                                  phoneNumberController.text.isEmpty &&
                                          (callStatus ==
                                              OmiCallState.confirmed.rawValue)
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
                                DialUserPic(
                                  size: correctWidth,
                                  image: guestUser?["avatar_url"] != "" &&
                                          guestUser?["avatar_url"] != null
                                      ? guestUser!["avatar_url"]
                                      : "assets/images/calling_face.png",
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 16),
                          child: Text(
                            callTime ?? callStatus.statusToDescription(),
                            //statusToDescription($callStatus),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                        if (callStatus == OmiCallState.confirmed.rawValue) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DialButton(
                                iconSrc: !isMuted
                                    ? 'assets/icons/ic_microphone.svg'
                                    : 'assets/icons/ic_block_microphone.svg',
                                text: "Microphone",
                                press: () {
                                  toggleMute(context);
                                },
                              ),
                              if (currentAudio != null)
                                DialButton(
                                  iconSrc: 'assets/images/$_audioImage.png',
                                  text: _audioTitle,
                                  press: () {
                                    toggleAndCheckDevice();
                                  },
                                ),
                              DialButton(
                                iconSrc: "assets/icons/ic_video.svg",
                                text: "Video",
                                press: () {},
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              DialButton(
                                iconSrc: "assets/icons/ic_message.svg",
                                text: "Message",
                                press: () {
                                  setState(() {
                                    isShowKeyboard = !isShowKeyboard;
                                  });
                                },
                                color: Colors.grey,
                              ),
                              DialButton(
                                iconSrc: "assets/icons/ic_user.svg",
                                text: "Add contact",
                                press: () {},
                                color: Colors.grey,
                              ),
                              DialButton(
                                iconSrc: "assets/icons/ic_voicemail.svg",
                                text: "Voice mail",
                                press: () {},
                                color: Colors.grey,
                              ),
                            ],
                          ),
                        ],
                        if (callStatus != OmiCallState.confirmed.rawValue)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.43,
                          )
                        else
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.19,
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if (callStatus == OmiCallState.unknown.rawValue)
                              RoundedCircleButton(
                                iconSrc: "assets/icons/call_end.svg",
                                press: () async {
                                  if (phoneNumberController.text.isNotEmpty) {
                                    makeCall();
                                  }
                                },
                                color: phoneNumberController.text.isNotEmpty
                                    ? kGreenColor
                                    : kSecondaryColor,
                                iconColor: Colors.white,
                              ),
                            if ((callStatus == OmiCallState.early.rawValue ||
                                    callStatus ==
                                        OmiCallState.incoming.rawValue) &&
                                isOutGoingCall == false)
                              RoundedCircleButton(
                                iconSrc: "assets/icons/call_end.svg",
                                press: () async {
                                  final result =
                                      await OmicallClient.instance.joinCall();
                                  if (result == false && mounted) {
                                    Navigator.pop(context);
                                  }
                                },
                                color: kGreenColor,
                                iconColor: Colors.white,
                              ),
                            if (callStatus > OmiCallState.unknown.rawValue)
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
                        ),
                      ],
                    ),
                  ),

                  // Positioned(
                  //   top: 10,
                  //   left: 12,
                  //   right: 12,
                  //   child: Text(
                  //     _callQuality,
                  //     textAlign: TextAlign.center,
                  //     style: const TextStyle(
                  //       color: Colors.white,
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.w600,
                  //     ),
                  //   ),
                  // )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 68),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      debugPrint("=======+++++++$callStatus++++++======");
                      if (callStatus == OmiCallState.confirmed.rawValue) {
                        await endCall(
                          needShowStatus: true,
                          needRequest: true,
                        ).then(
                          (value) async {
                            EasyLoading.show();
                            Navigator.of(context).pop();
                            Navigator.push(context,
                                MaterialPageRoute(builder: (_) {
                              return const HomeLoginScreen();
                            }));

                            await OmicallClient.instance.logout();
                            await LocalStorage.instance.logout();

                            EasyLoading.dismiss();
                          },
                        );
                      } else {
                        EasyLoading.show();
                        Navigator.of(context).pop();
                        Navigator.push(context, MaterialPageRoute(builder: (_) {
                          return const HomeLoginScreen();
                        }));

                        await OmicallClient.instance.logout();
                        await LocalStorage.instance.logout();

                        EasyLoading.dismiss();
                      }
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
                      child: TextFieldCustomWidget(
                        controller: phoneNumberController,
                        hintLabel: 'Phone Number',
                        icon: Icons.phone,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isShowKeyboard)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  height: 350,
                  color: Colors.white,
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          const SizedBox(
                            width: 54,
                          ),
                          Expanded(
                            child: Text(
                              keyboardMessage,
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.red,
                                fontWeight: FontWeight.w700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(
                            width: 12,
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                isShowKeyboard = !isShowKeyboard;
                                keyboardMessage = "";
                              });
                            },
                            child: const Icon(
                              Icons.cancel,
                              color: Colors.grey,
                              size: 30,
                            ),
                          ),
                          const SizedBox(
                            width: 24,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Expanded(
                        child: NumericKeyboard(
                          onKeyboardTap: _onKeyboardTap,
                          textColor: Colors.red,
                          rightButtonFn: () {
                            setState(() {
                              isShowKeyboard = !isShowKeyboard;
                            });
                          },
                          rightIcon: const Text(
                            "*",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 24,
                            ),
                          ),
                          leftButtonFn: () {
                            _onKeyboardTap("*");
                          },
                          leftIcon: const Text(
                            "#",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 24,
                            ),
                          ),
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      onWillPop: () async => false,
    );
  }
}
