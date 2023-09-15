import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();
  static final instance = LocalStorage._();

  Future<Map?> loginInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginInfoString = prefs.getString("login_info");
    if (loginInfoString != null) {
      return json.decode(loginInfoString);
    }
    return null;
  }

  Future<void> setLoginInfo(Map<String, dynamic> loginInfo) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final loginInfoString = json.encode(loginInfo);
    await prefs.setString("login_info", loginInfoString);
  }

  Future<bool> getIsDirectCall() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final isDirectCall = prefs.getBool("is_direct_call");
    return isDirectCall ?? false;
  }

  Future<void> setIsDirectCall(bool isDirectCall) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool("is_direct_call", isDirectCall);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
