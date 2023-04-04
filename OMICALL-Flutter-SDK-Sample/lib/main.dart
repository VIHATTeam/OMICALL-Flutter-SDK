import 'dart:io';

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/home/home_screen.dart';
import 'package:calling/screens/login/login_apikey_screen.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final loginInfo = await LocalStorage.instance.loginInfo();
  await initService(loginInfo);
  runApp(MyApp(
    loginInfo: loginInfo,
  ));
}

Future<void> initService(Map<dynamic, dynamic>? loginInfo) async {
  if (loginInfo == null) {
    return;
  }
  //auto login
  await OmicallClient.instance.initCallWithApiKey(
    usrName: null,
    apiKey: null,
    usrUuid: null,
    isVideo: true,
  );
  // await OmicallClient.instance.initCallWithUserPassword(
  //   userName: null,
  //   password: null,
  //   realm: null,
  //   isVideo: true,
  // );
  await updateToken(
    showLoading: false,
  );
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: MaterialApp(
        theme: ThemeData.light(),
        home: loginInfo != null ? const HomeScreen() : const LoginApiKeyScreen(),
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
  String id = "";
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    id = (await deviceInfo.androidInfo).id;
  } else {
    id = (await deviceInfo.iosInfo).identifierForVendor ?? "";
  }
  if (showLoading) {
    EasyLoading.show();
  }
  await OmicallClient.instance.updateToken(
    id,
    Platform.isAndroid ? "vn.vihat.omicall.sdk_example" : "vn.vihat.omikit",
    fcmToken: token,
    apnsToken: apnToken,
  );
  if (showLoading) {
    EasyLoading.dismiss();
  }
}
