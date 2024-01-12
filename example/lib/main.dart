import 'dart:io';

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/HomeLoginScreen.dart';
import 'package:calling/screens/home/home_screen.dart';
import 'package:calling/screens/login/login_apikey_screen.dart';
import 'package:calling/screens/login/login_user_password_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import 'screens/choose_type_ui/choose_type_ui_screen.dart';
import 'screens/direct_call/direct_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await Firebase.initializeApp();
  final userInfo = await LocalStorage.instance.loginInfo();
  final isDirectCall = await LocalStorage.instance.getIsDirectCall();
  runApp(MyApp(
    loginInfo: userInfo,
    isDirectCall: isDirectCall,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
    this.loginInfo,
    required this.isDirectCall,
  }) : super(key: key);
  final Map? loginInfo;
  final bool isDirectCall;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final loginInfo = widget.loginInfo;

  @override
  void initState() {
    super.initState();
    EasyLoading.instance.userInteractions = false;
    OmicallClient.instance.startServices();
    OmicallClient.instance.configPushNotification(
      notificationIcon: "calling_face",
      prefix: Platform.isIOS ? "" : "Cuộc gọi đến ",
      incomingBackgroundColor: "#FFFFFFFF",
      incomingAcceptButtonImage: "join_call",
      incomingDeclineButtonImage: "hangup",
      backImage: "ic_back",
      userImage: "calling_face",
      prefixMissedCallMessage: 'Cuộc gọi nhỡ từ',
      missedCallTitle: 'Cuộc gọi nhỡ',
      userNameKey: 'full_name',
      channelId: 'comcung.channelid.notification',
      audioNotificationDescription: "Có cuộc gọi audio",
      representName:"CSKH H-Finance"
    );
    init();
  }

  bool isVideo = false;

  Future<void> init() async {
    isVideo = loginInfo?['isVideo'] ?? false;
    final call = await OmicallClient.instance.getInitialCall();
    if (call is Map) {
      setState(() {
        isVideo = call["isVideo"] as bool;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: MaterialApp(
        theme: ThemeData.light(),
        home: loginInfo == null
            ? const LoginUserPasswordScreen()
            // ? const LoginApiKeyScreen()
            :
            // widget.isDirectCall
            //     ? DirectCallScreen(
            //         isVideo: isVideo,
            //         status: OmiCallState.unknown.rawValue,

            //         /// User gọi ra ngoài
            //         isOutGoingCall: true,
            //       )
            //     :
            const HomeScreen(
                needRequestNotification: true,
                isLoginUUID: false
              ),
        // ChooseTypeUIScreen(
        //     isVideo: loginInfo?['isVideo'],
        //   ),
        debugShowCheckedModeBanner: false,
        builder: EasyLoading.init(),
      ),
      onTap: () {
        if (FocusManager.instance.primaryFocus?.hasFocus == true) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      },
    );
  }
}

// Future<void> updateToken({
//   bool showLoading = true,
// }) async {
//   await FirebaseMessaging.instance.requestPermission(
//     alert: true,
//     badge: true,
//     sound: true,
//   );
//   final token = await FirebaseMessaging.instance.getToken();
//   String? apnToken;
//   if (Platform.isIOS) {
//     apnToken = await FirebaseMessaging.instance.getAPNSToken();
//   }
//   if (showLoading) {
//     EasyLoading.show();
//   }
//   await OmicallClient.instance.updateToken(
//     fcmToken: token,
//     apnsToken: apnToken,
//   );
//   if (showLoading) {
//     EasyLoading.dismiss();
//   }
// }

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (
        X509Certificate cert,
        String host,
        int port,
      ) {
        return true;
      };
  }
}
