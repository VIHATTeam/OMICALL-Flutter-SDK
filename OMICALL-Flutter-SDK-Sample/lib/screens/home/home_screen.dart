import 'dart:io';

import 'package:calling/main.dart';
import 'package:calling/screens/video_call/video_call_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/constant/enums.dart';
import 'package:omicall_flutter_plugin/model/action_list.dart';
import 'package:omicall_flutter_plugin/model/action_model.dart';

import '../dial/dial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // var phoneNumber = "";
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController phoneNumber = TextEditingController()..text = '101';

  //audio
  // TextEditingController userName = TextEditingController()..text = '100';
  // TextEditingController password = TextEditingController()..text = 'ConCung100';
  //video
  TextEditingController userName = TextEditingController()..text = '100';
  TextEditingController password = TextEditingController()..text = 'Kunkun';
  bool _isLoginSuccess = false;
  bool _supportVideoCall = false;
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
  GlobalKey<VideoCallState>? _videoKey;

  @override
  void initState() {
    super.initState();
    // updateToken();
    omiChannel.subscriptionEvent().listen((event) {
      final action = event.data;
      if (action.actionName == OmiEventList.onCallEstablished && action.data["isVideo"] == true) {
        if (_videoKey?.currentState != null) {
          _videoKey?.currentState?.refreshRemoteCamera();
        } else {
          pushToVideoScreen();
          Future.delayed(const Duration(milliseconds: 300), () {
            _videoKey?.currentState?.refreshRemoteCamera();
          });
        }
        return;
      }
      if (action.actionName == OmiEventList.onCallEnd) {
        if (_videoKey?.currentContext != null) {
          Navigator.of(_videoKey!.currentContext!).pop();
          _videoKey = null;
        }
        return;
      }
    });
  }

  Future<void> updateToken() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final token = await FirebaseMessaging.instance.getToken();
    String? apnToken;
    if (Platform.isIOS) {
      apnToken = await FirebaseMessaging.instance.getAPNSToken();
    }
    String id = "";
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      id = (await deviceInfo.androidInfo).id;
    } else {
      id = (await deviceInfo.iosInfo).identifierForVendor ?? "";
    }
    final omiAction = OmiAction.updateToken(
      id,
      Platform.isAndroid ? "omicall.concung.dev" : "vn.vihat.omikit",
      fcmToken: token,
      apnsToken: apnToken,
    );
    omiChannel.action(action: omiAction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OmiKit Demo App'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              !_isLoginSuccess
                  ? Column(
                      children: [
                        TextField(
                          controller: userName,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person),
                            labelText: "User Name",
                            enabledBorder: myInputBorder(),
                            focusedBorder: myFocusBorder(),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextField(
                          controller: password,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.password),
                            labelText: "Password",
                            enabledBorder: myInputBorder(),
                            focusedBorder: myFocusBorder(),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        TextField(
                          controller: phoneNumber,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.phone),
                            labelText: "Phone Number",
                            enabledBorder: myInputBorder(),
                            focusedBorder: myFocusBorder(),
                          ),
                        ),
                      ],
                    ),
              if (!_isLoginSuccess) Container(
                margin: const EdgeInsets.only(top: 16,),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _supportVideoCall = !_supportVideoCall;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _supportVideoCall ? Icons.check_circle : Icons.circle_outlined,
                        size: 24,
                        color: _supportVideoCall ? Colors.redAccent : Colors.grey,
                      ),
                      const SizedBox(width: 8,),
                      Text(
                        "Video call",
                        style: TextStyle(
                          fontSize: 16,
                          color: _supportVideoCall ? Colors.redAccent : Colors.grey,
                        ),
                      )
                    ],
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  if (_isLoginSuccess) {
                    FocusScope.of(context).unfocus();
                    makeCall(context);
                  } else {
                    _login();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
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
                  child: Center(
                    child: Text(
                      _isLoginSuccess ? 'Make Call' : 'Login',
                      style: const TextStyle(
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

  void _login() async {
    if (userName.text.isEmpty || password.text.isEmpty) {
      return;
    }
    //audio call
    ActionModel action;
    if (_supportVideoCall) {
      action = OmiAction.initCall(
        userName.text,
        password.text,
        'dky',
        isVideo: true,
      );
    } else {
      action = OmiAction.initCall(
        userName.text,
        password.text,
        'thaonguyennguyen1197',
      );
    }
    omiChannel.action(action: action);
    Future.delayed(const Duration(seconds: 2), () {
      updateToken();
    });
    setState(() {
      _isLoginSuccess = true;
    });
  }

  void pushToVideoScreen() {
    if (_videoKey != null) {
      return;
    }
    _videoKey = GlobalKey<VideoCallState>();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return VideoCallScreen(
        key: _videoKey,
      );
    })).then((value) {
      _videoKey = null;
    });
  }

  Future<void> makeCall(
    BuildContext context, {
    String? phone,
  }) async {
    var params = <String, dynamic>{
      'phoneNumber': phone ?? phoneNumber.text,
      'isVideo': _supportVideoCall,
    };
    if (_supportVideoCall) {
      pushToVideoScreen();
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DialScreen(
            param: params,
          ),
        ),
      );
    }
    final action = OmiAction.startCall(
      phone ?? phoneNumber.text,
      _supportVideoCall,
    );
    omiChannel.action(action: action);
  }
}
