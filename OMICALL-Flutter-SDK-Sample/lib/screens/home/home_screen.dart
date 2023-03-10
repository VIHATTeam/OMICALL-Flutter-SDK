import 'dart:io';

import 'package:calling/screens/video_call/video_call_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../dial/dial_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  // var phoneNumber = "";
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController phoneNumber = TextEditingController()..text = '101';
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
  bool _supportVideoCall = false;
  GlobalKey<VideoCallState>? _videoKey;

  @override
  void initState() {
    super.initState();
    updateToken();
    // OmicallClient().subscriptionEvent().listen((event) {
    //   final action = event.data;
    //   if (action.actionName == OmiEventList.onCallEstablished &&
    //       action.data["isVideo"] == true) {
    //     if (_videoKey?.currentState != null) {
    //       _videoKey?.currentState?.refreshRemoteCamera();
    //     } else {
    //       pushToVideoScreen();
    //       Future.delayed(const Duration(milliseconds: 300), () {
    //         _videoKey?.currentState?.refreshRemoteCamera();
    //       });
    //     }
    //     return;
    //   }
    //   if (action.actionName == OmiEventList.onCallEnd) {
    //     if (_videoKey?.currentContext != null) {
    //       Navigator.of(_videoKey!.currentContext!).pop();
    //       _videoKey = null;
    //     }
    //     return;
    //   }
    // });
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
    EasyLoading.show();
    await OmicallClient().updateToken(
      id,
      Platform.isAndroid ? "omicall.concung.dev" : "vn.vihat.omikit",
      fcmToken: token,
      apnsToken: apnToken,
    );
    EasyLoading.dismiss();
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
                controller: phoneNumber,
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
                      _supportVideoCall = !_supportVideoCall;
                    });
                  },
                  child: Row(
                    children: [
                      Icon(
                        _supportVideoCall
                            ? Icons.check_circle
                            : Icons.circle_outlined,
                        size: 24,
                        color: _supportVideoCall ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(
                        width: 8,
                      ),
                      Text(
                        "Video call",
                        style: TextStyle(
                          fontSize: 16,
                          color:
                              _supportVideoCall ? Colors.blue : Colors.grey,
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
    OmicallClient().startCall(
      phone ?? phoneNumber.text,
      _supportVideoCall,
    );
  }
}
