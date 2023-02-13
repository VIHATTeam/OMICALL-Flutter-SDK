import 'package:flutter/material.dart';

import 'package:calling/screens/homeScreen/home_screen.dart';
import 'package:calling/screens/dialScreen/dial_screen.dart';
import 'package:calling/screens/groupCall/group_call_screen.dart';

class AppRoute {
  static const homePage = '/home_page';

  static const callingPage = '/calling_page';
  static const dialScreen = '/dial_screen';

  static Route<Object>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case homePage:
        return MaterialPageRoute(
            builder: (_) => HomeScreen(), settings: settings);
      case callingPage:
        // return MaterialPageRoute(
        //     builder: (_) => DialScreen(), settings: settings);

        return null;
    }
  }
}
