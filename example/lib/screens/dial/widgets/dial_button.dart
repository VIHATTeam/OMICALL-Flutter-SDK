import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class DialButton extends StatelessWidget {
  const DialButton({
    Key? key,
    required this.iconSrc,
    required this.text,
    required this.press,
    this.color,
  }) : super(key: key);

  final String iconSrc, text;
  final Color? color;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            vertical: 20,
          ),
        ),
        onPressed: press,
        child: Column(
          children: [
            iconSrc.contains("svg") ? SvgPicture.asset(
              iconSrc,
              height: 36,
              color: Colors.white,
            ) : Image.asset(
              iconSrc,
              height: 36,
              width: 36,
              color: Colors.white,
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              text,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
