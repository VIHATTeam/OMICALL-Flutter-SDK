import 'dart:async';
import 'dart:io';

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/home/home_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import '../../components/textfield_custom_widget.dart';
import '../../model/login_information.dart';
import '../dial/Dial_Screen_2.dart';
import '../dial/dial_screen.dart';
import '../video_call/video_call_screen.dart';

import '../choose_type_ui/choose_type_ui_screen.dart';

class LoginApiKeyScreen extends StatefulWidget {
  const LoginApiKeyScreen({Key? key}) : super(key: key);

  // var phoneNumber = "";
  @override
  State<LoginApiKeyScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginApiKeyScreen> {
  // NSString * USER_NAME1 = @"100";
  // NSString * PASS_WORD1 = @"Kunkun";
  // NSString * USER_NAME2 = @"101";
  // NSString * PASS_WORD2 = @"Kunkun12345"; 0358380641

  String user_name = " Tài khoản test app Tài khoản test app";
  String pass_word = "0906005535";
  String apiKEY = "E7AF81703203FC31F5658FAF3B875149CD57368ED07DB4AF414D93D3D2EBC76E";


  //video
  late final TextEditingController _userNameController = TextEditingController()
    ..text = user_name;
  late final TextEditingController _usrUuidController = TextEditingController()
    ..text = pass_word;
  late final TextEditingController _apiKeyController = TextEditingController()
    ..text = apiKEY;

  bool _supportVideoCall = true;

  bool _isVideoCall = false;
  late StreamSubscription _subscription;
  GlobalKey<DialScreenState>? _dialScreenKey;
  GlobalKey<VideoCallState>? _videoScreenKey;
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

  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _usrUuidController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  "Sign in to your ApiKey",
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
                            controller: _userNameController,
                            hintLabel: 'User Name',
                            icon: Icons.person,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.035,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                          child: TextFieldCustomWidget(
                            controller: _usrUuidController,
                            keyboardType: TextInputType.visiblePassword,
                            hintLabel: 'Password',
                            icon: Icons.lock,
                            isPassword: true,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.035,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 30, right: 30),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(
                              MediaQuery.of(context).size.width * 0.1),
                          child: TextFieldCustomWidget(
                            controller: _apiKeyController,
                            hintLabel: 'Host',
                            icon: Icons.location_city,
                            keyboardType: TextInputType.text,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.03,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // GestureDetector(
                            //   onTap: () {
                            //     setState(() {
                            //       _supportVideoCall = !_supportVideoCall;
                            //     });
                            //   },
                            //   child: Row(
                            //     children: [
                            //       Icon(
                            //         _supportVideoCall
                            //             ? Icons.check_circle
                            //             : Icons.circle_outlined,
                            //         size: 24,
                            //         color: _supportVideoCall
                            //             ? const Color.fromARGB(
                            //                 255, 225, 121, 243)
                            //             : Colors.grey,
                            //       ),
                            //       const SizedBox(
                            //         width: 8,
                            //       ),
                            //       Text(
                            //         "Video call",
                            //         style: TextStyle(
                            //           fontSize: 16,
                            //           color: _supportVideoCall
                            //               ? const Color.fromARGB(
                            //                   255, 225, 121, 243)
                            //               : Colors.grey,
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            // ),
                            Spacer(),
                            const Text(
                              "Forget you password",
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                          ],
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
                              "Sign in",
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
                                  _login();
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
                                      MediaQuery.of(context).size.height * 0.1,
                                    ),
                                  ),
                                  width:
                                      MediaQuery.of(context).size.width * 0.18,
                                  height:
                                      MediaQuery.of(context).size.height * 0.05,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Don't have an account? ",
                            style: TextStyle(fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: const Text(
                              "Create",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                decorationThickness: 2.0,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                onTap: () {
                  Navigator.of(context).pop();
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
    );
  }

  void _login() async {
    if (_userNameController.text.isEmpty ||
        _usrUuidController.text.isEmpty ||
        _apiKeyController.text.isEmpty) {
      return;
    }
    // EasyLoading.show();
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    String? token = await FirebaseMessaging.instance.getToken();
    if (Platform.isIOS) {
      token = await FirebaseMessaging.instance.getAPNSToken();
    }
    final result0 = await OmicallClient.instance.getCurrentUser();
    debugPrint(result0.toString());
    final result = await OmicallClient.instance.initCallWithApiKey(
      usrName: _userNameController.text,
      usrUuid: _usrUuidController.text,
      isVideo: _supportVideoCall,
      phone: _usrUuidController.text,
      apiKey: _apiKeyController.text,
        fcmToken: token
    );
    // EasyLoading.dismiss();
    // debugPrint(result.toString());
    if (result == false) {
      return;
    }

    await LocalStorage.instance.setLoginInfo({
      "usrName": _userNameController.text,
      "usrUuid": _usrUuidController.text,
      "isVideo": _supportVideoCall,
      "apiKey": _apiKeyController.text,
      "realm": '',
      "host": '',
      "fcmToken": token
    });

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) {
      return HomeScreen(
        // userName: _userNameController.text,
        // password: _usrUuidController.text,
        // realm: '',
        // host: _usrUuidController.text,
        // usrUuid: _usrUuidController.text,
        // apiKey: _apiKeyController.text,
        needRequestNotification: true,
        isLoginUUID: true
      );
//       return const HomeScreen(
//         needRequestNotification: true,
//       );
      // return DialScreen2(
      //   key: _dialScreenKey,
      //   phoneNumber: "167631",
      //   status: 8,
      //   isOutGoingCall: true,
      // );
    }));
  }
}
