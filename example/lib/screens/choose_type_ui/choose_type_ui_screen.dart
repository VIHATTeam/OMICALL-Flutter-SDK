import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';

import '../../local_storage/local_storage.dart';
import '../call_home/call_home_screen.dart';
import '../home/home_screen.dart';
import '../video_call/video_call_screen.dart';

class ChooseTypeUIScreen extends StatefulWidget {
  final String userName;
  final String password;
  final String realm;
  final String host;
  final bool isVideo;

  // usrName: _userNameController.text,
  final String usrUuid;
  final String apiKey;
  const ChooseTypeUIScreen({
    Key? key,
    required this.userName,
    required this.password,
    required this.realm,
    required this.host,
    required this.usrUuid,
    required this.apiKey,
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
                        return HomeScreen(isVideo: _supportVideoCall,);
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
                onTap: () async{
                  EasyLoading.show();
                  await OmicallClient.instance.logout();
                  await LocalStorage.instance.logout();
                  EasyLoading.dismiss();
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

  Future<void> onChooseDirectCall(BuildContext context) async {
    bool result = false;
    EasyLoading.show();
    if (widget.apiKey.isEmpty) {
      result = await OmicallClient.instance.initCallWithUserPassword(
        userName: widget.userName,
        password: widget.password,
        realm: widget.realm,
        host: widget.host,
        isVideo: _supportVideoCall,
      );
      debugPrint(result.toString());
    } else {
      result = await OmicallClient.instance.initCallWithApiKey(
        usrName: widget.userName,
        usrUuid: widget.usrUuid,
        isVideo: _supportVideoCall,
        phone: widget.usrUuid,
        apiKey: widget.apiKey,
      );
      debugPrint(result.toString());
    }
    EasyLoading.dismiss();
    if (result == false || !mounted) {
      return;
    }
    if (!_supportVideoCall) {
      await Navigator.push(context, MaterialPageRoute(builder: (_) {
        return CallHomeScreen(
          isVideo: _supportVideoCall,
          status: 0,
          isOutGoingCall: true,
        );
      }));
    } else {

      await Navigator.push(context, MaterialPageRoute(builder: (_) {
        return const VideoCallScreen(
          status: 0,
          isOutGoingCall: true,
          isTypeDirectCall: true,
        );
      }));
    }
  }
}
