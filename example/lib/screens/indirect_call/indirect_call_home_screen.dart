// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:calling/screens/video_call/video_call_screen.dart';
import 'package:easy_dialog/easy_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import '../../components/textfield_custom_widget.dart';
import '../../local_storage/local_storage.dart';
import '../../main.dart';
import '../HomeLoginScreen.dart';
import '../dial/dial_screen.dart';

part 'indirect_call_home_vm_mixin.dart';

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

class InDirectCallHomeScreen extends StatefulWidget {
  // final bool isVideo;
  const InDirectCallHomeScreen({
    Key? key,
    this.needRequestNotification = false,
    //required this.isVideo,
  }) : super(key: key);
  final bool needRequestNotification;

  @override
  State<InDirectCallHomeScreen> createState() => _InDirectCallHomeScreenState();
}

class _InDirectCallHomeScreenState extends State<InDirectCallHomeScreen>
    with InDirectCallHomeViewModel {
  @override
  void initState() {
    initControllers();
    super.initState();
  }

  @override
  void dispose() {
    disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            child: TextFieldCustomWidget(
                              controller: _phoneNumberController,
                              keyboardType: TextInputType.phone,
                              hintLabel: 'Phone Number',
                              icon: Icons.phone,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.03,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
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
                                  color: _isVideoCall
                                      ? const Color.fromARGB(255, 225, 121, 243)
                                      : Colors.grey,
                                ),
                                const SizedBox(
                                  width: 8,
                                ),
                                Text(
                                  "Video call",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _isVideoCall
                                        ? const Color.fromARGB(
                                            255, 225, 121, 243)
                                        : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
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
                      return const HomeLoginScreen();
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
}
