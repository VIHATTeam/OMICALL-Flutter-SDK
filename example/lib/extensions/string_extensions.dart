import 'package:omicall_flutter_plugin/action/action_model.dart';

extension StringExtensions on String{
  String statusToDescription(int status) {
    if (status == OmiCallState.calling.rawValue) {
      return "Đang kết nối tới cuộc gọi";
    }
    if (status == OmiCallState.connecting.rawValue) {
      return "Đang kết nối";
    }
    if (status == OmiCallState.early.rawValue) {
      return "Cuộc gọi đang đổ chuông";
    }
    if (status == OmiCallState.confirmed.rawValue) {
      return "Cuộc gọi bắt đầu";
    }
    if (status == OmiCallState.disconnected.rawValue) {
      return "Cuộc gọi kết thúc";
    }
    return "";
  }
}