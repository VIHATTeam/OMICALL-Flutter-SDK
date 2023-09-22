import 'dart:async';
import 'dart:io';

import 'package:calling/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../../components/dial_button.dart';
import '../../../components/dial_user_pic.dart';
import '../../../components/rounded_button.dart';
import '../../../numeric_keyboard/numeric_keyboard.dart';
part 'dial_indirect_vm_mixin.dart';

String statusToDescription(int status) {
  if (status == OmiCallState.calling.rawValue) {
    return "Đang kết nối tới cuộc gọi";
  }
  if (status == OmiCallState.connecting.rawValue) {
    return "Đang kết nối";
  }
  if (status == OmiCallState.early.rawValue) {
    return "Cuộc gọi đang đổ chuông";
  }
  if (status == OmiCallState.confirmed.rawValue) {
    return "Cuộc gọi bắt đầu";
  }
  if (status == OmiCallState.disconnected.rawValue) {
    return "Cuộc gọi kết thúc";
  }
  return "";
}

class DialInDirectView extends StatefulWidget {
  final String? phoneNumber;
  final int status;
  final bool isOutGoingCall;
  const DialInDirectView({
    Key? key,
    this.phoneNumber,
    required this.status,
    required this.isOutGoingCall,
  }) : super(key: key);

  @override
  State<DialInDirectView> createState() => DialInDirectViewState();
}

class DialInDirectViewState extends State<DialInDirectView>
    with DialInDirectViewModel {
  @override
  void initState() {
    initController();
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stopWatch();
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

    bool checkShowOption = _callStatus == OmiCallState.early.rawValue ||
        _callStatus == OmiCallState.connecting.rawValue ||
        _callStatus == OmiCallState.confirmed.rawValue;
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
              child: Stack(
                alignment: AlignmentDirectional.topCenter,
                children: [
                  if (_callStatus == OmiCallState.confirmed.rawValue)
                    Padding(
                      padding: const EdgeInsets.only(
                        top: 270,
                      ),
                      child: Text(
                        _callQuality,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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
                                  "${current?["extension"] ?? "..."}",
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
                                  image: current?["avatar_url"] != "" &&
                                          current?["avatar_url"] != null
                                      ? current!["avatar_url"]
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
                                  "${guestUser?["extension"] ?? "..."}",
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
                            _callTime ?? statusToDescription(_callStatus),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                        ...callOtherOptionWidget(checkShowOption),
                        if (_callStatus == OmiCallState.incoming.rawValue)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.43,
                          )
                        else if (_callStatus != OmiCallState.confirmed.rawValue)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.2,
                          )
                        else
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.19,
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            if ((_callStatus == OmiCallState.early.rawValue ||
                                    _callStatus ==
                                        OmiCallState.incoming.rawValue) &&
                                widget.isOutGoingCall == false)
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
                            if (_callStatus > OmiCallState.unknown.rawValue)
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_isShowKeyboard)
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
                              _keyboardMessage,
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
                                _isShowKeyboard = !_isShowKeyboard;
                                _keyboardMessage = "";
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
                              _isShowKeyboard = !_isShowKeyboard;
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
