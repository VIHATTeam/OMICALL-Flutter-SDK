import 'dart:async';

import 'package:calling/components/dial_user_pic.dart';
import 'package:calling/components/rounded_button.dart';
import 'package:calling/constants.dart';
import 'package:calling/main.dart';
import 'package:calling/size_config.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/constant/enums.dart';
import 'package:omicall_flutter_plugin/model/action_list.dart';
import 'package:omicall_flutter_plugin/model/action_model.dart';
import '../../../numeric_keyboard/numeric_keyboard.dart';
import 'dial_button.dart';

class Body extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  bool _isMuted = false;
  bool _isMic = false;
  String _message = 'Connecting';
  bool _isShowKeyboard = false;
  String message = "";

  Stopwatch watch = Stopwatch();
  Timer? timer;

  @override
  void initState() {
    super.initState();
    omiChannel.listerEvent((action) {
      if (action.actionName == OmiEventList.onCallEstablished) {
        _setDuration();
      }
      if (action.actionName == OmiEventList.onCallEnd) {
        Navigator.pop(context);
      }
      if (action.actionName == OmiEventList.onMuted) {
        if (mounted) {
          setState(() {
            _isMuted = action.data["isMuted"] as bool;
          });
        }
      }
      if (action.actionName == OmiEventList.onRinging) {
        if (mounted) {
          setState(() {
            _message = "Ringing";
          });
        }
      }
    });
  }

  _onKeyboardTap(String value) {
    setState(() {
      message = "$message$value";
    });
    final action = ActionModel(
      actionName: OmiActionName.SEND_DTMF,
      data: {
        "character": value,
      },
    );
    omiChannel.action(action: action);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SizedBox.expand(),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Text(
                  ".........",
                  style: Theme.of(context)
                      .textTheme
                      .headline4!
                      .copyWith(color: Colors.white),
                ),
                Text(
                  _message,
                  style: TextStyle(color: Colors.white60),
                ),
                VerticalSpacing(),
                DialUserPic(image: "assets/images/calling_face.png"),
                Spacer(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
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
                VerticalSpacing(),
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
        ),
        if (_isShowKeyboard)
          Container(
            width: double.infinity,
            height: 350,
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
                        style: TextStyle(
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
                      child: Icon(
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
                    rightIcon: Text(
                      "*",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                      ),
                    ),
                    leftButtonFn: () {
                      _onKeyboardTap("*");
                    },
                    leftIcon: Text(
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
            color: Colors.white,
          )
      ],
    );
  }

  void _setDuration() {
    _startWatch();
  }

  Future<void> toggleMute(BuildContext context) async {
    final action = OmiAction.toggleMute();
    omiChannel.action(action: action);
  }

  Future<void> toggleSpeaker(BuildContext context) async {
    setState(() {
      _isMic = !_isMic;
    });
    final action = OmiAction.toggleSpeaker(_isMic);
    omiChannel.action(action: action);
  }

  Future<void> endCall(BuildContext context) async {
    final action = OmiAction.endCall();
    omiChannel.action(action: action);
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
    timer = new Timer.periodic(new Duration(milliseconds: 100), _updateTime);
  }

  //
  // _setTime() {
  //   var timeSoFar = watch.elapsedMilliseconds;
  //   setState(() {
  //     _duration = transformMilliSeconds(timeSoFar);
  //   });
  // }

  _updateTime(Timer timer) {
    if (watch.isRunning) {
      setState(() {
        _message = transformMilliSeconds(watch.elapsedMilliseconds);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    watch.stop();
    timer?.cancel();
    timer = null;
  }
}
