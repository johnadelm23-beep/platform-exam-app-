import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';

class CustomTextFormField extends StatefulWidget {
  const CustomTextFormField({
    super.key,
    this.maxLines = 1,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.hintText,
    this.controller,
    this.onChanged,
  });
  final int maxLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? hintText;
  final void Function(String)? onChanged;
  final TextEditingController? controller;

  @override
  State<CustomTextFormField> createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  bool isPassword = true;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      onChanged: widget.onChanged,
      style: TextStyle(fontSize: 15.sp),
      autovalidateMode: .onUserInteraction,
      controller: widget.controller,
      maxLines: widget.maxLines,
      obscureText: widget.obscureText && isPassword,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onTapOutside: (v) {
        FocusScope.of(context).unfocus();
      },
      decoration: InputDecoration(
        hintText: widget.hintText,
        suffixIcon: widget.obscureText
            ? IconButton(
                onPressed: () {
                  setState(() {
                    isPassword = !isPassword;
                  });
                },
                icon: isPassword
                    ? Icon(Icons.visibility_off)
                    : Icon(Icons.visibility),
              )
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: AppColors.primaryColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }
}
