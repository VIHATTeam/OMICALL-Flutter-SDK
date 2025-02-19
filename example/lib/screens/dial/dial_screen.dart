// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:calling/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../components/dial_button.dart';
import '../../components/dial_user_pic.dart';
import '../../components/rounded_button.dart';
import '../../numeric_keyboard/numeric_keyboard.dart';
import '../home/home_screen.dart';

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
  bool isHold = false;
  Map? _currentAudio;

  @override
  void initState() {
    initController();
    super.initState();
  }

  Future<void> initController() async {
    _callStatus = widget.status;
    debugPrint("status OmicallClient 33 ::: $_callStatus");
    if (widget.status == OmiCallState.confirmed.rawValue) {
      _startWatch();
    }

    /// Todo: check pop page more time
    int i = 0;
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
      debugPrint(
          "status callStateChangeEvent omiAction::: ${omiAction.actionName}");
      debugPrint("status callStateChangeEvent omiAction::: ${omiAction.data}");
      if (omiAction.actionName == OmiEventList.onSwitchboardAnswer) {
        getGuestUser();
      }
      if (omiAction.actionName != OmiEventList.onCallStateChanged) return;

      final data = omiAction.data;
      final status = data["status"] as int;

      updateDialScreen(status);
      debugPrint("status OmicallClient DiaScreen =====> ::: $status");
      if (status == OmiCallState.disconnected.rawValue) {
        i++;
        if (i >= 2) return;
        endCall(
          needShowStatus: true,
          needRequest: false,
        );

        // return;
      }
    });
    await getCurrentUser();
    await getGuestUser();
    OmicallClient.instance.setAudioChangedListener((newAudio) {
      setState(() {
        _currentAudio = newAudio.first;
      });
    });
    OmicallClient.instance.getCurrentAudio().then((value) {
      setState(() {
        _currentAudio = value?.first;
      });
    });
    OmicallClient.instance.setCallQualityListener((data) {
      debugPrint("quality setCallQualityListener  ===> ::: $data");
      final quality = data["quality"] as int;
      final numLcn = data["stat"]["lcn"] as int;
      final isShowLoading = data["isNeedLoading"] as bool;
      debugPrint("quality numLcn  ===> ::: $isShowLoading --- $numLcn ");
    
      if(isShowLoading){
        EasyLoading.show();
      } else {
        EasyLoading.dismiss();
      }


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

    OmicallClient.instance.setHoldListener((data){
      print("hold data listener ---> $data");
      setState(() {
        isHold = data;
      });
    });
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

  String get _audioTitle {
    final name = _currentAudio!["name"] as String;
    if (name == "Receiver") {
      return Platform.isAndroid ? "Android" : "iPhone";
    }
    return name;
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
              if (Platform.isIOS) {
                name = "iPhone";
              } else {
                name = "Android";
              }
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
        final speaker =
            audioList.firstWhere((element) => element["name"] == "Receiver");
        OmicallClient.instance.setOutputAudio(portType: speaker["type"]);
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _stopWatch();
    OmicallClient.instance.removeCallQualityListener();
    OmicallClient.instance.removeMuteListener();
    OmicallClient.instance.removeHoldListener();
    OmicallClient.instance.removeAudioChangedListener();
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
    debugPrint("status _callStatus omiAction::: $_callStatus");
    if (status == OmiCallState.confirmed.rawValue ||
        status == OmiCallState.connecting.rawValue) {
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

    bool checkShowOption = _callStatus == OmiCallState.early.rawValue ||
        _callStatus == OmiCallState.connecting.rawValue ||
        _callStatus == OmiCallState.confirmed.rawValue ||  _callStatus == OmiCallState.hold.rawValue;
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
                  if (_callStatus == OmiCallState.confirmed.rawValue || _callStatus == OmiCallState.hold.rawValue)
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
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 150,
                      bottom: 20,
                    ),
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
                                  "${guestUser?["represent_name"] ?? guestUser?["extension"] ?? "${widget.phoneNumber}"}",
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
                            height: MediaQuery.of(context).size.height * 0.33,
                          )
                        else if (_callStatus != OmiCallState.confirmed.rawValue)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.1,
                          )
                        else
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.09,
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

  Future<void> toggleMute(BuildContext context) async {
    OmicallClient.instance.toggleAudio();
  }

  Future<void> toggleSpeaker(BuildContext context) async {
    OmicallClient.instance.toggleSpeaker();
  }

  Future<void> toggleHold(BuildContext context) async {
    OmicallClient.instance.toggleHold();
  }


  Future<void> endCall({
    bool needRequest = true,
    bool needShowStatus = true,
  }) async {
    if (needRequest) {
      OmicallClient.instance.endCall().then((value) {});
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

  List<Widget> callOtherOptionWidget(bool checkShowOption) {
    if (checkShowOption) {
      return [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            DialButton(
              iconSrc: !isHold
                  ? 'assets/icons/ic_microphone.svg'
                  : 'assets/icons/ic_block_microphone.svg',
              text: "Microphone",
              press: () {
                // toggleMute(context);
                toggleHold(context);
              },
            ),
            if (_currentAudio != null)
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
                  _isShowKeyboard = !_isShowKeyboard;
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
      ];
    } else {
      return [];
    }
  }
}
