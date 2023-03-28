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
  String _callingStatus = '';
  String? _callTime;
  bool _isShowKeyboard = false;
  String _keyboardMessage = "";
  late StreamSubscription _subscription;

  Stopwatch watch = Stopwatch();
  Timer? timer;

  @override
  void initState() {
    _callingStatus = widget.status.value;
    if (widget.status == CallStatus.established) {
      _startWatch();
    }
    super.initState();
    _subscription =
        OmicallClient.instance.controller.eventTransferStream.listen((omiAction) {
      if (omiAction.actionName == OmiEventList.onCallEstablished) {
        updateDialScreen(null, CallStatus.established);
      }
      if (omiAction.actionName == OmiEventList.onCallEnd) {
        endCall(
          context,
          needShowStatus: true,
          needRequest: false,
        );
        return;
      }
    });
  }

  void updateDialScreen(Map<String, dynamic>? callInfo, CallStatus? status) {
    if (status == CallStatus.established) {
      _startWatch();
      setState(() {
        _callingStatus = status!.value;
      });
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
                      _callTime ?? _callingStatus,
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
                    if (_callingStatus == CallStatus.established.value) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StreamBuilder(
                            initialData: false,
                            stream: OmicallClient.instance.onMuteEvent(),
                            builder: (context, snapshot) {
                              final isMute = snapshot.data as bool;
                              return DialButton(
                                iconSrc: !isMute
                                    ? 'assets/icons/ic_microphone.svg'
                                    : 'assets/icons/ic_block_microphone.svg',
                                text: "Microphone",
                                press: () {
                                  toggleMute(context);
                                },
                              );
                            },
                          ),
                          StreamBuilder(
                            initialData: false,
                            stream: OmicallClient.instance.onMicEvent(),
                            builder: (context, snapshot) {
                              final isSpeaker = snapshot.data as bool;
                              return DialButton(
                                iconSrc: !isSpeaker
                                    ? 'assets/icons/ic_no_audio.svg'
                                    : 'assets/icons/ic_audio.svg',
                                text: "Audio",
                                press: () {
                                  toggleSpeaker(context);
                                },
                              );
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
                                _isShowKeyboard = !_isShowKeyboard;
                              });
                            },
                            color: Colors.white,
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
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (_callingStatus == "Ringing")
                          RoundedCircleButton(
                            iconSrc: "assets/icons/call_end.svg",
                            press: () {
                              OmicallClient.instance.joinCall();
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
                )
            ],
          ),
        ),
      ),
      onWillPop: () async => false,
    );
  }

  Future<void> toggleMute(BuildContext context) async {
    OmicallClient.instance.toggleAudio();
  }

  Future<void> toggleSpeaker(BuildContext context) async {
    OmicallClient.instance.toggleSpeaker();
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
      _stopWatch();
      setState(() {
        _callingStatus = CallStatus.end.value;
      });
      await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
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
      const Duration(seconds: 1),
      _updateTime,
    );
  }

  _updateTime(Timer timer) {
    if (watch.isRunning) {
      setState(() {
        _callTime = transformMilliSeconds(watch.elapsedMilliseconds);
      });
    }
  }

  _stopWatch() {
    watch.stop();
    timer?.cancel();
    timer = null;
  }

  _onKeyboardTap(String value) {
    setState(() {
      _keyboardMessage = "$_keyboardMessage$value";
    });
    OmicallClient.instance.sendDTMF(value);
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stopWatch();
    super.dispose();
  }
}
