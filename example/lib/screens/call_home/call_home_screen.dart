// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:calling/constants.dart';
import 'package:easy_dialog/easy_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../components/dial_button.dart';
import '../../components/dial_user_pic.dart';
import '../../components/rounded_button.dart';
import '../../main.dart';
import '../../numeric_keyboard/numeric_keyboard.dart';
import '../home/home_screen.dart';
import 'package:http/http.dart' as http;

import '../video_call/video_call_screen.dart';

// String statusToDescription(int status) {
//   if (status == OmiCallState.calling.rawValue) {
//     return "Đang kết nối tới cuộc gọi";
//   }
//   if (status == OmiCallState.connecting.rawValue) {
//     return "Đang kết nối";
//   }
//   if (status == OmiCallState.early.rawValue) {
//     return "Cuộc gọi đang đổ chuông";
//   }
//   if (status == OmiCallState.confirmed.rawValue) {
//     return "Cuộc gọi bắt đầu";
//   }
//   if (status == OmiCallState.disconnected.rawValue) {
//     return "Cuộc gọi kết thúc";
//   }
//   return "";
// }

class CallHomeScreen extends StatefulWidget {
  const CallHomeScreen({
    Key? key,
    this.phoneNumber,
    required this.status,
    required this.isOutGoingCall,
    required this.isVideo,
  }) : super(key: key);

  final String? phoneNumber;
  final bool isVideo;
  final int status;
  final bool isOutGoingCall;

  @override
  State<CallHomeScreen> createState() => CallHomeScreenState();
}

class CallHomeScreenState extends State<CallHomeScreen> {
  bool _isVideo = false;
  String callerNumber = '';

  bool _isOutGoingCall = false;
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
  TextEditingController _phoneNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isVideo = widget.isVideo;
    _callStatus = widget.status;
    _isOutGoingCall = widget.isOutGoingCall;
    initializeControllers();
  }

  Future<void> initializeControllers() async {
    if (Platform.isAndroid) {
      await checkAndPushToCall();
    }
    OmicallClient.instance.getOutputAudios().then((value) {
      debugPrint("audios ${value.toString()}");
    });
    OmicallClient.instance.getCurrentUser().then((value) {
      debugPrint("user ${value.toString()}");
    });

    // Đặt trình nghe cuộc gọi nhỡ nếu có thì start call luôn
    OmicallClient.instance.setMissedCallListener((data) async {
      await getGuestUser();
      final String callerNumber = data["callerNumber"];
      _isVideo = data["isVideo"];

      await makeCallWithParams(context, callerNumber, _isVideo);
    });
    debugPrint("status _callStatus omiAction::: $_callStatus");
    debugPrint("status _callStatus omiAction::: ${widget.status}");

    // Lắng nghe các sự kiện trạng thái thay đổi
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) async {
      // postData(jsonEncode(omiAction));
      debugPrint("omiAction  OmicallClient ::: $omiAction");
      if (omiAction.actionName != OmiEventList.onCallStateChanged) {
        return;
      }
      final data = omiAction.data;
      _callStatus = data["status"] as int;

      // debugPrint(
      //     "status callStateChangeEvent omiAction::: ${omiAction.actionName}");
      // debugPrint("status callStateChangeEvent omiAction::: $data");
      debugPrint("status OmicallClient ::: $_callStatus");
      if(data.keys.contains("isVideo")){
        _isVideo = data["isVideo"] ?? false;
      }

      if (_callStatus == OmiCallState.incoming.rawValue ||
          _callStatus == OmiCallState.confirmed.rawValue) {
        await getGuestUser();
        _isVideo = data['isVideo'] as bool;
        callerNumber = data["callerNumber"];

        _isOutGoingCall = false;
      }
      updateDialScreen(_callStatus);
      if (_callStatus == OmiCallState.disconnected.rawValue) {
        await endCall(
          context,
          needShowStatus: true,
          needRequest: false,
        );
        return;
      }

      if (omiAction.actionName == OmiEventList.onSwitchboardAnswer) {
        await getGuestUser();
      }
    });
    await getCurrentUser();
    OmicallClient.instance.setAudioChangedListener((newAudio) {
      setState(() {
        _currentAudio = newAudio.first;
      });
    });
    await OmicallClient.instance.getCurrentAudio().then((value) {
      setState(() {
        _currentAudio = value?.first;
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
    OmicallClient.instance.setCallLogListener((data) {
      final callerNumber = data["callerNumber"];
      _isVideo = data["isVideo"];
      makeCallWithParams(
        context,
        callerNumber,
        _isVideo,
      );
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

  Future<void> makeCall() async {
    final phone = _phoneNumberController.text;
    if (phone.isEmpty) {
      return;
    }
    EasyLoading.show();

    final result = await OmicallClient.instance.startCall(
      phone,
      _isVideo,
    );
    await getGuestUser();
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
    // OmicallClient.instance.startCallWithUUID(
    //   phone,
    //   _isVideoCall,
    // );
  }

  Future<void> checkAndPushToCall() async {
    final call = await OmicallClient.instance.getInitialCall();
    if (call is Map) {
      setState(() {
        _isVideo = call["isVideo"] as bool;
        callerNumber = call["callerNumber"];
        _callStatus = OmiCallState.confirmed.rawValue;
        _isOutGoingCall = false;
      });
      if (_isVideo) {
        await Navigator.push(context, MaterialPageRoute(builder: (_) {
          return VideoCallScreen(
            status: _callStatus,
            isOutGoingCall: _isOutGoingCall,
            isTypeDirectCall: true,
          );
        }));
      }
    }
  }

  Future<void> makeCallWithParams(
    BuildContext context,
    String callerNumber,
    bool isVideo,
  ) async {
    _callStatus = OmiCallState.calling.rawValue;
    _isOutGoingCall = true;

    OmicallClient.instance.startCall(
      callerNumber,
      isVideo,
    );
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
    _phoneNumberController.dispose();
    OmicallClient.instance.removeCallQualityListener();
    OmicallClient.instance.removeMuteListener();
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
      if (status == OmiCallState.confirmed.rawValue) {
        _startWatch();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWith = MediaQuery.of(context).size.width;
    var correctWidth = (screenWith - 20) / 4;
    if (correctWidth > 100) {
      correctWidth = 100;
    }
    OutlineInputBorder myInputBorder() {
      //return type is OutlineInputBorder
      return const OutlineInputBorder(
        //Outline border type for TextFeild
        borderRadius: BorderRadius.all(Radius.circular(20)),
        borderSide: BorderSide(
          color: Colors.redAccent,
          width: 3,
        ),
      );
    }

    OutlineInputBorder myFocusBorder() {
      return const OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(20),
        ),
        borderSide: BorderSide(
          color: Colors.greenAccent,
          width: 3,
        ),
      );
    }

    InputDecoration inputDecoration(
      String text,
      IconData? icon,
    ) {
      return InputDecoration(
        labelText: text,
        labelStyle: const TextStyle(
          color: Colors.grey,
        ),
        hintText: text,
        hintStyle: const TextStyle(
          color: Colors.grey,
        ),
        prefixIcon: Icon(
          icon,
          size: MediaQuery.of(context).size.width * 0.06,
          color: Colors.grey,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.01),
          ),
          borderSide: const BorderSide(
            color: Colors.red,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: BorderSide(
            color: Colors.red,
            width: MediaQuery.of(context).size.width * 0.01,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: const BorderSide(
            color: Colors.white,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(MediaQuery.of(context).size.width * 0.1),
          ),
          borderSide: BorderSide(
            color: const Color.fromARGB(255, 225, 121, 243),
            width: MediaQuery.of(context).size.width * 0.008,
          ),
        ),
      );
    }

    return _isVideo
        ? VideoCallScreen(
            status: _callStatus,
            isOutGoingCall: false,
            isTypeDirectCall: true,
          )
        : WillPopScope(
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
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 20, right: 20, top: 150),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Text(
                                        "${current?["extension"] ?? "..."}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .copyWith(
                                                color: Colors.grey,
                                                fontSize: 24),
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
                                        _phoneNumberController.text.isEmpty
                                            ? "..."
                                            : "${guestUser?["extension"] ?? "..."}",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium!
                                            .copyWith(
                                                color: Colors.grey,
                                                fontSize: 24),
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
                                height:
                                    MediaQuery.of(context).size.height * 0.05,
                              ),
                              if (_callStatus ==
                                  OmiCallState.confirmed.rawValue) ...[
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        iconSrc:
                                            'assets/images/$_audioImage.png',
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                              ],
                              if (_callStatus !=
                                  OmiCallState.confirmed.rawValue)
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.43,
                                )
                              else
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.19,
                                ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  if (_callStatus ==
                                      OmiCallState.unknown.rawValue)
                                    RoundedCircleButton(
                                      iconSrc: "assets/icons/call_end.svg",
                                      press: () async {
                                        if (_phoneNumberController
                                            .text.isNotEmpty) {
                                          makeCall();
                                        }
                                      },
                                      color:
                                          _phoneNumberController.text.isNotEmpty
                                              ? kGreenColor
                                              : kSecondaryColor,
                                      iconColor: Colors.white,
                                    ),
                                  if ((_callStatus ==
                                              OmiCallState.early.rawValue ||
                                          _callStatus ==
                                              OmiCallState.incoming.rawValue) &&
                                      _isOutGoingCall == false)
                                    RoundedCircleButton(
                                      iconSrc: "assets/icons/call_end.svg",
                                      press: () async {
                                        final result = await OmicallClient
                                            .instance
                                            .joinCall();
                                        if (result == false && mounted) {
                                          Navigator.pop(context);
                                        }
                                      },
                                      color: kGreenColor,
                                      iconColor: Colors.white,
                                    ),
                                  if (_callStatus >
                                      OmiCallState.unknown.rawValue)
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
                              ),
                            ],
                          ),
                        ),

                        // Positioned(
                        //   top: 10,
                        //   left: 12,
                        //   right: 12,
                        //   child: Text(
                        //     _callQuality,
                        //     textAlign: TextAlign.center,
                        //     style: const TextStyle(
                        //       color: Colors.white,
                        //       fontSize: 16,
                        //       fontWeight: FontWeight.w600,
                        //     ),
                        //   ),
                        // )
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 68),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            await endCall(
                              context,
                              needShowStatus: true,
                              needRequest: false,
                            );
                            Navigator.of(context).pop();
                          },
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.all(
                              Radius.circular(
                                  MediaQuery.of(context).size.width * 0.1),
                            ),
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              child: const Icon(
                                Icons.arrow_back,
                                size: 25,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Material(
                            elevation: 4,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width * 0.1),
                            child: TextFormField(
                              controller: _phoneNumberController,
                              keyboardType: TextInputType.phone,
                              decoration:
                                  inputDecoration('Phone Number', Icons.phone),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'This field cannot be empty';
                                }
                                return null;
                              },
                            ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Scaffold(
            //   backgroundColor: kBackgoundColor,
            //   appBar: AppBar(
            //     backgroundColor: kBackgoundColor,
            //     automaticallyImplyLeading: false,
            //     actions: [
            //       IconButton(
            //         onPressed: () async{
            //           await OmicallClient.instance.endCall();
            //           Navigator.pop(context);
            //         },
            //         icon: const Icon(Icons.logout),
            //       ),
            //     ],
            //     title: Container(
            //       alignment: Alignment.centerLeft,
            //       decoration: BoxDecoration(
            //         color: Colors.white,
            //         borderRadius: BorderRadius.circular(0),
            //       ),
            //       child: TextField(
            //         controller: _phoneNumberController,
            //         keyboardType: TextInputType.number,
            //         decoration: const InputDecoration(
            //           prefixIcon: Icon(Icons.phone),
            //           labelText: "Phone Number",
            //           // enabledBorder: myInputBorder(),
            //           // focusedBorder: myFocusBorder(),
            //         ),
            //         onSubmitted: (val) async {
            //           await getGuestUser();
            //         },
            //       ),
            //     ),
            //   ),
            //   body: SafeArea(
            //     child: SingleChildScrollView(
            //       child: Column(
            //         children: [
            //           Container(
            //             width: double.infinity,
            //             height: MediaQuery.of(context).size.height * 0.85,
            //             child: Stack(
            //               alignment: Alignment.bottomCenter,
            //               children: [
            //                 const SizedBox.expand(),
            //                 Padding(
            //                   padding: const EdgeInsets.all(20.0),
            //                   child: Column(
            //                     children: [
            //                       Row(
            //                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                         crossAxisAlignment: CrossAxisAlignment.center,
            //                         children: [
            //                           Column(
            //                             children: [
            //                               Text(
            //                                 "${current?["extension"] ?? "..."}",
            //                                 style: Theme.of(context)
            //                                     .textTheme
            //                                     .headlineMedium!
            //                                     .copyWith(
            //                                         color: Colors.white,
            //                                         fontSize: 24),
            //                               ),
            //                               const SizedBox(
            //                                 height: 16,
            //                               ),
            //                               DialUserPic(
            //                                 size: correctWidth,
            //                                 image: current?["avatar_url"] != "" &&
            //                                         current?["avatar_url"] != null
            //                                     ? current!["avatar_url"]
            //                                     : "assets/images/calling_face.png",
            //                               ),
            //                             ],
            //                           ),
            //                           const SizedBox(
            //                             width: 16,
            //                           ),
            //                           Column(
            //                             children: [
            //                               Text(
            //                                 _phoneNumberController.text.isEmpty
            //                                     ? "..."
            //                                     : "${guestUser?["extension"] ?? "..."}",
            //                                 style: Theme.of(context)
            //                                     .textTheme
            //                                     .headlineMedium!
            //                                     .copyWith(
            //                                         color: Colors.white,
            //                                         fontSize: 24),
            //                               ),
            //                               const SizedBox(
            //                                 height: 16,
            //                               ),
            //                               DialUserPic(
            //                                 size: correctWidth,
            //                                 image: guestUser?["avatar_url"] != "" &&
            //                                         guestUser?["avatar_url"] != null
            //                                     ? guestUser!["avatar_url"]
            //                                     : "assets/images/calling_face.png",
            //                               ),
            //                             ],
            //                           ),
            //                         ],
            //                       ),
            //                       Container(
            //                         margin: const EdgeInsets.only(top: 16),
            //                         child: Text(
            //                           _callTime ?? statusToDescription(_callStatus),
            //                           style: const TextStyle(
            //                             color: Colors.white60,
            //                             fontSize: 18,
            //                           ),
            //                         ),
            //                       ),
            //                       const Spacer(),
            //                       if (_callStatus ==
            //                           OmiCallState.confirmed.rawValue) ...[
            //                         Row(
            //                           mainAxisAlignment:
            //                               MainAxisAlignment.spaceBetween,
            //                           children: [
            //                             DialButton(
            //                               iconSrc: !isMuted
            //                                   ? 'assets/icons/ic_microphone.svg'
            //                                   : 'assets/icons/ic_block_microphone.svg',
            //                               text: "Microphone",
            //                               press: () {
            //                                 toggleMute(context);
            //                               },
            //                             ),
            //                             if (_currentAudio != null)
            //                               DialButton(
            //                                 iconSrc: 'assets/images/$_audioImage.png',
            //                                 text: _audioTitle,
            //                                 press: () {
            //                                   toggleAndCheckDevice();
            //                                 },
            //                               ),
            //                             DialButton(
            //                               iconSrc: "assets/icons/ic_video.svg",
            //                               text: "Video",
            //                               press: () {},
            //                               color: Colors.grey,
            //                             ),
            //                           ],
            //                         ),
            //                         const SizedBox(
            //                           height: 16,
            //                         ),
            //                         Row(
            //                           mainAxisAlignment:
            //                               MainAxisAlignment.spaceBetween,
            //                           children: [
            //                             DialButton(
            //                               iconSrc: "assets/icons/ic_message.svg",
            //                               text: "Message",
            //                               press: () {
            //                                 setState(() {
            //                                   _isShowKeyboard = !_isShowKeyboard;
            //                                 });
            //                               },
            //                               color: Colors.white,
            //                             ),
            //                             DialButton(
            //                               iconSrc: "assets/icons/ic_user.svg",
            //                               text: "Add contact",
            //                               press: () {},
            //                               color: Colors.grey,
            //                             ),
            //                             DialButton(
            //                               iconSrc: "assets/icons/ic_voicemail.svg",
            //                               text: "Voice mail",
            //                               press: () {},
            //                               color: Colors.grey,
            //                             ),
            //                           ],
            //                         ),
            //                       ],
            //                       const Spacer(),
            //                       Row(
            //                         mainAxisAlignment: MainAxisAlignment.spaceAround,
            //                         children: [
            //                           if (_callStatus ==
            //                               OmiCallState.unknown.rawValue)
            //                             RoundedCircleButton(
            //                               iconSrc: "assets/icons/call_end.svg",
            //                               press: () async {
            //                                 if (_phoneNumberController
            //                                     .text.isNotEmpty) {
            //                                   makeCall();
            //                                 }
            //                               },
            //                               color:
            //                                   _phoneNumberController.text.isNotEmpty
            //                                       ? kGreenColor
            //                                       : kSecondaryColor,
            //                               iconColor: Colors.white,
            //                             ),
            //                           if ((_callStatus ==
            //                                       OmiCallState.early.rawValue ||
            //                                   _callStatus ==
            //                                       OmiCallState.incoming.rawValue) &&
            //                               isOutGoingCall == false)
            //                             RoundedCircleButton(
            //                               iconSrc: "assets/icons/call_end.svg",
            //                               press: () async {
            //                                 final result = await OmicallClient
            //                                     .instance
            //                                     .joinCall();
            //                                 if (result == false && context.mounted) {
            //                                   Navigator.pop(context);
            //                                 }
            //                               },
            //                               color: kGreenColor,
            //                               iconColor: Colors.white,
            //                             ),
            //                           if (_callStatus > OmiCallState.unknown.rawValue)
            //                             RoundedCircleButton(
            //                               iconSrc: "assets/icons/call_end.svg",
            //                               press: () {
            //                                 endCall(
            //                                   context,
            //                                   needShowStatus: false,
            //                                 );
            //                               },
            //                               color: kRedColor,
            //                               iconColor: Colors.white,
            //                             ),
            //                         ],
            //                       )
            //                     ],
            //                   ),
            //                 ),
            //                 if (_isShowKeyboard)
            //                   Container(
            //                     width: double.infinity,
            //                     height: 350,
            //                     color: Colors.white,
            //                     child: Column(
            //                       children: [
            //                         const SizedBox(
            //                           height: 10,
            //                         ),
            //                         Row(
            //                           children: [
            //                             const SizedBox(
            //                               width: 54,
            //                             ),
            //                             Expanded(
            //                               child: Text(
            //                                 _keyboardMessage,
            //                                 style: const TextStyle(
            //                                   fontSize: 24,
            //                                   color: Colors.red,
            //                                   fontWeight: FontWeight.w700,
            //                                 ),
            //                                 textAlign: TextAlign.center,
            //                               ),
            //                             ),
            //                             const SizedBox(
            //                               width: 12,
            //                             ),
            //                             GestureDetector(
            //                               onTap: () {
            //                                 setState(() {
            //                                   _isShowKeyboard = !_isShowKeyboard;
            //                                   _keyboardMessage = "";
            //                                 });
            //                               },
            //                               child: const Icon(
            //                                 Icons.cancel,
            //                                 color: Colors.grey,
            //                                 size: 30,
            //                               ),
            //                             ),
            //                             const SizedBox(
            //                               width: 24,
            //                             ),
            //                           ],
            //                         ),
            //                         const SizedBox(
            //                           height: 10,
            //                         ),
            //                         Expanded(
            //                           child: NumericKeyboard(
            //                             onKeyboardTap: _onKeyboardTap,
            //                             textColor: Colors.red,
            //                             rightButtonFn: () {
            //                               setState(() {
            //                                 _isShowKeyboard = !_isShowKeyboard;
            //                               });
            //                             },
            //                             rightIcon: const Text(
            //                               "*",
            //                               style: TextStyle(
            //                                 color: Colors.red,
            //                                 fontSize: 24,
            //                               ),
            //                             ),
            //                             leftButtonFn: () {
            //                               _onKeyboardTap("*");
            //                             },
            //                             leftIcon: const Text(
            //                               "#",
            //                               style: TextStyle(
            //                                 color: Colors.red,
            //                                 fontSize: 24,
            //                               ),
            //                             ),
            //                             mainAxisAlignment:
            //                                 MainAxisAlignment.spaceEvenly,
            //                           ),
            //                         ),
            //                       ],
            //                     ),
            //                   ),
            //                 Positioned(
            //                   top: 10,
            //                   left: 12,
            //                   right: 12,
            //                   child: Text(
            //                     _callQuality,
            //                     textAlign: TextAlign.center,
            //                     style: const TextStyle(
            //                       color: Colors.white,
            //                       fontSize: 16,
            //                       fontWeight: FontWeight.w600,
            //                     ),
            //                   ),
            //                 )
            //               ],
            //             ),
            //           ),
            //         ],
            //       ),
            //
            //       // Column(
            //       //   children: [
            //       //     // Container(
            //       //     //   width: double.infinity,
            //       //     //   height: 75,
            //       //     //   color: Colors.white,
            //       //     //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //       //     //   child: Row(
            //       //     //     children: [
            //       //     //       GestureDetector(
            //       //     //         onTap: () {
            //       //     //           Navigator.pop(context);
            //       //     //         },
            //       //     //         child: const Icon(Icons.arrow_back),
            //       //     //       ),
            //       //     //       const SizedBox(
            //       //     //         width: 12,
            //       //     //       ),
            //       //     //       Expanded(
            //       //     //         child: TextField(
            //       //     //           controller: _phoneNumberController,
            //       //     //           keyboardType: TextInputType.number,
            //       //     //           decoration: InputDecoration(
            //       //     //             prefixIcon: const Icon(Icons.phone),
            //       //     //             labelText: "Phone Number",
            //       //     //             enabledBorder: myInputBorder(),
            //       //     //             focusedBorder: myFocusBorder(),
            //       //     //           ),
            //       //     //           onSubmitted: (val)async{
            //       //     //             await getGuestUser();
            //       //     //           },
            //       //     //         ),
            //       //     //       ),
            //       //     //     ],
            //       //     //   ),
            //       //     // ),
            //       //
            //       //   ],
            //       // ),
            //     ),
            //   ),
            // ),
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
    _phoneNumberController.clear();
    setState(() {
      _callStatus = OmiCallState.unknown.rawValue;
      guestUser = {};
      _callTime = '';
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
