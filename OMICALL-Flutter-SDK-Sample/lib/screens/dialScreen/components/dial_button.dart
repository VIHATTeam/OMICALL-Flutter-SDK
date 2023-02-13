import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../size_config.dart';

class DialButton extends StatelessWidget {
  const DialButton({
    Key? key,
    required this.iconSrc,
    required this.text,
    required this.press,
    this.color
  }) : super(key: key);

  final String iconSrc, text;
  final Color? color;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: getProportionateScreenWidth(120),
      child: TextButton(
        style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(
          vertical: getProportionateScreenWidth(20),
        )),
        onPressed: press,
        child: Column(
          children: [
            SvgPicture.asset(
              iconSrc,
              color:color ?? Colors.white,
              height: 36,
            ),
            VerticalSpacing(of: 5),
            Text(
              text,
              style: TextStyle(
                color:color ?? Colors.white,
                fontSize: 13,
              ),
            )
          ],
        ),
      ),
    );
  }
}
