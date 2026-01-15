import 'package:flutter/material.dart';
import 'package:reel_recommandation/utils/colors.dart';
import 'package:reel_recommandation/utils/validator_callback.dart';

class CustomTextField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType type;
  final bool isPass;
  final ValidatorCallback validatorCallback;
  const CustomTextField({
    super.key,
    required this.hint,
    required this.controller,
    required this.type,
    required this.isPass,
    required this.validatorCallback,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration: InputDecoration(
        hint: Text(hint, style: TextStyle(color: darkTextSecondary)),
        border: UnderlineInputBorder(borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey, width: 0.3),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey, width: 0.3),
        ),
        filled: true,
        fillColor: darkDivider,
      ),
      keyboardType: type,
      cursorColor: darkTextSecondary,
      obscureText: isPass,
      controller: controller,
      validator: validatorCallback,
    );
  }
}