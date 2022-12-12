
class ActionModel{
  final String actionName;
  final Map<String,dynamic> data;
  ActionModel({required this.actionName, required this.data});

  Map<String, dynamic> toJson() =>
      {
        'actionName': actionName,
        'data': data,
      };
}
