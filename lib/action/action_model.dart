class OmiAction {
  final String actionName;
  final Map<dynamic, dynamic> data;

  OmiAction({
    required this.actionName,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'actionName': actionName,
      'data': data,
    };
  }
}


enum OmiCallState {
  calling,
  early,
  connecting,
  confirmed,
  incoming,
  disconnected,
  hold,
}

extension ExtensionCallState on OmiCallState {
  int get rawValue {
    return index;
  }
}
