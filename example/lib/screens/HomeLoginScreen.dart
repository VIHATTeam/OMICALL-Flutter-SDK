import 'dart:io';

import 'package:calling/local_storage/local_storage.dart';
import 'package:calling/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:omicall_flutter_plugin/omicall.dart';

import 'login/login_apikey_screen.dart';
import 'login/login_user_password_screen.dart';

class HomeLoginScreen extends StatefulWidget {
  const HomeLoginScreen({Key? key}) : super(key: key);

  // var phoneNumber = "";
  @override
  State<HomeLoginScreen> createState() => _HomeLoginState();
}

class _HomeLoginState extends State<HomeLoginScreen> {
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
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                const Text(
                  "Hello",
                  style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.015,
                ),
                const Text(
                  "Welcome to OMICALL",
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
                        return const LoginUserPasswordScreen();
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Text(
                              'Login with User name',
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
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) {
                        return const LoginApiKeyScreen();
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: const [
                            Text(
                              'Login with Api Key',
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
        ],
      ),
    );
    // return Scaffold(
    //   appBar: AppBar(
    //     title: const Text('Home Login'),
    //   ),
    //   body: Padding(
    //     padding: const EdgeInsets.all(16.0),
    //     child: Column(
    //         // mainAxisSize: MainAxisSize.max,
    //         mainAxisAlignment: MainAxisAlignment.center,
    //         // crossAxisAlignment: CrossAxisAlignment.stretch,
    //         children: <Widget>[
    //
    //           GestureDetector(
    //             onTap: () {
    //               Navigator.push(context, MaterialPageRoute(builder: (_) {
    //                 return const LoginUserPasswordScreen();
    //               }));
    //             },
    //             child: Container(
    //               height: 60,
    //               decoration: BoxDecoration(
    //                 gradient: LinearGradient(
    //                   colors: [
    //                     Colors.teal,
    //                     Colors.teal[200]!,
    //                   ],
    //                   begin: Alignment.topLeft,
    //                   end: Alignment.bottomRight,
    //                 ),
    //                 borderRadius: BorderRadius.circular(20),
    //                 boxShadow: const [
    //                   BoxShadow(
    //                     color: Colors.black12,
    //                     offset: Offset(5, 5),
    //                     blurRadius: 10,
    //                   )
    //                 ],
    //               ),
    //               child: const Center(
    //                 child: Text(
    //                   'Login with User Name',
    //                   style: TextStyle(
    //                     color: Colors.white,
    //                     fontSize: 20,
    //                     fontWeight: FontWeight.w500,
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ),
    //           const SizedBox(
    //             height: 16,
    //           ),
    //           GestureDetector(
    //             onTap: () {
    //               Navigator.push(context, MaterialPageRoute(builder: (_) {
    //                 return const LoginApiKeyScreen();
    //               }));
    //             },
    //             child: Container(
    //               height: 60,
    //               decoration: BoxDecoration(
    //                 gradient: LinearGradient(
    //                   colors: [
    //                     Colors.teal,
    //                     Colors.teal[200]!,
    //                   ],
    //                   begin: Alignment.topLeft,
    //                   end: Alignment.bottomRight,
    //                 ),
    //                 borderRadius: BorderRadius.circular(20),
    //                 boxShadow: const [
    //                   BoxShadow(
    //                     color: Colors.black12,
    //                     offset: Offset(5, 5),
    //                     blurRadius: 10,
    //                   )
    //                 ],
    //               ),
    //               child: const Center(
    //                 child: Text(
    //                   'Login with Api Key',
    //                   style: TextStyle(
    //                     color: Colors.white,
    //                     fontSize: 20,
    //                     fontWeight: FontWeight.w500,
    //                   ),
    //                 ),
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //   ),
    //   );
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
}
