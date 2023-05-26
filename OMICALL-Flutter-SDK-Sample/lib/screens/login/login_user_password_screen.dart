import 'dart:io';

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

class LoginUserPasswordScreen extends StatefulWidget {
  const LoginUserPasswordScreen({Key? key}) : super(key: key);

  // var phoneNumber = "";
  @override
  State<LoginUserPasswordScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginUserPasswordScreen> {
  // NSString * USER_NAME1 = @"100";
  // NSString * PASS_WORD1 = @"Kunkun";
  // NSString * USER_NAME2 = @"101";
  // NSString * PASS_WORD2 = @"Kunkun12345";
  //video
  late final TextEditingController _userNameController = TextEditingController()
    ..text = Platform.isIOS ? '102' : '103';
  late final TextEditingController _passwordController = TextEditingController()
    ..text = Platform.isIOS ? 'AwiZHdm2SY' : 'a7JoGYJbJQ';
  late final TextEditingController _serviceUrlController =
      TextEditingController()..text = 'devtestcallbot';
  late final TextEditingController _hostUrlController = TextEditingController()
    ..text = 'vh.omicrm.com';

  bool _supportVideoCall = true;
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _serviceUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _userNameController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person),
                labelText: "User Name",
                enabledBorder: myInputBorder(),
                focusedBorder: myFocusBorder(),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.password),
                labelText: "Password",
                enabledBorder: myInputBorder(),
                focusedBorder: myFocusBorder(),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              controller: _serviceUrlController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.cleaning_services),
                labelText: "Service",
                enabledBorder: myInputBorder(),
                focusedBorder: myFocusBorder(),
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            TextField(
              controller: _hostUrlController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.cleaning_services),
                labelText: "Host",
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
                      color: _supportVideoCall ? Colors.blue : Colors.grey,
                    ),
                    const SizedBox(
                      width: 8,
                    ),
                    Text(
                      "Video call",
                      style: TextStyle(
                        fontSize: 16,
                        color: _supportVideoCall ? Colors.blue : Colors.grey,
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
                FocusScope.of(context).unfocus();
                _login();
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
                    'Login',
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

  void _login() async {
    if (_userNameController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _serviceUrlController.text.isEmpty ||
        _serviceUrlController.text.isEmpty ||
        _hostUrlController.text.isEmpty) {
      return;
    }
    EasyLoading.show();
    await OmicallClient.instance.initCallWithUserPassword(
      userName: _userNameController.text,
      password: _passwordController.text,
      realm: _serviceUrlController.text,
      host: _hostUrlController.text,
      isVideo: _supportVideoCall,
    );

    await LocalStorage.instance.setLoginInfo({
      "userName": _userNameController.text,
      "password": _passwordController.text,
      "realm": _serviceUrlController.text,
      "isVideo": _supportVideoCall,
    });
    EasyLoading.dismiss();
    if (!mounted) {
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) {
      return const HomeScreen(
        needRequestNotification: true,
      );
    }));
  }
}
