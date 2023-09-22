part of 'video_direct_view.dart';

mixin VideoDirectViewModel implements State<VideoDirectView> {
  RemoteCameraController? _remoteController;
  LocalCameraController? _localController;
  late StreamSubscription _subscription;
  int _callStatus = 0;
  bool isMuted = false;
  Map? _currentAudio;
  String _callQuality = "";
  TextEditingController _phoneNumberController = TextEditingController();
  Map? guestUser;
  bool _isOutGoingCall = false;
  int i = 0;

  Future<void> initializeControllers() async {
    OmicallClient.instance.registerVideoEvent();
    _isOutGoingCall = widget.isOutGoingCall;
    await getGuestUser();
    OmicallClient.instance.setMissedCallListener((data) async {
      await getGuestUser();
      final String callerNumber = data["callerNumber"];

      await makeCallWithParams(callerNumber, true);
    });
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) async {
      if (omiAction.actionName == OmiEventList.onCallStateChanged) {
        final data = omiAction.data;
        _callStatus = data["status"] as int;
        debugPrint("status OmicallClient 00 ::: $_callStatus");
        // final isVideo = data["isVideo"] ?? false;
        // if (!isVideo && _callStatus == OmiCallState.early.rawValue) {
        //   await checkAndPushToCallDial();
        // }
        // if (data.keys.contains("isVideo")) {
        //   _isVideo = data["isVideo"] ?? false;
        // }

        updateVideoScreen(_callStatus);
        if (_callStatus == OmiCallState.incoming.rawValue ||
            _callStatus == OmiCallState.confirmed.rawValue) {
          _isOutGoingCall = false;
          // setState(() {});
        }

        if (_callStatus == OmiCallState.confirmed.rawValue) {
          if (Platform.isAndroid) {
            refreshRemoteCamera();
            refreshLocalCamera();
          }
        }

        if (_callStatus == OmiCallState.disconnected.rawValue) {
          // i++;
          // if (i >= 2) return;

          await endCall(
            needShowStatus: true,
            needRequest: true,
          );

          return;
        }
        print('_isOutGoingCall: $_isOutGoingCall');
      }
    });

    OmicallClient.instance.setVideoListener((data) {
      refreshRemoteCamera();
      refreshLocalCamera();
    });
    OmicallClient.instance.setMuteListener((p0) {
      setState(() {
        isMuted = p0;
      });
    });
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
  }

  // Future<void> checkAndPushToCallDial() async {
  //   Navigator.pop(context);
  //   await Future.delayed(const Duration(milliseconds: 200)).then((value) async {
  //     await Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (_) {
  //           return DirectCallScreen(
  //             isVideo: false,
  //             status: OmiCallState.incoming.rawValue,

  //             /// User gọi ra ngoài
  //             isOutGoingCall: false,
  //           );
  //         },
  //       ),
  //     );
  //   });
  // }

  Future<void> getGuestUser() async {
    final user = await OmicallClient.instance.getGuestUser();
    if (user != null) {
      setState(() {
        guestUser = user;
      });
    }
  }

  Future<void> makeCall(BuildContext context) async {
    final phone = _phoneNumberController.text;
    if (phone.isEmpty) {
      return;
    }
    EasyLoading.show();
    final result = await OmicallClient.instance.startCall(
      phone,
      true,
    );
    await getGuestUser();
    EasyLoading.dismiss();
    Map<String, dynamic> jsonMap = {};
    bool startCallSuccess = false;
    String messageError = "";
    debugPrint("result  OmicallClient  zzz ::: $result");

    jsonMap = json.decode(result);
    messageError = jsonMap['message'];
    int status = jsonMap['status'];
    if (status == OmiStartCallStatus.startCallSuccess.rawValue) {
      startCallSuccess = true;
    }

    if (startCallSuccess) {
      setState(() {
        _callStatus = OmiCallState.calling.rawValue;
        _isOutGoingCall = true;
      });
    } else {
      EasyDialog(
        title: const Text("Notification"),
        description: Text("Error code ${messageError}"),
      ).show(context);
    }
    // if (status == OmiStartCallStatus.startCallSuccess.rawValue) {
    //   setState(() {
    //     callStatus = true;
    //     _isOutGoingCall = true;
    //   });
    // }
    //
    // if (!callStatus) {
    //   EasyDialog(
    //     title: Text("Notification"),
    //     description: Text("Error code ${messageError}"),
    //   ).show(context);
    // }
    // OmicallClient.instance.startCallWithUUID(
    //   phone,
    //   _isVideoCall,
    // );
  }

  Future<void> makeCallWithParams(
    String callerNumber,
    bool isVideo,
  ) async {
    _callStatus = OmiCallState.calling.rawValue;

    OmicallClient.instance.startCall(
      callerNumber,
      isVideo,
    );
  }

  void updateVideoScreen(int status) {
    setState(() {
      _callStatus = status;
    });
  }

  Future<void> endCall({
    bool needRequest = true,
    bool needShowStatus = true,
  }) async {
    if (needRequest) {
      await OmicallClient.instance.endCall();
    }
    if (needShowStatus) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (!mounted) {
      return;
    }

    // if (i > 1) {
    //   i = 0;
    // }
    setState(() {
      _callStatus = OmiCallState.unknown.rawValue;
      guestUser = {};
      _phoneNumberController.clear();
    });
  }

  void refreshRemoteCamera() {
    _remoteController?.refresh();
  }

  void refreshLocalCamera() {
    _localController?.refresh();
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
              name = "iPhone";
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
        final receiver =
            audioList.firstWhere((element) => element["name"] == "Receiver");
        OmicallClient.instance.setOutputAudio(portType: receiver["type"]);
      }
    }
  }
}
