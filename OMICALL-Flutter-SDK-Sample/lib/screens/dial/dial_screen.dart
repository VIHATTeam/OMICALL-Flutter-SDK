import 'dart:async';

import 'package:calling/components/call_status.dart';
import 'package:calling/constants.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../components/dial_user_pic.dart';
import '../../components/rounded_button.dart';
import '../../numeric_keyboard/numeric_keyboard.dart';
import 'widgets/dial_button.dart';

class DialScreen extends StatefulWidget {
  const DialScreen({
    Key? key,
    this.phoneNumber,
    required this.status,
  }) : super(key: key);

  final String? phoneNumber;
  final CallStatus status;

  @override
  State<DialScreen> createState() => DialScreenState();
}

class DialScreenState extends State<DialScreen> {
  bool _isMuted = false;
  bool _isMic = false;
  String _callingStatus = '';
  bool _isShowKeyboard = false;
  String message = "";

  Stopwatch watch = Stopwatch();
  Timer? timer;

  @override
  void initState() {
    if (widget.status == CallStatus.established) {
      _startWatch();
    } else {
      _callingStatus = widget.status.value;
    }
    super.initState();
  }

  void updateDialScreen(Map<String, dynamic>? callInfo, CallStatus? status) {
    if (status == CallStatus.established) {
      _startWatch();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        backgroundColor: kBackgoundColor,
        body: SafeArea(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              const SizedBox.expand(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(
                      "#${widget.phoneNumber ?? ""}",
                      style: Theme.of(context)
                          .textTheme
                          .headline4!
                          .copyWith(color: Colors.white),
                    ),
                    Text(
                      _callingStatus,
                      style: const TextStyle(
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const DialUserPic(
                      image: "assets/images/calling_face.png",
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DialButton(
                          iconSrc: _isMic
                              ? 'assets/icons/ic_microphone.svg'
                              : 'assets/icons/ic_block_microphone.svg',
                          text: "Microphone",
                          press: () {
                            toggleSpeaker(context);
                          },
                        ),
                        DialButton(
                          iconSrc: !_isMuted
                              ? 'assets/icons/ic_audio.svg'
                              : 'assets/icons/ic_no_audio.svg',
                          text: "Audio",
                          press: () {
                            toggleMute(context);
                          },
                        ),
                        DialButton(
                          iconSrc: "assets/icons/Icon Video.svg",
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
                          iconSrc: "assets/icons/Icon Message.svg",
                          text: "Message",
                          press: () {
                            setState(() {
                              _isShowKeyboard = !_isShowKeyboard;
                            });
                          },
                          color: Colors.white,
                        ),
                        DialButton(
                          iconSrc: "assets/icons/Icon User.svg",
                          text: "Add contact",
                          press: () {},
                          color: Colors.grey,
                        ),
                        DialButton(
                          iconSrc: "assets/icons/Icon Voicemail.svg",
                          text: "Voice mail",
                          press: () {},
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const Spacer(),
                    RoundedButton(
                      iconSrc: "assets/icons/call_end.svg",
                      press: () {
                        endCall(context);
                      },
                      color: kRedColor,
                      iconColor: Colors.white,
                    )
                  ],
                ),
              ),
              if (_isShowKeyboard)
                Container(
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
                              message,
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
                                message = "";
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
                )
            ],
          ),
        ),
      ),
      onWillPop: () async => false,
    );
  }

  Future<void> toggleMute(BuildContext context) async {
    OmicallClient().toggleMicrophone();
  }

  Future<void> toggleSpeaker(BuildContext context) async {
    setState(() {
      _isMic = !_isMic;
    });
    OmicallClient().toggleSpeaker(_isMic);
  }

  Future<void> endCall(BuildContext context) async {
    OmicallClient().endCall();
    Navigator.pop(context, true);
  }

  transformMilliSeconds(int milliseconds) {
    int hundreds = (milliseconds / 10).truncate();
    int seconds = (hundreds / 100).truncate();
    int minutes = (seconds / 60).truncate();
    int hours = (minutes / 60).truncate();

    String hoursStr = (hours % 60).toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');

    return "$hoursStr:$minutesStr:$secondsStr";
  }

  _startWatch() {
    watch.start();
    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      _updateTime,
    );
  }

  _updateTime(Timer timer) {
    if (watch.isRunning) {
      setState(() {
        _callingStatus = transformMilliSeconds(watch.elapsedMilliseconds);
      });
    }
  }

  _onKeyboardTap(String value) {
    setState(() {
      message = "$message$value";
    });
    OmicallClient().sendDTMF(value);
  }

  @override
  void dispose() {
    super.dispose();
    watch.stop();
    timer?.cancel();
    timer = null;
  }
}
