import 'dart:io';

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/home/home_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import 'screens/login/login_apikey_screen.dart';
import 'screens/login/login_user_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  await Firebase.initializeApp();
  final loginInfo = await LocalStorage.instance.loginInfo();
  runApp(MyApp(
    loginInfo: loginInfo,
  ));
}

class MyApp extends StatefulWidget {
  const MyApp({
    Key? key,
    this.loginInfo,
  }) : super(key: key);
  final Map? loginInfo;

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
      prefix: "Cuộc gọi tới từ: ",
      declineTitle: "Từ chối",
      acceptTitle: "Chấp nhận",
      acceptBackgroundColor: "#FF3700B3",
      declineBackgroundColor: "#FF000000",
      incomingBackgroundColor: "#FFFFFFFF",
      incomingAcceptButtonImage: "join_call",
      incomingDeclineButtonImage: "hangup",
      backImage: "ic_back",
      userImage: "calling_face",
      prefixMissedCallMessage: 'Cuộc gọi nhỡ từ',
      missedCallTitle: 'Cuộc gọi nhỡ',
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: MaterialApp(
        theme: ThemeData.light(),
        home:
            loginInfo != null ? const HomeScreen() : const LoginApiKeyScreen(),
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

Future<void> updateToken({
  bool showLoading = true,
}) async {
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
  if (showLoading) {
    EasyLoading.show();
  }
  await OmicallClient.instance.updateToken(
    fcmToken: token,
    apnsToken: apnToken,
  );
  if (showLoading) {
    EasyLoading.dismiss();
  }
}

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
