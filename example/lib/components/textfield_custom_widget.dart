import 'package:flutter/material.dart';

class TextFieldCustomWidget extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String hintLabel;
  final IconData icon;
  final bool isPassword;

  const TextFieldCustomWidget({
    Key? key,
    required this.controller,
    required this.keyboardType,
    required this.hintLabel,
    required this.icon,
    this.isPassword = false,
  }) : super(key: key);

  @override
  State<TextFieldCustomWidget> createState() => _TextFieldCustomWidgetState();
}

class _TextFieldCustomWidgetState extends State<TextFieldCustomWidget> {
  bool _obscureText = true;
  InputDecoration inputDecoration(
    String text,
    IconData? icon, {
    bool isPass = false,
  }) {
    return InputDecoration(
      suffixIcon: isPass
          ? IconButton(
              icon:
                  Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
              onPressed: () {
                print(_obscureText);
                setState(() {
                  _obscureText = !_obscureText;
                });
                print(_obscureText);
              },
            )
          : const SizedBox.shrink(),
      labelText: text,
      labelStyle: const TextStyle(
        color: Colors.grey,
      ),
      hintText: text,
      hintStyle: const TextStyle(
        color: Colors.grey,
      ),
      prefixIcon: Icon(
        icon,
        size: MediaQuery.of(context).size.width * 0.06,
        color: Colors.grey,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MediaQuery.of(context).size.width * 0.01),
        ),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MediaQuery.of(context).size.width * 0.1),
        ),
        borderSide: BorderSide(
          color: Colors.red,
          width: MediaQuery.of(context).size.width * 0.01,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MediaQuery.of(context).size.width * 0.1),
        ),
        borderSide: const BorderSide(
          color: Colors.white,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(MediaQuery.of(context).size.width * 0.1),
        ),
        borderSide: BorderSide(
          color: const Color.fromARGB(255, 225, 121, 243),
          width: MediaQuery.of(context).size.width * 0.008,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      keyboardType: widget.keyboardType,
      obscureText: widget.isPassword ? _obscureText : false,
      enableSuggestions: widget.isPassword ? false : true,
      autocorrect: widget.isPassword ? false: true,
      decoration: inputDecoration(
        widget.hintLabel,
        widget.icon,
        isPass: widget.isPassword,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'This field cannot be empty';
        }
        return null;
      },
    );
  }
}
