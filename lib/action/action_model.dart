class OmiAction {
  final String actionName;
  final Map<String, dynamic> data;

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
