part of 'dial_indirect_view.dart';

mixin DialInDirectViewModel implements State<DialInDirectView> {
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
  Map? _currentAudio;


  Future<void> initController() async {
    _callStatus = widget.status;
    debugPrint("status OmicallClient 00 ::: $_callStatus");
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
          debugPrint("status OmicallClient 00 ::: $status");
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
    OmicallClient.instance.setMuteListener((data) {
      setState(() {
        isMuted = data;
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

  Future<void> toggleMute(BuildContext context) async {
    OmicallClient.instance.toggleAudio();
  }

  Future<void> toggleSpeaker(BuildContext context) async {
    OmicallClient.instance.toggleSpeaker();
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
              iconSrc: !isMuted
                  ? 'assets/icons/ic_microphone.svg'
                  : 'assets/icons/ic_block_microphone.svg',
              text: "Microphone",
              press: () {
                toggleMute(context);
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