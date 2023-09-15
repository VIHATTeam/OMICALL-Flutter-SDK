// To parse this JSON data, do
//
//     final loginInformation = loginInformationFromJson(jsonString);

import 'dart:convert';

LoginInformation loginInformationFromJson(String str) =>
    LoginInformation.fromJson(json.decode(str));

String loginInformationToJson(LoginInformation data) =>
    json.encode(data.toJson());

class LoginInformation {
  final String? usrName;
  final String? usrUuid;
  final String? isVideo;
  final String? apiKey;
  final String? realm;
  final String? host;

  LoginInformation({
    this.usrName,
    this.usrUuid,
    this.isVideo,
    this.apiKey,
    this.realm,
    this.host,
  });

  LoginInformation copyWith({
    String? usrName,
    String? usrUuid,
    String? isVideo,
    String? apiKey,
    String? realm,
    String? host,
  }) =>
      LoginInformation(
        usrName: usrName ?? this.usrName,
        usrUuid: usrUuid ?? this.usrUuid,
        isVideo: isVideo ?? this.isVideo,
        apiKey: apiKey ?? this.apiKey,
        realm: realm ?? this.realm,
        host: host ?? this.host,
      );

  factory LoginInformation.fromJson(Map<String, dynamic> json) =>
      LoginInformation(
        usrName: json["usrName"],
        usrUuid: json["usrUuid"],
        isVideo: json["isVideo"],
        apiKey: json["apiKey"],
        realm: json["realm"],
        host: json["host"],
      );

  Map<String, dynamic> toJson() => {
        "usrName": usrName,
        "usrUuid": usrUuid,
        "isVideo": isVideo,
        "apiKey": apiKey,
        "realm": realm,
        "host": host,
      };
}
