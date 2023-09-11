part of 'indirect_call_screen.dart';
//
mixin IndirectCallViewModel implements State<IndirectCallScreen> {}
//   bool isVideo = false;
//   String guestNumber = '';
//   bool isOutGoingCall = false;
//   int callStatus = OmiCallState.unknown.rawValue;
//   String? callTime;
//   bool isShowKeyboard = false;
//   String keyboardMessage = "";
//   late StreamSubscription _subscription;
//   Map? currentUser;
//   Map? guestUser;
//   Stopwatch watch = Stopwatch();
//   Timer? timer;
//   String callQuality = "";
//   bool isMuted = false;
//   Map? currentAudio;
//   TextEditingController phoneNumberController = TextEditingController();
//
//   @override
//   void dispose() {
//     _subscription.cancel();
//     stopWatch();
//     phoneNumberController.dispose();
//     OmicallClient.instance.removeCallQualityListener();
//     OmicallClient.instance.removeMuteListener();
//     OmicallClient.instance.removeAudioChangedListener();
//   }
//
//   @override
//   void initState() {
//     // TODO: implement initState
//     isVideo = widget.isVideo;
//     callStatus = widget.status;
//     isOutGoingCall = widget.isOutGoingCall;
//     initializeControllers();
//   }
//
//   Future<void> initializeControllers() async {
//     if (Platform.isAndroid) {
//       /// Todo:(NOTE) Check có cuộc gọi, nếu có sẽ auto show màn hình cuộc gọi
//       await checkAndPushToCall();
//     }
//     await updateToken();
//     OmicallClient.instance.getOutputAudios().then((value) {
//       debugPrint("audios ${value.toString()}");
//     });
//     OmicallClient.instance.getCurrentUser().then((value) {
//       debugPrint("user ${value.toString()}");
//     });
//
//     /// Todo:(NOTE) Đặt trình nghe cuộc gọi nhỡ nếu có thì start call luôn
//     OmicallClient.instance.setMissedCallListener((data) async {
//       await getGuestUser();
//       guestNumber = data["callerNumber"];
//       isVideo = data["isVideo"];
//
//       await makeCallWithParams(guestNumber, isVideo);
//     });
//     debugPrint("status _callStatus omiAction::: $callStatus");
//
//     // Lắng nghe các sự kiện trạng thái thay đổi
//     _subscription =
//         OmicallClient.instance.callStateChangeEvent.listen((omiAction) async {
//       debugPrint("omiAction  OmicallClient ::: $omiAction");
//       if (omiAction.actionName != OmiEventList.onCallStateChanged) {
//         return;
//       }
//       final data = omiAction.data;
//       callStatus = data["status"] as int;
//
//       debugPrint("status OmicallClient ::: $callStatus");
//
//       // if(data.keys.contains("isVideo")){
//       //   _isVideo = data["isVideo"] ?? false;
//       // }
//
//       if (callStatus == OmiCallState.incoming.rawValue ||
//           callStatus == OmiCallState.confirmed.rawValue) {
//         await getGuestUser();
//         isVideo = data['isVideo'] as bool;
//         guestNumber = data["callerNumber"];
//         isOutGoingCall = false;
//       }
//       updateScreen(callStatus);
//       if (callStatus == OmiCallState.disconnected.rawValue) {
//         await endCall(
//           needShowStatus: true,
//           needRequest: false,
//         );
//         return;
//       }
//
//       if (omiAction.actionName == OmiEventList.onSwitchboardAnswer) {
//         await getGuestUser();
//       }
//     });
//     await getCurrentUser();
//     OmicallClient.instance.setAudioChangedListener((newAudio) {
//       setState(() {
//         currentAudio = newAudio.first;
//       });
//     });
//     await OmicallClient.instance.getCurrentAudio().then((value) {
//       setState(() {
//         currentAudio = value?.first;
//       });
//     });
//     OmicallClient.instance.setCallQualityListener((data) {
//       final quality = data["quality"] as int;
//       setState(() {
//         if (quality == 0) {
//           callQuality = "GOOD";
//         }
//         if (quality == 1) {
//           callQuality = "NORMAL";
//         }
//         if (quality == 2) {
//           callQuality = "BAD";
//         }
//       });
//     });
//     OmicallClient.instance.setMuteListener((data) {
//       setState(() {
//         isMuted = data;
//       });
//     });
//
//     /// Todo:(NOTE) Chỉ là Log không ảnh hưởng tới luồng cuộc gọi
//   OmicallClient.instance.setCallLogListener((data) {
//       final callerNumber = data["callerNumber"];
//       isVideo = data["isVideo"];
//       makeCallWithParams(
//         callerNumber,
//         isVideo,
//       );
//     });
//   }
//
//   Future<void> checkAndPushToCall() async {
//     final call = await OmicallClient.instance.getInitialCall();
//     if (call is Map) {
//       setState(() {
//         isVideo = call["isVideo"] as bool;
//         guestNumber = call["callerNumber"];
//         callStatus = OmiCallState.confirmed.rawValue;
//         isOutGoingCall = false;
//       });
//       //   if (isVideo) {
//       //     await Navigator.push(context, MaterialPageRoute(builder: (_) {
//       //       return VideoCallScreen(
//       //         status: _callStatus,
//       //         isOutGoingCall: _isOutGoingCall,
//       //         isTypeDirectCall: true,
//       //       );
//       //     }));
//       //   }
//       // }
//     }
//   }
//
//   Future<void> makeCallWithParams(
//     String callerNumber,
//     bool isVideo,
//   ) async {
//     callStatus = OmiCallState.calling.rawValue;
//     isOutGoingCall = true;
//
//     OmicallClient.instance.startCall(
//       callerNumber,
//       isVideo,
//     );
//   }
//
//   String get _audioImage {
//     final name = _currentAudio!["name"] as String;
//     if (name == "Receiver") {
//       return "ic_iphone";
//     }
//     if (name == "Speaker") {
//       return "ic_speaker";
//     }
//     return "ic_airpod";
//   }
//
//   String get _audioTitle {
//     final name = _currentAudio!["name"] as String;
//     if (name == "Receiver") {
//       return Platform.isAndroid ? "Android" : "iPhone";
//     }
//     return name;
//   }
//
//   Future<void> getCurrentUser() async {
//     final user = await OmicallClient.instance.getCurrentUser();
//     if (user != null) {
//       setState(() {
//         current = user;
//       });
//     }
//   }
//
//   Future<void> getGuestUser() async {
//     final user = await OmicallClient.instance.getGuestUser();
//     if (user != null) {
//       setState(() {
//         guestUser = user;
//       });
//     }
//   }
//
//   void updateScreen(int status) {
//     setState(() {
//       if (status == OmiCallState.confirmed.rawValue) {
//         _startWatch();
//       }
//     });
//   }
//
//   Future<void> toggleMute(BuildContext context) async {
//     OmicallClient.instance.toggleAudio();
//   }
//
//   Future<void> toggleSpeaker(BuildContext context) async {
//     OmicallClient.instance.toggleSpeaker();
//   }
//
//   Future<void> endCall({
//     bool needRequest = true,
//     bool needShowStatus = true,
//   }) async {
//     if (needRequest) {
//       OmicallClient.instance.endCall().then((value) {});
//     }
//     if (needShowStatus) {
//       _stopWatch();
//       updateDialScreen(OmiCallState.disconnected.rawValue);
//       await Future.delayed(const Duration(milliseconds: 400));
//     }
//     if (!mounted) {
//       return;
//     }
//     phoneNumberController.clear();
//     setState(() {
//       callStatus = OmiCallState.unknown.rawValue;
//       guestUser = {};
//       callTime = '';
//     });
//   }
//
//   transformMilliSeconds(int milliseconds) {
//     int hundreds = (milliseconds / 10).truncate();
//     int seconds = (hundreds / 100).truncate();
//     int minutes = (seconds / 60).truncate();
//     int hours = (minutes / 60).truncate();
//
//     String hoursStr = (hours % 60).toString().padLeft(2, '0');
//     String minutesStr = (minutes % 60).toString().padLeft(2, '0');
//     String secondsStr = (seconds % 60).toString().padLeft(2, '0');
//
//     return "$hoursStr:$minutesStr:$secondsStr";
//   }
//
//   _startWatch() {
//     watch.start();
//     timer = Timer.periodic(
//       const Duration(seconds: 1),
//       _updateTime,
//     );
//   }
//
//   _updateTime(Timer timer) {
//     if (watch.isRunning) {
//       setState(() {
//         _callTime = transformMilliSeconds(watch.elapsedMilliseconds);
//       });
//     }
//   }
//
//   _stopWatch() {
//     watch.stop();
//     timer?.cancel();
//     timer = null;
//   }
//
//   _onKeyboardTap(String value) {
//     setState(() {
//       _keyboardMessage = "$_keyboardMessage$value";
//     });
//     OmicallClient.instance.sendDTMF(value);
//   }
// }
