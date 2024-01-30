// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:calling/screens/choose_type_ui/choose_type_ui_screen.dart';
import 'package:http/http.dart' as http;

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/video_call/video_call_screen.dart';
import 'package:easy_dialog/easy_dialog.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../../main.dart';
import '../HomeLoginScreen.dart';
import '../dial/dial_screen.dart';
import '../login/login_apikey_screen.dart';
import '../login/login_user_password_screen.dart';
import 'package:flutter/material.dart';

String statusToDescription(int status) {
  if (status == OmiCallState.calling.rawValue) {
    return "Đang kết nối tới cuộc gọi";
  }
  if (status == OmiCallState.connecting.rawValue) {
    return "Đang kết nối";
  }
  if (status == OmiCallState.early.rawValue) {
    return "Cuộc gọi đang đổ chuông";
  }
  if (status == OmiCallState.confirmed.rawValue) {
    return "Cuộc gọi bắt đầu";
  }
  if (status == OmiCallState.disconnected.rawValue) {
    return "Cuộc gọi kết thúc";
  }
  return "";
}

class HomeScreen extends StatefulWidget {
  // final bool isVideo;
  const HomeScreen({
    Key? key,
    this.needRequestNotification = false,
    this.isLoginUUID = false,
    //required this.isVideo,
  }) : super(key: key);
  final bool needRequestNotification;
  final bool isLoginUUID;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _phoneNumberController =
      TextEditingController()..text = Platform.isAndroid ? '' : '';
  //'1000071' : '167631';

  TextStyle basicStyle = const TextStyle(
    color: Colors.white,
    fontSize: 16,
  );
  bool _isVideoCall = false;
  bool _isCallUDP = false;
  bool _isLoginUUID = false;
  late StreamSubscription _subscription;
  GlobalKey<DialScreenState>? _dialScreenKey;
  GlobalKey<VideoCallState>? _videoScreenKey;

  @override
  void initState() {
    super.initState();
    _isLoginUUID = widget.isLoginUUID;
    // _isVideoCall = widget.isVideo;
    if (Platform.isAndroid) {
      checkAndPushToCall();
    }
    OmicallClient.instance.getOutputAudios().then((value) {
      debugPrint("audios ${value.toString()}");
    });
    OmicallClient.instance.getCurrentUser().then((value) {
      debugPrint("user ${value.toString()}");
    });
    OmicallClient.instance.setMissedCallListener((data) {
      final String callerNumber = data["callerNumber"];
      final bool isVideo = data["isVideo"];
      debugPrint("OMICALL FLUTTER setMissedCallListener ==>  ${data}");
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
      final status = data["status"] as int;
      debugPrint("status  OmicallClient  zzz ::: $status");

      if (status == OmiCallState.incoming.rawValue ||
          status == OmiCallState.confirmed.rawValue) {
        debugPrint("data  OmicallClient  zzz ZZZZ ::: $data");

        _isVideoCall = data['isVideo'] as bool;
        var callerNumber = "";
        // bool isVideo =false;

        // if (_isVideoCall) {
        //   pushToVideoScreen(
        //     callerNumber,
        //     status: status,
        //     isOutGoingCall: false,
        //   );
        //   return;
        // }
        pushToDialScreen(
          callerNumber ?? "",
          status: status,
          isOutGoingCall: false,
        );
        return;
      }
      if (status == OmiCallState.confirmed.rawValue) {
        if (_dialScreenKey?.currentState != null) {
          return;
        }
        if (_videoScreenKey?.currentState != null) {
          return;
        }
        final data = omiAction.data;
        final callerNumber = data["callerNumber"];
        // _isVideoCall = data["isVideo"];
        // if (_isVideoCall) {
        //   pushToVideoScreen(
        //     callerNumber,
        //     status: status,
        //     isOutGoingCall: false,
        //   );
        //   return;
        // }
        pushToDialScreen(
          callerNumber ?? "",
          status: status,
          isOutGoingCall: false,
        );
      }
      if (status == OmiCallState.disconnected.rawValue) {
        debugPrint(data.toString());
      }
    });
    // checkSystemAlertPermission();
    OmicallClient.instance.setCallLogListener((data) {
      debugPrint("OMICALL FLUTTER setCallLogListener ==>  ${data}");
      final callerNumber = data["callerNumber"];
      _isVideoCall = data["isVideo"];
      makeCallWithParams(
        context,
        callerNumber,
        false,
      );
    });
  }

  Future<void> checkAndPushToCall() async {
    final call = await OmicallClient.instance.getInitialCall();
    debugPrint("call checkAndPushToCall ==>  ${call}}");
    if (call is Map && call['callerNumber'].length > 0 && call['status'] == 3 &&  call['status'] == 5 ) {
      final isVideo = call["isVideo"] as bool;
      final callerNumber = call["callerNumber"];

      // if (call['muted'] == false) return;

      if (isVideo) {
        pushToVideoScreen(
          callerNumber,
          status: OmiCallState.confirmed.rawValue,
          isOutGoingCall: false,
        );
      } else {
        pushToDialScreen(
          callerNumber,
          status: call['status'] == 5 ? OmiCallState.confirmed.rawValue : OmiCallState.incoming.rawValue,
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

  @override
  void dispose() {
    _subscription.cancel();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(
      String text,
      IconData? icon, {
      bool isPass = false,
    }) {
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                  ),
                  const Text(
                    "OMICALL",
                    style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.015,
                  ),
                  const Text(
                    "Please, enter phone number",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.07,
                  ),
                  Form(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 30, right: 30),
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
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        if(Platform.isAndroid)  Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: GestureDetector(
                            onTap: () {
                              if(_isCallUDP){
                                OmicallClient.instance.changeTransport(type: "UDP");
                                setState(() {
                                  _isCallUDP = !_isCallUDP;
                                });
                              } else {
                                OmicallClient.instance.changeTransport(type: "TCP");
                                setState(() {
                                  _isCallUDP = !_isCallUDP;
                                });
                              }
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _isCallUDP
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 24,
                                  color: _isCallUDP
                                      ? const Color.fromARGB(255, 225, 121, 243)
                                      : Colors.grey,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Call with UDP",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _isCallUDP
                                        ? const Color.fromARGB(
                                        255, 225, 121, 243)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ) else
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 32),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              const Text(
                                "Let's call",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.03,
                              ),
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.height * 0.1,
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    FocusScope.of(context).unfocus();
                                    makeCall(context);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color.fromARGB(255, 255, 230, 85),
                                          Color.fromARGB(255, 176, 74, 166),
                                        ], // Define your gradient colors
                                        begin: Alignment
                                            .bottomRight, // Define the starting point of the gradient
                                        end: Alignment
                                            .topLeft, // Define the ending point of the gradient
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        MediaQuery.of(context).size.height *
                                            0.1,
                                      ),
                                    ),
                                    width: MediaQuery.of(context).size.width *
                                        0.18,
                                    height: MediaQuery.of(context).size.height *
                                        0.05,
                                    child:
                                        const Icon(Icons.navigate_next_rounded),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.05,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 68),
              child: Align(
                alignment: Alignment.topLeft,
                child: GestureDetector(
                  onTap: () async {
                    EasyLoading.show();
                    Navigator.of(context).pop();
                    Navigator.push(context, MaterialPageRoute(builder: (_) {
                      if(_isLoginUUID){
                        return const LoginApiKeyScreen();
                      }
                      return const LoginUserPasswordScreen();
                    }));

                    await OmicallClient.instance.logout();
                    await LocalStorage.instance.logout();

                    EasyLoading.dismiss();
                  },
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.all(
                      Radius.circular(MediaQuery.of(context).size.width * 0.1),
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
              ),
            ),
          ],
        ),
      ),
      onWillPop: () async {
        return false;
      },
    );
  }

  void pushToVideoScreen(
    String phoneNumber, {
    required int status,
    required bool isOutGoingCall,
  }) {
    if (_videoScreenKey != null) {
      return;
    }
    _videoScreenKey = GlobalKey();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return VideoCallScreen(
        key: _videoScreenKey,
        status: status,
        isOutGoingCall: isOutGoingCall,
        isTypeDirectCall: false,
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
    _dialScreenKey = GlobalKey();
    print("Pussh to screen");
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return DialScreen(
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
    // EasyLoading.show();
    final result = await OmicallClient.instance.startCall(
      phone,
      false,
    );

    // EasyLoading.dismiss();
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
      // if (_isVideoCall) {
      //   pushToVideoScreen(
      //     phone,
      //     status: OmiCallState.calling.rawValue,
      //     isOutGoingCall: true,
      //   );
      // } else {
      //   pushToDialScreen(
      //     phone,
      //     status: OmiCallState.calling.rawValue,
      //     isOutGoingCall: true,
      //   );
      // }
      pushToDialScreen(
        phone,
        status: OmiCallState.calling.rawValue,
        isOutGoingCall: true,
      );
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
