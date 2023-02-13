import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final Widget child;
  final Function onPressed;
  final Gradient gradient;

  GradientButton({
    required this.onPressed,
    required this.child,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialButton(
      onPressed: onPressed(),
      child: Ink(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 200.0,
            minHeight: 50.0,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ),
      splashColor: Colors.black12,
      padding: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(32.0),
      ),
    );
  }
}
