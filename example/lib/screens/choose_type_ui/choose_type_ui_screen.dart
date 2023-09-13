import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/constant/events.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';

import '../../local_storage/local_storage.dart';
import '../HomeLoginScreen.dart';
import '../call_home/call_home_screen.dart';
import '../direct_call/direct_call_screen.dart';
import '../home/home_screen.dart';
import '../video_call/video_call_screen.dart';

class ChooseTypeUIScreen extends StatefulWidget {
  final bool isVideo;

  // usrName: _userNameController.text,

  const ChooseTypeUIScreen({
    Key? key,
    required this.isVideo,
  }) : super(key: key);

  @override
  State<ChooseTypeUIScreen> createState() => _ChooseTypeUIScreenState();
}

class _ChooseTypeUIScreenState extends State<ChooseTypeUIScreen> {
  bool _supportVideoCall = false;

  @override
  void initState() {
    _supportVideoCall = widget.isVideo;
    // _subscription =
    //     OmicallClient.instance.callStateChangeEvent.listen((omiAction) async {
    //   if (omiAction.actionName == OmiEventList.onCallStateChanged) {
    //     final data = omiAction.data;
    //     final status = data["status"] as int;
    //     //if (callStatus == status) return;
    //
    //     debugPrint("status OmicallClient 00 ::: $status");
    //     if (status == OmiCallState.incoming.rawValue ||
    //         status == OmiCallState.confirmed.rawValue) {
    //       final isVideo = data["isVideo"] ?? false;
    //
    //       Navigator.push(
    //         context,
    //         MaterialPageRoute(
    //           builder: (_) {
    //             return DirectCallScreen(
    //               isVideo: isVideo,
    //               status: status,
    //               /// User gọi ra ngoài
    //               isOutGoingCall: false,
    //             );
    //           },
    //         ),
    //       );
    //     }
    //   }
    //   // if(data.keys.contains("isVideo")){
    // });
    super.initState();
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
                  "Please, choose type call",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return const HomeScreen();
                      }));
                    },
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.height * 0.1,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 176, 74, 166),
                              Color.fromARGB(255, 255, 230, 85),
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
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.07,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Indirect Call',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.navigate_next_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.04,
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
                  child: GestureDetector(
                    onTap: () async {
                      ///------------------
                      await onChooseDirectCall(context);
                    },
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(
                        MediaQuery.of(context).size.height * 0.1,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color.fromARGB(255, 176, 74, 166),
                              Color.fromARGB(255, 255, 230, 85),
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
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.07,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              'Direct Call',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Icon(Icons.navigate_next_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 30, right: 30),
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
                          color: _supportVideoCall
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
                            color: _supportVideoCall
                                ? const Color.fromARGB(255, 225, 121, 243)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Image.asset(
              "assets/images/signIn02.png",
              height: MediaQuery.of(context).size.height * 0.28,
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
                  //((route) {
                  //   MaterialPageRoute(
                  //     builder: (_) {
                  //       return const HomeLoginScreen();
                  //     },
                  //   );
                  //   return false;
                  // });
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
    );
  }

  Future<void> onChooseDirectCall(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) {
          return DirectCallScreen(
            isVideo: _supportVideoCall,
            status: OmiCallState.unknown.rawValue,

            /// User gọi ra ngoài
            isOutGoingCall: true,
          );
        },
      ),
    );
  }
}
