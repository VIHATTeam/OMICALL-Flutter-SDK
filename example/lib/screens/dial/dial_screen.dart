import 'dart:async';

import 'package:calling/constants.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../components/dial_user_pic.dart';
import '../../components/rounded_button.dart';
import '../../numeric_keyboard/numeric_keyboard.dart';
import '../home/home_screen.dart';
import 'widgets/dial_button.dart';

class DialScreen extends StatefulWidget {
  const DialScreen({
    Key? key,
    this.phoneNumber,
    required this.status,
    required this.isOutGoingCall,
  }) : super(key: key);

  final String? phoneNumber;
  final int status;
  final bool isOutGoingCall;

  @override
  State<DialScreen> createState() => DialScreenState();
}

class DialScreenState extends State<DialScreen> {
  int _callStatus = 0;
  String? _callTime;
  bool _isShowKeyboard = false;
  String _keyboardMessage = "";
  late StreamSubscription _subscription;
  Map? current;
  Map? guestUser;
  Stopwatch watch = Stopwatch();
  Timer? timer;
  String _callQuality = "";
  bool isMuted = false;
  bool isSpeaker = false;

  @override
  void initState() {
    _callStatus = widget.status;
    if (widget.status == OmiCallState.confirmed.rawValue) {
      _startWatch();
    }
    super.initState();
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
      if (omiAction.actionName == OmiEventList.onCallStateChanged) {
        final data = omiAction.data;
        final status = data["status"] as int;
        updateDialScreen(status);
        if (status == OmiCallState.disconnected.rawValue) {
          endCall(
            context,
            needShowStatus: true,
            needRequest: false,
          );
          return;
        }
      }
      if (omiAction.actionName == OmiEventList.onSwitchboardAnswer) {
        // final data = omiAction.data;
        // final sip = data["sip"];
        //switchboard sip => use get profile
        // OmicallClient.instance.getUserInfo(phone: sip);
        getGuestUser();
      }
    });
    getCurrentUser();
    getGuestUser();
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
    OmicallClient.instance.setMuteListener((data) {
      setState(() {
        isMuted = data;
      });
    });
    OmicallClient.instance.setSpeakerListener((data) {
      setState(() {
        isSpeaker = data;
      });
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stopWatch();
    OmicallClient.instance.removeCallQualityListener();
    OmicallClient.instance.removeMuteListener();
    OmicallClient.instance.removeSpeakerListener();
    super.dispose();
  }

  Future<void> getCurrentUser() async {
    final user = await OmicallClient.instance.getCurrentUser();
    if (user != null) {
      setState(() {
        current = user;
      });
    }
  }

  Future<void> getGuestUser() async {
    final user = await OmicallClient.instance.getGuestUser();
    if (user != null) {
      setState(() {
        guestUser = user;
      });
    }
  }

  void updateDialScreen(int status) {
    setState(() {
      _callStatus = status;
    });
    if (status == OmiCallState.confirmed.rawValue) {
      _startWatch();
    }
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text(
                              "${current?["extension"] ?? "..."}",
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium!
                                  .copyWith(color: Colors.white, fontSize: 24),
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
                                  .copyWith(color: Colors.white, fontSize: 24),
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
                          color: Colors.white60,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (_callStatus == OmiCallState.confirmed.rawValue) ...[
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
                          DialButton(
                            iconSrc: !isSpeaker
                                ? 'assets/icons/ic_no_audio.svg'
                                : 'assets/icons/ic_audio.svg',
                            text: "Audio",
                            press: () {
                              toggleSpeaker(context);
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
                        if ((_callStatus == OmiCallState.early.rawValue || _callStatus == OmiCallState.incoming.rawValue) && widget.isOutGoingCall == false)
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
                        if (_callStatus > OmiCallState.calling.rawValue)
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
                ),
              Positioned(
                top: 10,
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
      OmicallClient.instance.endCall().then((value) {
        debugPrint("End calllllll");
        debugPrint(value.toString());
      });
    }
    if (needShowStatus) {
      _stopWatch();
      updateDialScreen(OmiCallState.disconnected.rawValue);
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
}