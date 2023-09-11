import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();
  static final instance = LocalStorage._();

  Future<Map?> loginInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginInfoString = prefs.getString("login_info");
    if (loginInfoString == null || loginInfoString.isEmpty) return null;
    return json.decode(loginInfoString);
  }

  Future<void> setLoginInfo(Map<String, dynamic> loginInfo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginInfoString = json.encode(loginInfo);
    await prefs.setString("login_info", loginInfoString);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
