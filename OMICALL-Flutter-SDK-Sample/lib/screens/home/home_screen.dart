import 'dart:async';
import 'dart:io';

import 'package:calling/components/call_status.dart';
import 'package:calling/screens/video_call/video_call_screen.dart';
import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../main.dart';
import '../dial/dial_screen.dart';

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
      TextEditingController()..text = Platform.isAndroid ? '101' : '100';
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
  GlobalKey<VideoCallState>? _videoKey;
  GlobalKey<DialScreenState>? _dialKey;
  late StreamSubscription _subscription;

  @override
  void initState() {
    super.initState();
    if (widget.needRequestNotification) {
      updateToken();
    }
    _subscription = OmicallClient().controller.eventTransferStream.listen((omiAction) {
      if (omiAction.actionName == OmiEventList.incomingReceived) {
        //having a incoming call
        final data = omiAction.data;
        final callerNumber = data["callerNumber"];
        final bool isIncoming = data["isIncoming"];
        final bool isVideo = data["isVideo"];
        if (isIncoming && isVideo) {
          pushToVideoScreen(
            callerNumber,
            isInComing: true,
          );
          Future.delayed(const Duration(milliseconds: 300), () {
            _videoKey?.currentState?.refreshRemoteCamera();
          });
          return;
        }
        if (isIncoming && !isVideo) {
          pushToDialScreen(
            callerNumber ?? "",
            status: CallStatus.ringing,
          );
        }
      }
      if (omiAction.actionName == OmiEventList.onCallEstablished) {
        if (_dialKey?.currentState != null) {
          _dialKey?.currentState?.updateDialScreen(null, CallStatus.established);
        }
      }
      if (omiAction.actionName == OmiEventList.onCallEnd) {
        if (_videoKey?.currentContext != null) {
          Navigator.of(_videoKey!.currentContext!).pop();
          _videoKey = null;
        }
        if (_dialKey?.currentContext != null) {
          Navigator.of(_dialKey!.currentContext!).pop();
          _dialKey = null;
        }
        return;
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
    bool isInComing = true,
  }) {
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

  void pushToDialScreen(
    String phoneNumber, {
    required CallStatus status,
  }) {
    if (_dialKey != null) {
      return;
    }
    _dialKey = GlobalKey<DialScreenState>();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) {
      return DialScreen(
        key: _dialKey,
        phoneNumber: phoneNumber,
        status: status,
      );
    })).then((value) {
      _dialKey = null;
    });
  }

  Future<void> makeCall(BuildContext context) async {
    final phone = _phoneNumberController.text;
    if (phone.isEmpty) {
      return;
    }
    if (_isVideoCall) {
      pushToVideoScreen(phone);
    } else {
      pushToDialScreen(
        phone,
        status: CallStatus.ringing,
      );
    }
    OmicallClient().startCall(
      phone,
      _isVideoCall,
    );
  }
}
