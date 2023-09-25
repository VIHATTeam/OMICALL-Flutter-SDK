part of 'indirect_call_home_screen.dart';

mixin InDirectCallHomeViewModel implements State<InDirectCallHomeScreen> {
  late final TextEditingController _phoneNumberController =
      TextEditingController()..text = Platform.isAndroid ? '1000071' : '167631';

  TextStyle basicStyle = const TextStyle(
    color: Colors.white,
    fontSize: 16,
  );
  bool _isVideoCall = false;
  late StreamSubscription _subscription;
  GlobalKey<DialInDirectViewState>? _dialScreenKey;
  GlobalKey<VideoInDirectViewState>? _videoScreenKey;

  void initControllers() {
    // _isVideoCall = widget.isVideo;
    if (Platform.isAndroid) {
      checkAndPushToCall();
    }
    updateToken();
    OmicallClient.instance.getOutputAudios().then((value) {
      debugPrint("audios ${value.toString()}");
    });
    OmicallClient.instance.getCurrentUser().then((value) {
      debugPrint("user ${value.toString()}");
    });
    OmicallClient.instance.setMissedCallListener((data) {
      final String callerNumber = data["callerNumber"];
      final bool isVideo = data["isVideo"];
      makeCallWithParams(context, callerNumber, isVideo);
    });
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
      postData(jsonEncode(omiAction));
      debugPrint("omiAction  OmicallClient ::: $omiAction");
      if (omiAction.actionName != OmiEventList.onCallStateChanged) {
        return;
      }
      final data = omiAction.data;
      debugPrint("data  OmicallClient  zzz ::: $data");
      String statusString = '';
      final status = data["status"] as int;

      switch (status) {
        case 1:
          statusString = 'calling';
          break;
        case 2:
          statusString = 'incoming';
          break;
        case 3:
          statusString = 'early';
          break;
        case 4:
          statusString = 'connecting';
          break;
        case 5:
          statusString = 'confirmed';
          break;
        default:
          statusString = 'disconnect';
          break;
      }
      debugPrint("status  OmicallClient  zzz ::: $statusString");
      if (status == OmiCallState.incoming.rawValue ||
          status == OmiCallState.confirmed.rawValue ||
          status == OmiCallState.early.rawValue) {
        debugPrint("data  OmicallClient  zzz ::: $data");

        _isVideoCall = data['isVideo'] as bool;
        var callerNumber = "";
        // bool isVideo =false;

        if (_isVideoCall) {
          pushToVideoScreen(
            callerNumber,
            status: status,
            isOutGoingCall: false,
          );
        } else {
          pushToDialScreen(
            callerNumber,
            status: status,
            isOutGoingCall: false,
          );
        }
      }
      // if (status == OmiCallState.confirmed.rawValue) {
      //   if (_dialScreenKey?.currentState != null) {
      //     return;
      //   }
      //   if (_videoScreenKey?.currentState != null) {
      //     return;
      //   }
      //   final data = omiAction.data;
      //   final callerNumber = data["callerNumber"];
      //   _isVideoCall = data["isVideo"];
      //   if (_isVideoCall) {
      //     pushToVideoScreen(
      //       callerNumber,
      //       status: status,
      //       isOutGoingCall: false,
      //     );
      //     return;
      //   }
      //   pushToDialScreen(
      //     callerNumber ?? "",
      //     status: status,
      //     isOutGoingCall: false,
      //   );
      // }
      if (status == OmiCallState.disconnected.rawValue) {
        debugPrint(data.toString());
      }
    });
    // checkSystemAlertPermission();
    OmicallClient.instance.setCallLogListener((data) {
      final callerNumber = data["callerNumber"];
      _isVideoCall = data["isVideo"];
      makeCallWithParams(
        context,
        callerNumber,
        _isVideoCall,
      );
    });
  }

  Future<void> checkAndPushToCall() async {
    final call = await OmicallClient.instance.getInitialCall();
    if (call is Map) {
      final isVideo = call["isVideo"] as bool;
      final callerNumber = call["callerNumber"];
      if (isVideo) {
        pushToVideoScreen(
          callerNumber,
          status: OmiCallState.confirmed.rawValue,
          isOutGoingCall: false,
        );
      } else {
        pushToDialScreen(
          callerNumber,
          status: OmiCallState.confirmed.rawValue,
          isOutGoingCall: false,
        );
      }
    }
  }

  Future<void> checkSystemAlertPermission() async {
    if (Platform.isAndroid) {
      final systemAlertWindowStatus = await Permission.systemAlertWindow.status;
      if (!systemAlertWindowStatus.isGranted) {
        Permission.systemAlertWindow.request();
      }
    }
  }

  void disposeControllers() {
    _subscription.cancel();
    _phoneNumberController.dispose();
  }

  void pushToVideoScreen(
    String phoneNumber, {
    required int status,
    required bool isOutGoingCall,
  }) {
    if (_videoScreenKey != null) {
      return;
    }
    //_videoScreenKey = GlobalKey();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return VideoInDirectView(
        key: _videoScreenKey,
        status: status,
        isOutGoingCall: isOutGoingCall,
      );
    })).then((value) {
      _videoScreenKey = null;
    });
  }

  void pushToDialScreen(
    String phoneNumber, {
    required int status,
    required bool isOutGoingCall,
  }) {
    if (_dialScreenKey != null) {
      return;
    }
    //_dialScreenKey = GlobalKey();
    print("Pussh to screen");
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return DialInDirectView(
        key: _dialScreenKey,
        phoneNumber: phoneNumber,
        status: status,
        isOutGoingCall: isOutGoingCall,
      );
    })).then((value) {
      _dialScreenKey = null;
    });
  }

  void postData(String param) async {
    try {
      final response = await http.post(
        Uri.parse('https://enx490iha5mem.x.pipedream.net'),
        headers: {"Content-Type": "application/json"},
        body: param, // Your JSON data here
      );

      // if (response.statusCode == 200) {
      //   setState(() {
      //     responseText = "POST request successful: ${response.body}";
      //   });
      // } else {
      //   setState(() {
      //     responseText = "POST request failed with status: ${response.statusCode}";
      //   });
      // }
    } catch (e) {
      // setState(() {
      //   responseText = "An error occurred: $e";
      // });
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
      _isVideoCall,
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
      callStatus = true;
    }

    if (callStatus) {
      if (_isVideoCall) {
        pushToVideoScreen(
          phone,
          status: OmiCallState.calling.rawValue,
          isOutGoingCall: true,
        );
      } else {
        pushToDialScreen(
          phone,
          status: OmiCallState.calling.rawValue,
          isOutGoingCall: true,
        );
      }
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

  Future<void> makeCallWithParams(
    BuildContext context,
    String callerNumber,
    bool isVideo,
  ) async {
    if (isVideo) {
      pushToVideoScreen(
        callerNumber,
        status: OmiCallState.calling.rawValue,
        isOutGoingCall: true,
      );
    } else {
      pushToDialScreen(
        callerNumber,
        status: OmiCallState.calling.rawValue,
        isOutGoingCall: true,
      );
    }
    OmicallClient.instance.startCall(
      callerNumber,
      isVideo,
    );
  }
}
