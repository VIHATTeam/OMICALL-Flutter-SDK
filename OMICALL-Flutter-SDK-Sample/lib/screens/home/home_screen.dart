// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:calling/components/call_status.dart';
import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/video_call/video_call_screen.dart';
import 'package:easy_dialog/easy_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../main.dart';
import '../dial/dial_screen.dart';
import '../login/login_user_password_screen.dart';

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
      TextEditingController()..text = Platform.isAndroid ? '110' : '111';

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
  late StreamSubscription _subscription, _missedCallSubscription;
  GlobalKey<DialScreenState>? _dialScreenKey;
  GlobalKey<VideoCallState>? _videoScreenKey;

  @override
  void initState() {
    super.initState();
    updateToken();
    _missedCallSubscription =
        OmicallClient.instance.missedCallEvent.listen((data) {
      final String callerNumber = data["callerNumber"];
      final bool isVideo = data["isVideo"];
      makeCallWithParams(context, callerNumber, isVideo);
    });
    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
      if (omiAction.actionName == OmiEventList.incomingReceived) {
        //having a incoming call
        final data = omiAction.data;
        final transactionId = data["transactionId"];
        debugPrint("transactionId $transactionId");
        final callerNumber = data["callerNumber"];
        final bool isVideo = data["isVideo"];
        if (isVideo) {
          pushToVideoScreen(
            callerNumber,
            status: CallStatus.ringing,
          );
          return;
        }
        pushToDialScreen(
          callerNumber ?? "",
          status: CallStatus.ringing,
        );
      }
      if (omiAction.actionName == OmiEventList.onCallEstablished) {
        if (_dialScreenKey?.currentState != null) {
          return;
        }
        if (_videoScreenKey?.currentState != null) {
          return;
        }
        final data = omiAction.data;
        final callerNumber = data["callerNumber"];
        final bool isVideo = data["isVideo"];
        if (isVideo && _videoScreenKey?.currentState == null) {
          pushToVideoScreen(
            callerNumber,
            status: CallStatus.established,
          );
          return;
        }
        pushToDialScreen(
          callerNumber ?? "",
          status: CallStatus.established,
        );
      }
    });
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
    required CallStatus status,
  }) {
    _videoScreenKey = GlobalKey();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return VideoCallScreen(
        key: _videoScreenKey,
        status: status,
      );
    }));
  }

  void pushToDialScreen(
    String phoneNumber, {
    required CallStatus status,
  }) {
    _dialScreenKey = GlobalKey();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return DialScreen(
        key: _dialScreenKey,
        phoneNumber: phoneNumber,
        status: status,
      );
    }));
  }

  Future<void> makeCall(BuildContext context) async {
    final phone = _phoneNumberController.text;
    if (phone.isEmpty) {
      return;
    }
    final result = await OmicallClient.instance.startCall(
      phone,
      _isVideoCall,
    );
    if (result) {
      if (_isVideoCall) {
        pushToVideoScreen(phone, status: CallStatus.calling);
      } else {
        pushToDialScreen(
          phone,
          status: CallStatus.calling,
        );
      }
    } else {
      EasyDialog(
        title: const Text("Notification"),
        description: const Text("Please check microphone permission"),
      ).show(context);
    }
    // OmicallClient.instance.startCallWithUUID(
    //   phone,
    //   _isVideoCall,
    // );
  }

  Future<void> makeCallWithParams(
      BuildContext context, String callerNumber, bool isVideo) async {
    if (isVideo) {
      pushToVideoScreen(callerNumber, status: CallStatus.calling);
    } else {
      pushToDialScreen(
        callerNumber,
        status: CallStatus.calling,
      );
    }
    OmicallClient.instance.startCall(
      callerNumber,
      isVideo,
    );
  }
}
