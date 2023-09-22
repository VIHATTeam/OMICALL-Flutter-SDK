import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:omicall_flutter_plugin/action/action_model.dart';
import 'package:omicall_flutter_plugin/constant/events.dart';
import 'package:omicall_flutter_plugin/omicallsdk.dart';

import '../../main.dart';
import 'dial/dial_direct_view.dart';
import 'video/video_direct_view.dart';

class DirectCallScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final videoDirectViewKey = GlobalKey<VideoDirectViewState>();
    final dialDirectViewKey = GlobalKey<DialDirectViewState>();

    return isVideo
        ? VideoDirectView(
            key: videoDirectViewKey,
            status: status,
            isOutGoingCall: isOutGoingCall,
          )
        : DialDirectView(
            key: dialDirectViewKey,
            status: status,
            isOutGoingCall: isOutGoingCall,
          );
  }
}
