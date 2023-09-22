// // ignore_for_file: use_build_context_synchronously

// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:easy_dialog/easy_dialog.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_easyloading/flutter_easyloading.dart';
// import 'package:omicall_flutter_plugin/action/action_model.dart';
// import 'package:omicall_flutter_plugin/omicall.dart';

// import '../../components/dial_user_pic.dart';
// import '../../components/option_item.dart';
// import '../../components/rounded_button.dart';
// import '../../constants.dart';
// import '../call_home/call_home_screen.dart';
// import '../dial/dial_screen.dart';

// class VideoCallScreen extends StatefulWidget {
//   const VideoCallScreen({
//     Key? key,
//     required this.status,
//     required this.isOutGoingCall,
//     required this.isTypeDirectCall,
//   }) : super(key: key);

//   final int status;
//   final bool isOutGoingCall;
//   final bool isTypeDirectCall;

//   @override
//   State<StatefulWidget> createState() {
//     return VideoCallState();
//   }
// }

// class VideoCallState extends State<VideoCallScreen> {
//   RemoteCameraController? _remoteController;
//   LocalCameraController? _localController;
//   late StreamSubscription _subscription;
//   int _callStatus = 0;
//   bool isMuted = false;
//   Map? _currentAudio;
//   String _callQuality = "";
//   TextEditingController _phoneNumberController = TextEditingController();
//   Map? guestUser;
//   bool _isOutGoingCall = false;
//   bool _isVideo = true;

//   Future<void> getGuestUser() async {
//     final user = await OmicallClient.instance.getGuestUser();
//     if (user != null) {
//       setState(() {
//         guestUser = user;
//       });
//     }
//   }

//   Future<void> makeCall(BuildContext context) async {
//     final phone = _phoneNumberController.text;
//     if (phone.isEmpty) {
//       return;
//     }
//     EasyLoading.show();
//     final result = await OmicallClient.instance.startCall(
//       phone,
//       true,
//     );

//     EasyLoading.dismiss();
//     Map<String, dynamic> jsonMap = {};
//     bool callStatus = false;
//     String messageError = "";
//     debugPrint("result  OmicallClient  zzz ::: $result");

//     jsonMap = json.decode(result);
//     messageError = jsonMap['message'];
//     int status = jsonMap['status'];
//     if (status == OmiStartCallStatus.startCallSuccess.rawValue) {
//       setState(() {
//         callStatus = true;
//         _isOutGoingCall = true;
//       });
//     }

//     if (!callStatus) {
//       EasyDialog(
//         title: Text("Notification"),
//         description: Text("Error code ${messageError}"),
//       ).show(context);
//     }
//     // OmicallClient.instance.startCallWithUUID(
//     //   phone,
//     //   _isVideoCall,
//     // );
//   }

//   Future<void> makeCallWithParams(
//     BuildContext context,
//     String callerNumber,
//     bool isVideo,
//   ) async {
//     _callStatus = OmiCallState.calling.rawValue;

//     OmicallClient.instance.startCall(
//       callerNumber,
//       isVideo,
//     );
//   }

//   @override
//   void initState() {
//     _callStatus = widget.status;
//     initializeControllers();
//     super.initState();
//   }

//   int i = 0;

//   Future<void> initializeControllers() async {
//     OmicallClient.instance.registerVideoEvent();
//     _isOutGoingCall = widget.isOutGoingCall;
//     await getGuestUser();
//     OmicallClient.instance.setMissedCallListener((data) async {
//       await getGuestUser();
//       final String callerNumber = data["callerNumber"];

//       await makeCallWithParams(context, callerNumber, true);
//     });
//     _subscription =
//         OmicallClient.instance.callStateChangeEvent.listen((omiAction) async {
//       if (omiAction.actionName == OmiEventList.onCallStateChanged) {
//         final data = omiAction.data;
//         final status = data["status"] as int;
//         print('============STATUS: $status');
//         if (data.keys.contains("isVideo")) {
//           _isVideo = data["isVideo"] ?? false;
//         }
//         _callStatus = data["status"] as int;
//         updateVideoScreen(status);
//         if (status == OmiCallState.incoming.rawValue) {
//           _isOutGoingCall = false;
//           setState(() {});
//         }

//         if (status == OmiCallState.confirmed.rawValue) {
//           if (Platform.isAndroid) {
//             refreshRemoteCamera();
//             refreshLocalCamera();
//           }
//         }

//         if (status == OmiCallState.disconnected.rawValue) {
//           i++;
//           if (i >= 2) return;

//           await endCall(
//             needShowStatus: true,
//             needRequest: true,
//           );

//           return;
//         }
//         print('_isOutGoingCall: $_isOutGoingCall');
//       }
//     });

//     OmicallClient.instance.setVideoListener((data) {
//       refreshRemoteCamera();
//       refreshLocalCamera();
//     });
//     OmicallClient.instance.setMuteListener((p0) {
//       setState(() {
//         isMuted = p0;
//       });
//     });
//     OmicallClient.instance.setAudioChangedListener((newAudio) {
//       setState(() {
//         _currentAudio = newAudio.first;
//       });
//     });
//     OmicallClient.instance.getCurrentAudio().then((value) {
//       setState(() {
//         _currentAudio = value.first;
//       });
//     });
//     OmicallClient.instance.setCallQualityListener((data) {
//       final quality = data["quality"] as int;
//       setState(() {
//         if (quality == 0) {
//           _callQuality = "GOOD";
//         }
//         if (quality == 1) {
//           _callQuality = "NORMAL";
//         }
//         if (quality == 2) {
//           _callQuality = "BAD";
//         }
//       });
//     });
//   }

//   @override
//   void dispose() {
//     OmicallClient.instance.removeVideoEvent();
//     OmicallClient.instance.removeMuteListener();
//     OmicallClient.instance.removeAudioChangedListener();
//     _subscription.cancel();
//     _phoneNumberController.dispose();
//     super.dispose();
//   }

//   void updateVideoScreen(int status) {
//     setState(() {
//       _callStatus = status;
//     });
//   }

//   Future<void> endCall({
//     bool needRequest = true,
//     bool needShowStatus = true,
//   }) async {
//     if (needRequest) {
//       await OmicallClient.instance.endCall();
//     }
//     if (needShowStatus) {
//       await Future.delayed(const Duration(milliseconds: 200));
//     }
//     if (!mounted) {
//       return;
//     }
//     _callStatus = OmiCallState.unknown.rawValue;
//     guestUser = {};
//     _phoneNumberController.clear();
//     if (i > 1) {
//       i = 0;
//     }
//     setState(() {});
//     if (!widget.isTypeDirectCall) {
//       Navigator.pop(context);
//     }
//   }

//   void refreshRemoteCamera() {
//     _remoteController?.refresh();
//   }

//   void refreshLocalCamera() {
//     _localController?.refresh();
//   }

//   String get _audioImage {
//     final name = _currentAudio!["name"] as String;
//     if (name == "Receiver") {
//       return "ic_iphone";
//     }
//     if (name == "Speaker") {
//       return "ic_speaker";
//     }
//     return "ic_airpod";
//   }

//   Future<void> toggleAndCheckDevice() async {
//     final audioList = await OmicallClient.instance.getOutputAudios();
//     if (!mounted) {
//       return;
//     }
//     if (audioList.length > 2) {
//       //show selection
//       showCupertinoModalPopup(
//         context: context,
//         builder: (_) => CupertinoActionSheet(
//           actions: audioList.map((e) {
//             String name = e["name"];
//             if (name == "Receiver") {
//               name = "iPhone";
//             }
//             return CupertinoActionSheetAction(
//               onPressed: () {
//                 OmicallClient.instance.setOutputAudio(portType: e["type"]);
//                 Navigator.pop(context);
//               },
//               child: Text(name),
//             );
//           }).toList(),
//           cancelButton: CupertinoActionSheetAction(
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             child: const Text('Close'),
//           ),
//         ),
//       );
//     } else {
//       if (_currentAudio!["name"] == "Receiver") {
//         final speaker =
//             audioList.firstWhere((element) => element["name"] == "Speaker");
//         OmicallClient.instance.setOutputAudio(portType: speaker["type"]);
//       } else {
//         final receiver =
//             audioList.firstWhere((element) => element["name"] == "Receiver");
//         OmicallClient.instance.setOutputAudio(portType: receiver["type"]);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     InputDecoration inputDecoration(
//       String text,
//       IconData? icon,
//     ) {
//       return InputDecoration(
//         labelText: text,
//         labelStyle: const TextStyle(
//           color: Colors.grey,
//         ),
//         hintText: text,
//         hintStyle: const TextStyle(
//           color: Colors.grey,
//         ),
//         prefixIcon: Icon(
//           icon,
//           size: MediaQuery.of(context).size.width * 0.06,
//           color: Colors.grey,
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.all(
//             Radius.circular(MediaQuery.of(context).size.width * 0.01),
//           ),
//           borderSide: const BorderSide(
//             color: Colors.red,
//           ),
//         ),
//         focusedErrorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.all(
//             Radius.circular(MediaQuery.of(context).size.width * 0.1),
//           ),
//           borderSide: BorderSide(
//             color: Colors.red,
//             width: MediaQuery.of(context).size.width * 0.01,
//           ),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.all(
//             Radius.circular(MediaQuery.of(context).size.width * 0.1),
//           ),
//           borderSide: const BorderSide(
//             color: Colors.white,
//           ),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.all(
//             Radius.circular(MediaQuery.of(context).size.width * 0.1),
//           ),
//           borderSide: BorderSide(
//             color: const Color.fromARGB(255, 225, 121, 243),
//             width: MediaQuery.of(context).size.width * 0.008,
//           ),
//         ),
//       );
//     }

//     final width = MediaQuery.of(context).size.width;
//     // var correctWidth = (width - 20) / 4;
//     // if (correctWidth > 100) {
//     //   correctWidth = 100;
//     // }
//     return _isVideo == false
//         ? widget.isTypeDirectCall
//             ? CallHomeScreen(
//                 status: _callStatus,
//                 isOutGoingCall: true,
//                 isVideo: false,
//               )
//             : DialScreen(
//                 status: _callStatus,
//                 isOutGoingCall: false,
//               )
//         : WillPopScope(
//             child: Scaffold(
//               backgroundColor: Colors.grey,
//               body: Stack(
//                 children: [
//                   SingleChildScrollView(
//                     child: Column(
//                       children: [
//                         Container(
//                           color: Colors.grey,
//                           child: Column(
//                             children: [
//                               Stack(
//                                 alignment: Alignment.center,
//                                 children: [
//                                   if (_callStatus ==
//                                           OmiCallState.confirmed.rawValue ||
//                                       _callStatus ==
//                                           OmiCallState.connecting.rawValue)
//                                     RemoteCameraView(
//                                       width: double.infinity,
//                                       height:
//                                           MediaQuery.of(context).size.height,
//                                       onCameraCreated: (controller) async {
//                                         _remoteController = controller;
//                                         if (_callStatus ==
//                                                 OmiCallState
//                                                     .confirmed.rawValue &&
//                                             Platform.isAndroid) {
//                                           await Future.delayed(const Duration(
//                                               milliseconds: 200));
//                                           controller.refresh();
//                                         }
//                                       },
//                                     ),
//                                   if (_callStatus !=
//                                           OmiCallState.confirmed.rawValue ||
//                                       _callStatus ==
//                                           OmiCallState.unknown.rawValue)
//                                     Column(
//                                       children: [
//                                         Text(
//                                           _phoneNumberController.text.isEmpty
//                                               ? "..."
//                                               : "${guestUser?["extension"] ?? "..."}",
//                                           style: Theme.of(context)
//                                               .textTheme
//                                               .headlineMedium!
//                                               .copyWith(
//                                                   color: Colors.grey,
//                                                   fontSize: 24),
//                                         ),
//                                         const SizedBox(
//                                           height: 16,
//                                         ),
//                                         Center(
//                                           child: DialUserPic(
//                                             size: 200,
//                                             image: guestUser?["avatar_url"] !=
//                                                         "" &&
//                                                     guestUser?["avatar_url"] !=
//                                                         null
//                                                 ? guestUser!["avatar_url"]
//                                                 : "assets/images/calling_face.png",
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   if (_callStatus ==
//                                       OmiCallState.unknown.rawValue)
//                                     Padding(
//                                       padding: EdgeInsets.only(
//                                           top: MediaQuery.of(context)
//                                                   .size
//                                                   .height *
//                                               0.85),
//                                       child: RoundedCircleButton(
//                                         iconSrc: "assets/icons/call_end.svg",
//                                         press: () async {
//                                           if (_phoneNumberController
//                                               .text.isNotEmpty) {
//                                             makeCall(context);
//                                           }
//                                         },
//                                         color: _phoneNumberController
//                                                 .text.isNotEmpty
//                                             ? kGreenColor
//                                             : kSecondaryColor,
//                                         iconColor: Colors.white,
//                                       ),
//                                     ),
//                                   if (_callStatus ==
//                                       OmiCallState.confirmed.rawValue)
//                                     Padding(
//                                       padding: EdgeInsets.only(
//                                           top: MediaQuery.of(context)
//                                                   .size
//                                                   .height *
//                                               0.85),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceAround,
//                                         children: [
//                                           OptionItem(
//                                             icon: "video",
//                                             showDefaultIcon: true,
//                                             callback: () {
//                                               OmicallClient.instance
//                                                   .toggleVideo();
//                                             },
//                                           ),
//                                           OptionItem(
//                                             icon: "hangup",
//                                             showDefaultIcon: true,
//                                             callback: () {
//                                               endCall(
//                                                 needShowStatus: false,
//                                               );
//                                             },
//                                           ),
//                                           OptionItem(
//                                             icon: "mic",
//                                             showDefaultIcon: isMuted,
//                                             callback: () {
//                                               OmicallClient.instance
//                                                   .toggleAudio();
//                                             },
//                                           ),
//                                           if (_currentAudio != null)
//                                             OptionItem(
//                                               icon: _audioImage,
//                                               showDefaultIcon: true,
//                                               color: Colors.white,
//                                               callback: () {
//                                                 toggleAndCheckDevice();
//                                               },
//                                             ),
//                                         ],
//                                       ),
//                                     ),
//                                   if (_callStatus ==
//                                           OmiCallState.calling.rawValue ||
//                                       _callStatus ==
//                                           OmiCallState.incoming.rawValue ||
//                                       _callStatus ==
//                                           OmiCallState.early.rawValue ||
//                                       _callStatus ==
//                                           OmiCallState.connecting
//                                               .rawValue)
//                                     Padding(
//                                       padding: EdgeInsets.only(
//                                           top: MediaQuery.of(context)
//                                                   .size
//                                                   .height *
//                                               0.85),
//                                       child: Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.spaceAround,
//                                         children: [
//                                           if ((_callStatus ==
//                                                       OmiCallState
//                                                           .early.rawValue ||
//                                                   _callStatus ==
//                                                       OmiCallState
//                                                           .incoming.rawValue) &&
//                                               _isOutGoingCall == false)
//                                             RoundedCircleButton(
//                                               iconSrc:
//                                                   "assets/icons/call_end.svg",
//                                               press: () async {
//                                                 final result =
//                                                     await OmicallClient.instance
//                                                         .joinCall();
//                                                 if (result == false &&
//                                                     mounted) {
//                                                   Navigator.pop(context);
//                                                 }
//                                               },
//                                               color: kGreenColor,
//                                               iconColor: Colors.white,
//                                             ),
//                                           RoundedCircleButton(
//                                             iconSrc:
//                                                 "assets/icons/call_end.svg",
//                                             press: () {
//                                               endCall(
//                                                 needShowStatus: false,
//                                               );
//                                             },
//                                             color: kRedColor,
//                                             iconColor: Colors.white,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   if (_callStatus == OmiCallState.confirmed.rawValue &&
//                       !widget.isTypeDirectCall)
//                     Positioned(
//                       right: 15,
//                       top: 50,
//                       child: Padding(
//                         padding: const EdgeInsets.only(left: 10),
//                         child: GestureDetector(
//                           onTap: () async {
//                             OmicallClient.instance.switchCamera();
//                           },
//                           child: Material(
//                             elevation: 4,
//                             borderRadius: BorderRadius.all(
//                               Radius.circular(
//                                   MediaQuery.of(context).size.width * 0.1),
//                             ),
//                             child: Container(
//                               width: 52,
//                               height: 52,
//                               decoration: const BoxDecoration(
//                                 shape: BoxShape.circle,
//                                 color: Colors.white,
//                               ),
//                               child: const Icon(
//                                 Icons.cameraswitch_rounded,
//                                 size: 25,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   if (widget.isTypeDirectCall)
//                     Padding(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 24, vertical: 50),
//                       child: Row(
//                         children: [
//                           GestureDetector(
//                             onTap: () async {
//                               await endCall(
//                                 needShowStatus: false,
//                               ).then(
//                                 (value) => Navigator.of(context).pop(),
//                               );
//                             },
//                             child: Material(
//                               elevation: 4,
//                               borderRadius: BorderRadius.all(
//                                 Radius.circular(
//                                     MediaQuery.of(context).size.width * 0.1),
//                               ),
//                               child: Container(
//                                 width: 52,
//                                 height: 52,
//                                 decoration: const BoxDecoration(
//                                   shape: BoxShape.circle,
//                                   color: Colors.white,
//                                 ),
//                                 child: const Icon(
//                                   Icons.arrow_back,
//                                   size: 25,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: Material(
//                               elevation: 4,
//                               borderRadius: BorderRadius.circular(
//                                   MediaQuery.of(context).size.width * 0.1),
//                               child: TextFormField(
//                                 controller: _phoneNumberController,
//                                 keyboardType: TextInputType.phone,
//                                 decoration: inputDecoration(
//                                     'Phone Number', Icons.phone),
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'This field cannot be empty';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ),
//                           ),
//                           if (_callStatus == OmiCallState.confirmed.rawValue)
//                             Padding(
//                               padding: const EdgeInsets.only(left: 10),
//                               child: GestureDetector(
//                                 onTap: () async {
//                                   OmicallClient.instance.switchCamera();
//                                 },
//                                 child: Material(
//                                   elevation: 4,
//                                   borderRadius: BorderRadius.all(
//                                     Radius.circular(
//                                         MediaQuery.of(context).size.width *
//                                             0.1),
//                                   ),
//                                   child: Container(
//                                     width: 52,
//                                     height: 52,
//                                     decoration: const BoxDecoration(
//                                       shape: BoxShape.circle,
//                                       color: Colors.white,
//                                     ),
//                                     child: const Icon(
//                                       Icons.cameraswitch_rounded,
//                                       size: 25,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ),
//                         ],
//                       ),
//                     ),
//                   if (_callStatus == OmiCallState.confirmed.rawValue)
//                     Positioned(
//                       top: MediaQuery.of(context).padding.top +
//                           kToolbarHeight +
//                           30,
//                       right: 16,
//                       width: width / 3,
//                       height: (3 * width) / 5,
//                       child: LocalCameraView(
//                         width: double.infinity,
//                         height: double.infinity,
//                         onCameraCreated: (controller) async {
//                           _localController = controller;
//                           if (_callStatus == OmiCallState.confirmed.rawValue &&
//                               Platform.isAndroid) {
//                             await Future.delayed(
//                                 const Duration(milliseconds: 200));
//                             controller.refresh();
//                           }
//                         },
//                         errorWidget: Container(
//                           width: double.infinity,
//                           height: double.infinity,
//                           color: Colors.white,
//                           child: const Center(
//                             child: Icon(
//                               Icons.remove_red_eye,
//                               color: Colors.black,
//                               size: 24,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   if (_callStatus == OmiCallState.confirmed.rawValue)
//                     Positioned(
//                       top: MediaQuery.of(context).viewPadding.top +
//                           (widget.isTypeDirectCall ? 100 : 30),
//                       left: 12,
//                       right: 12,
//                       child: Text(
//                         _callQuality,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                     )
//                 ],
//               ),
//             ),
//             onWillPop: () async => false,
//           );
//   }
// }


