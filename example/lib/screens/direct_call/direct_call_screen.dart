import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/constant/events.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';

import '../../main.dart';
import 'dial/dial_direct_view.dart';
import 'video/video_direct_view.dart';

class DirectCallScreen extends StatefulWidget {
  final bool isVideo;
  final int status;
  final bool isOutGoingCall;
  const DirectCallScreen({
    Key? key,
    required this.isVideo,
    required this.status,
    required this.isOutGoingCall,
  }) : super(key: key);

  @override
  State<DirectCallScreen> createState() => _DirectCallScreenState();
}

class _DirectCallScreenState extends State<DirectCallScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return widget.isVideo
        ? VideoDirectView(
            status: widget.status,
            isOutGoingCall: widget.isOutGoingCall,
          )
        : DialDirectView(
            status: widget.status,
            isOutGoingCall: widget.isOutGoingCall,
          );
  }
}
