// ignore_for_file: use_build_context_synchronously

part of 'video_indirect_view.dart';

mixin VideoInDirectViewModel implements State<VideoInDirectView> {
  RemoteCameraController? _remoteController;
  LocalCameraController? _localController;
  late StreamSubscription _subscription;
  int _callStatus = 0;
  bool isMuted = false;
  Map? _currentAudio;
  String _callQuality = "";
  final TextEditingController _phoneNumberController = TextEditingController();
  Map? guestUser;
  bool _isOutGoingCall = false;

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

    EasyLoading.dismiss();
    Map<String, dynamic> jsonMap = {};
    bool callStatus = false;
    String messageError = "";
    debugPrint("result  OmicallClient  zzz ::: $result");

    jsonMap = json.decode(result);
    messageError = jsonMap['message'];
    int status = jsonMap['status'];
    if (status == OmiStartCallStatus.startCallSuccess.rawValue) {
      setState(() {
        callStatus = true;
        _isOutGoingCall = true;
      });
    }

    if (!callStatus) {
      EasyDialog(
        title: const Text("Notification"),
        description: Text("Error code $messageError"),
      ).show(context);
    }
    // OmicallClient.instance.startCallWithUUID(
    //   phone,
    //   _isVideoCall,
    // );
  }

  Future<void> makeCallWithParams(
    BuildContext context,
    String callerNumber,
    bool isVideo,
  ) async {
    _callStatus = OmiCallState.calling.rawValue;

    OmicallClient.instance.startCall(
      callerNumber,
      isVideo,
    );
  }

  int i = 0;

  Future<void> initializeControllers() async {
    OmicallClient.instance.registerVideoEvent();
    _isOutGoingCall = widget.isOutGoingCall;
    await getGuestUser();
    OmicallClient.instance.setMissedCallListener((data) async {
      await getGuestUser();
      final String callerNumber = data["callerNumber"];

      await makeCallWithParams(context, callerNumber, true);
    });
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) async {
      if (omiAction.actionName == OmiEventList.onCallStateChanged) {
        final data = omiAction.data;
        final status = data["status"] as int;
        debugPrint('============STATUS: $status');

        _callStatus = data["status"] as int;
        updateVideoScreen(status);
        if (status == OmiCallState.incoming.rawValue) {
          _isOutGoingCall = false;
          setState(() {});
        }

        if (status == OmiCallState.confirmed.rawValue) {
          if (Platform.isAndroid) {
            refreshRemoteCamera();
            refreshLocalCamera();
          }
        }

        if (status == OmiCallState.disconnected.rawValue) {
          i++;
          if (i >= 2) return;

          await endCall(
            needShowStatus: true,
            needRequest: true,
          );

          return;
        }
        debugPrint('_isOutGoingCall: $_isOutGoingCall');
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
    _callStatus = OmiCallState.unknown.rawValue;
    guestUser = {};
    _phoneNumberController.clear();
    if (i > 1) {
      i = 0;
    }
    setState(() {});

    Navigator.pop(context);
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
