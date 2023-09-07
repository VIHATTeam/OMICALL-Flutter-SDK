// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:convert';
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
  const HomeScreen({
    Key? key,
    this.needRequestNotification = false,
  }) : super(key: key);
  final bool needRequestNotification;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final TextEditingController _phoneNumberController =
      TextEditingController()..text = Platform.isAndroid ? '167631' : '167631';

  // late final TextEditingController _phoneNumberController =
  // TextEditingController()..text = Platform.isAndroid ? '123aaa' : '122aaa';
  TextStyle basicStyle = const TextStyle(
    color: Colors.white,
    fontSize: 16,
  );

  Gradient gradient4 = LinearGradient(
    colors: [
      Colors.black.withOpacity(0.8),
      Colors.grey[500]!.withOpacity(0.8),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
  bool _isVideoCall = false;
  late StreamSubscription _subscription;
  GlobalKey<DialScreenState>? _dialScreenKey;
  GlobalKey<VideoCallState>? _videoScreenKey;

  // Future<void> requestFCM() async {
  //   await FirebaseMessaging.instance.requestPermission(
  //     alert: false,
  //     badge: false,
  //     sound: false,
  //   );
  //   final token = await FirebaseMessaging.instance.getToken();
  //   String? apnToken;
  //   await OmicallClient.instance.updateToken(
  //     fcmToken: token,
  //     apnsToken: apnToken,
  //   );
  // }

  @override
  void initState() {
    super.initState();
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
      final status = data["status"] as int;
          debugPrint("status  OmicallClient  zzz ::: $status");
      if (status == OmiCallState.incoming.rawValue ||
          status == OmiCallState.confirmed.rawValue) {
        debugPrint("data  OmicallClient  zzz ::: $data");

        bool isVideo = data['isVideo'] as bool;
        var callerNumber = "";
        // bool isVideo =false;


        if (isVideo) {
          pushToVideoScreen(
            callerNumber,
            status: status,
            isOutGoingCall: false,
          );
          return;
        }
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
        final bool isVideo = data["isVideo"];
        if (isVideo) {
          pushToVideoScreen(
            callerNumber,
            status: status,
            isOutGoingCall: false,
          );
          return;
        }
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
      final callerNumber = data["callerNumber"];
      final isVideo = data["isVideo"];
      makeCallWithParams(
        context,
        callerNumber,
        isVideo,
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

  @override
  void dispose() {
    _subscription.cancel();
    _phoneNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          leading: const SizedBox(),
          leadingWidth: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: _phoneNumberController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone),
                  labelText: "Phone Number",
                  enabledBorder: myInputBorder(),
                  focusedBorder: myFocusBorder(),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(
                  top: 16,
                ),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _isVideoCall = !_isVideoCall;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _isVideoCall
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 24,
                        color: _isVideoCall ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        "Video call",
                        style: TextStyle(
                          fontSize: 16,
                          color: _isVideoCall ? Colors.blue : Colors.grey,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(
                height: 16,
              ),
              GestureDetector(
                onTap: () {
                  makeCall(context);
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.teal,
                        Colors.teal[200]!,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(5, 5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Call',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 24,
              ),
              GestureDetector(
                onTap: () async {
                  EasyLoading.show();
                  await OmicallClient.instance.logout();
                  await LocalStorage.instance.logout();
                  EasyLoading.dismiss();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const LoginUserPasswordScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        offset: Offset(5, 5),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      onWillPop: () async {
        return false;
      },
    );
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

  void pushToVideoScreen(
    String phoneNumber, {
    required int status,
    required bool isOutGoingCall,
  }) {
    if (_videoScreenKey != null) { return; }
    _videoScreenKey = GlobalKey();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return VideoCallScreen(
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
    if (_dialScreenKey != null) { return; }
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
    if(status == OmiStartCallStatus.startCallSuccess.rawValue){
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
