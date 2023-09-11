
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/constant/events.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';

import '../../main.dart';

part 'indirect_call_vm_mixin.dart';

class IndirectCallScreen extends StatefulWidget {
  final bool isVideo;
  final int status;
  final bool isOutGoingCall;
  const IndirectCallScreen({
    Key? key,
    required this.isVideo,
    required this.status,
    required this.isOutGoingCall,
  }) : super(key: key);

  @override
  State<IndirectCallScreen> createState() => _IndirectCallScreenState();
}

class _IndirectCallScreenState extends State<IndirectCallScreen> with IndirectCallViewModel{

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
