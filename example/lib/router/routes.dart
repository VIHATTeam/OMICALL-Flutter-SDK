import 'package:flutter/material.dart';

import '../main.dart';
import '../screens/HomeLoginScreen.dart';
import '../screens/choose_type_ui/choose_type_ui_screen.dart';
import '../screens/login/login_apikey_screen.dart';
import '../screens/login/login_user_password_screen.dart';

Route routes(RouteSettings settings) {
  if (settings.name == '/home_login') {
    return MaterialPageRoute(
      builder: (context) {
        return const HomeLoginScreen();
      },
    );
  } else if (settings.name == '/login_api_key') {
    return MaterialPageRoute(
      builder: (context) {
        return const LoginApiKeyScreen();
      },
    );
  } else if (settings.name == '/login_user_password') {
    return MaterialPageRoute(
      builder: (context) {
        return const LoginUserPasswordScreen();
      },
    );
  } else if (settings.name == '/choose_type_call') {
    return MaterialPageRoute(
      builder: (context) {
        return const ChooseTypeUIScreen(
          isVideo: false,
        );
      },
    );
  } else {
    return MaterialPageRoute(
      builder: (context) {
        return const MyApp(
          isDirectCall: true,
        );
      },
    );
  }
}
