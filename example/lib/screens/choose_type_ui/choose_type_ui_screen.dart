// ignore_for_file: unused_field

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/constant/events.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';

import '../../local_storage/local_storage.dart';
import '../../main.dart';
import '../direct_call/direct_call_screen.dart';
import '../indirect_call/indirect_call_home_screen.dart';

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

  late StreamSubscription _subscription;

  @override
  void initState() {
    _supportVideoCall = widget.isVideo;
    initControllers();
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  int i = 0;

  Future<void> initControllers() async {
    if (Platform.isAndroid) {
      /// Todo:(NOTE) Check có cuộc gọi, nếu có sẽ auto show màn hình cuộc gọi trường hợp kill app
      await checkAndPushToCall();
    }

    updateToken();

    _subscription =
        OmicallClient.instance.callStateChangeEvent.listen((omiAction) {
      debugPrint("omiAction  OmicallClient ::: $omiAction");
      if (omiAction.actionName != OmiEventList.onCallStateChanged) {
        return;
      }
      final data = omiAction.data;
      String statusString = '';
      debugPrint("data  OmicallClient  zzz ::: $data");
      final status = data["status"] as int;

      switch (status) {
        case 1:
          statusString = 'calling';
          break;
        case 2:
          statusString = 'incoming';
          break;
        case 3:
          statusString = 'early';
          break;
        case 4:
          statusString = 'connecting';
          break;
        case 5:
          statusString = 'confirmed';
          break;
        default:
          statusString = 'disconnect';
          break;
      }
      debugPrint("status choose OmicallClient zzz ::: $statusString");
      if (status == OmiCallState.incoming.rawValue) {
        i++;
        _supportVideoCall = data['isVideo'] as bool;

        if (i <= 1) {
          Navigator.of(context).push(MaterialPageRoute(builder: (_) {
            return DirectCallScreen(
              isVideo: _supportVideoCall,
              status: status,

              /// User gọi ra ngoài
              isOutGoingCall: false,
            );
          })).then((value) {
            i = 0;
          });
        }

        return;
      }
    });
  }

  Future<void> checkAndPushToCall() async {
    final call = await OmicallClient.instance.getInitialCall();
    if (call is Map) {
      Future.delayed(const Duration(milliseconds: 500)).then((value) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) {
              return DirectCallScreen(
                isVideo: call['isVideo'] as bool,
                status: call['status'],

                /// User gọi ra ngoài
                isOutGoingCall: false,
              );
            },
          ),
        );
      });
    }
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
                    onTap: () async {
                      await LocalStorage.instance
                          .setIsDirectCall(false)
                          .then((value) async {
                        await Navigator.push(context,
                            MaterialPageRoute(builder: (_) {
                          return const InDirectCallHomeScreen();
                        }));
                      });
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
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
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/home_login');
                  }

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
    await LocalStorage.instance.setIsDirectCall(true).then((value) async {
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
    });
  }
}
