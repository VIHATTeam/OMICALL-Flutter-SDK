import 'package:omicall_flutter_plugin/action/action_model.dart';

extension IntExtensions on int{
  String statusToDescription() {
    if (this == OmiCallState.calling.rawValue) {
      return "Đang kết nối tới cuộc gọi";
    }
    if (this == OmiCallState.connecting.rawValue) {
      return "Đang kết nối";
    }
    if (this == OmiCallState.early.rawValue) {
      return "Cuộc gọi đang đổ chuông";
    }
    if (this == OmiCallState.confirmed.rawValue) {
      return "Cuộc gọi bắt đầu";
    }
    if (this == OmiCallState.disconnected.rawValue) {
      return "Cuộc gọi kết thúc";
    }
    return "";
}

}