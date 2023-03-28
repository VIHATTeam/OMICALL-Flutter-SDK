enum CallStatus {
  calling, ringing, established, end
}

extension CallStatusExtension on CallStatus {
  String get value {
    if (this == CallStatus.ringing) {
      return "Ringing";
    }
    if (this == CallStatus.end) {
      return "End";
    }
    return "Established";
  }
}