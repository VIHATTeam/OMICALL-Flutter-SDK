import 'package:calling/constants.dart';
import 'package:calling/size_config.dart';
import 'package:flutter/material.dart';

import 'components/body.dart';

class DialScreen extends StatelessWidget {
  const DialScreen({
    Key? key,
    required this.param,
  }) : super(key: key);
  final Map param;

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return const Scaffold(
      backgroundColor: kBackgoundColor,
      body: Body(),
    );
  }
}
