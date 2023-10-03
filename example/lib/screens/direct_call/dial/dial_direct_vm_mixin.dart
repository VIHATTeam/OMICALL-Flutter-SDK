part of 'dial_direct_view.dart';

mixin DialDirectViewModel implements State<DialDirectView> {
  String guestNumber = '';
  bool isOutGoingCall = false;
  int callStatus = OmiCallState.unknown.rawValue;
  String? callTime;
  bool isShowKeyboard = false;
  String keyboardMessage = "";
  late StreamSubscription _subscription;
  Map? currentUser;
  Map? guestUser;
  Stopwatch watch = Stopwatch();
  Timer? timer;
  String callQuality = "";
  bool isMuted = false;
  Map? currentAudio;
  TextEditingController phoneNumberController = TextEditingController();

  /// Todo: check pop page more time
  int i = 0;
  Future<void> initializeControllers(int status) async {
    if (Platform.isAndroid) {
      /// Todo:(NOTE) Check có cuộc gọi, nếu có sẽ auto show màn hình cuộc gọi
      await checkAndPushToCall();
    }
    await updateToken();
    OmicallClient.instance.getOutputAudios().then((value) {
      debugPrint("audios ${value.toString()}");
    });
    OmicallClient.instance.getCurrentUser().then((value) {
      debugPrint("user ${value.toString()}");
    });
    if (status == OmiCallState.incoming.rawValue ||
        status == OmiCallState.confirmed.rawValue) {
      //guestNumber = data["callerNumber"];
      //isVideo = data['isVideo'] as bool;
      // guestNumber = data["callerNumber"];
      //isOutGoingCall = false;
      debugPrint("==============================");
      debugPrint("isOutGoingCall OmicallClient ::: $isOutGoingCall");
      updateScreen(status);
    }

    /// Todo:(NOTE) Đặt trình nghe cuộc gọi nhỡ nếu có thì start call luôn
    OmicallClient.instance.setMissedCallListener((data) async {
      await getGuestUser();
      guestNumber = data["callerNumber"];

      /// isVideo = data["isVideo"];
      await makeCallWithParams(guestNumber, false);
    });
    debugPrint("status _callStatus omiAction::: $callStatus");

    /// Todo:(NOTE) Lắng nghe các sự kiện trạng thái thay đổi
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) async {
      await getGuestUser();
      debugPrint("omiAction  OmicallClient ::: $omiAction");
      if (omiAction.actionName == OmiEventList.onSwitchboardAnswer) {
        await getGuestUser();
      }
      if (omiAction.actionName == OmiEventList.onCallStateChanged) {
        final data = omiAction.data;
        final status = data["status"] as int;
        //if (callStatus == status) return;

        debugPrint("status OmicallClient 11 ::: $status");
        debugPrint("isOutGoingCall OmicallClient ::: $isOutGoingCall");

        // if(data.keys.contains("isVideo")){
        final isVideo = data["isVideo"] ?? false;
        if (isVideo && status == OmiCallState.early.rawValue) {
          await checkAndPushToCallVideo();
        }
        if (status == OmiCallState.incoming.rawValue ||
            status == OmiCallState.confirmed.rawValue) {
          guestNumber = data["callerNumber"];
          //isVideo = data['isVideo'] as bool;
          // guestNumber = data["callerNumber"];
          //isOutGoingCall = false;
          debugPrint("==============================");
          debugPrint("isOutGoingCall OmicallClient ::: $isOutGoingCall");
          updateScreen(status);
        }

        if (status == OmiCallState.disconnected.rawValue) {

          await endCall(
            needShowStatus: true,
            needRequest: true,
          );
          return;
        }
        updateScreen(status);
      }

    });
    await getCurrentUser();
    OmicallClient.instance.setAudioChangedListener((newAudio) {
      setState(() {
        currentAudio = newAudio.first;
      });
    });
    await OmicallClient.instance.getCurrentAudio().then((value) {
      setState(() {
        currentAudio = value?.first;
      });
    });
    OmicallClient.instance.setCallQualityListener((data) {
      final quality = data["quality"] as int;
      setState(() {
        if (quality == 0) {
          callQuality = "GOOD";
        }
        if (quality == 1) {
          callQuality = "NORMAL";
        }
        if (quality == 2) {
          callQuality = "BAD";
        }
      });
    });
    OmicallClient.instance.setMuteListener((data) {
      setState(() {
        isMuted = data;
      });
    });

    /// Todo:(NOTE) Chỉ là Log không ảnh hưởng tới luồng cuộc gọi
    OmicallClient.instance.setCallLogListener((data) {
      final callerNumber = data["callerNumber"];
      // isVideo = data["isVideo"];
      makeCallWithParams(
        callerNumber,
        false,
      );
    });
  }

  Future<void> checkAndPushToCallVideo() async {
    Navigator.pop(context);
    await Future.delayed(const Duration(milliseconds: 200)).then((value) async {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) {
            return DirectCallScreen(
              isVideo: true,
              status: callStatus,

              /// User gọi ra ngoài
              isOutGoingCall: false,
            );
          },
        ),
      );
    });
  }

  Future<void> checkAndPushToCall() async {
    final call = await OmicallClient.instance.getInitialCall();
    if (call is Map) {
      setState(() {
        //isVideo = call["isVideo"] as bool;
        guestNumber = call["callerNumber"];
        callStatus = OmiCallState.confirmed.rawValue;
        isOutGoingCall = false;
      });
      //   if (isVideo) {
      //     await Navigator.push(context, MaterialPageRoute(builder: (_) {
      //       return VideoCallScreen(
      //         status: _callStatus,
      //         isOutGoingCall: _isOutGoingCall,
      //         isTypeDirectCall: true,
      //       );
      //     }));
      //   }
      // }
    }
  }

  Future<void> makeCallWithParams(
    String callerNumber,
    bool isVideo,
  ) async {
    callStatus = OmiCallState.calling.rawValue;
    isOutGoingCall = true;

    OmicallClient.instance.startCall(
      callerNumber,
      isVideo,
    );
  }

  Future<void> getCurrentUser() async {
    final user = await OmicallClient.instance.getCurrentUser();
    if (user != null) {
      setState(() {
        currentUser = user;
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

  void updateScreen(int status) {
    setState(() {
      callStatus = status;
      if (status == OmiCallState.incoming.rawValue) {
        isOutGoingCall = false;
      }
    });
    debugPrint("status OmicallClient 22 ::: $status");
    if (status == OmiCallState.confirmed.rawValue) {
      _startWatch();
    } else if (status == OmiCallState.disconnected.rawValue) {
      _stopWatch();
    }
  }

  Future<void> makeCall() async {
    final phone = phoneNumberController.text;
    if (phone.isEmpty) {
      return;
    }
    EasyLoading.show();

    final result = await OmicallClient.instance.startCall(
      phone,
      false
    );

    // final result = await OmicallClient.instance.joinCall();

    debugPrint("result  joinCall  zzz ::: $result");
    await getGuestUser();
    EasyLoading.dismiss();
    Map<String, dynamic> jsonMap = {};
    bool startCallSuccess = false;
    String messageError = "";
    debugPrint("result  OmicallClient  zzz ::: $result");

    jsonMap = json.decode(result);
    messageError = jsonMap['message'] ?? "";
    int status = jsonMap['status'] ?? -1;
    if (status == OmiStartCallStatus.startCallSuccess.rawValue) {
      startCallSuccess = true;
    }

    if (startCallSuccess) {
      setState(() {
        callStatus = OmiCallState.calling.rawValue;
        isOutGoingCall = true;
      });
    } else {
      EasyDialog(
        title: const Text("Notification"),
        description: Text("Error code ${messageError}"),
      ).show(context);
    }
    // OmicallClient.instance.startCallWithUUID(
    //   phone,
    //   _isVideoCall,
    // );
  }

  Future<void> endCall({
    bool needRequest = true,
    bool needShowStatus = true,
  }) async {
    if (needRequest) {
      print("endCall:...");

     var result  = await OmicallClient.instance.endCall();
      print("endCall:... $result");

    }
    if (needShowStatus) {
      _stopWatch();
      updateScreen(OmiCallState.disconnected.rawValue);
      //await Future.delayed(const Duration(milliseconds: 400));
    }
    if (!mounted) {
      return;
    }

    setState(() {
      callStatus = OmiCallState.unknown.rawValue;
      guestUser = {};
      callTime = null;
      //phoneNumberController.clear();
    });
    //Navigator.pop(context);
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
        callTime = transformMilliSeconds(watch.elapsedMilliseconds);
      });
    }
  }

  _stopWatch() {
    watch.stop();
    timer?.cancel();
    timer = null;
    watch.reset();
  }

  _onKeyboardTap(String value) {
    setState(() {
      keyboardMessage = "$keyboardMessage$value";
    });
    OmicallClient.instance.sendDTMF(value);
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
      if (currentAudio!["name"] == "Receiver") {
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

  String get _audioImage {
    final name = currentAudio!["name"] as String;
    if (name == "Receiver") {
      return "ic_iphone";
    }
    if (name == "Speaker") {
      return "ic_speaker";
    }
    return "ic_airpod";
  }

  String get _audioTitle {
    final name = currentAudio!["name"] as String;
    if (name == "Receiver") {
      return Platform.isAndroid ? "Android" : "IOS";
    }
    return name;
  }

  Future<void> toggleMute(BuildContext context) async {
    OmicallClient.instance.toggleAudio();
  }

  Future<void> toggleSpeaker(BuildContext context) async {
    OmicallClient.instance.toggleSpeaker();
  }
}
