import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/ui/login_screen.dart';
import 'package:platformexamapp/features/auth/ui/widgets/custom_text_rich.dart';
import 'package:platformexamapp/features/home/cubit/cubit/home_cubit.dart';
import 'package:platformexamapp/features/home/ui/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmationPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmationPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: .start,
            children: [
              Row(
                children: [
                  Text(
                    "Create your account!👋",
                    style: TextStyle(fontSize: 30.sp),
                  ),
                ],
              ),
              SizedBox(height: 30.h),
              Form(
                key: _formKey,
                child: Column(
                  spacing: 30,
                  children: [
                    /// 🔹 NAME
                    CustomTextFormField(
                      hintText: "Name",
                      keyboardType: TextInputType.name,
                      controller: _nameController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Name is required";
                        }
                        if (v.trim().length < 3) {
                          return "Name must be at least 3 characters";
                        }
                        if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v)) {
                          return "Name must contain only letters";
                        }
                        return null;
                      },
                    ),

                    CustomTextFormField(
                      hintText: "Email",
                      keyboardType: TextInputType.emailAddress,
                      controller: _emailController,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return "Email is required";
                        }

                        final emailRegex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );

                        if (!emailRegex.hasMatch(v.trim())) {
                          return "Enter a valid email";
                        }

                        return null;
                      },
                    ),

                    CustomTextFormField(
                      hintText: "Password",
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      controller: _passwordController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Password is required";
                        }

                        if (v.length < 8) {
                          return "Password must be at least 8 characters";
                        }

                        if (!RegExp(r'[A-Z]').hasMatch(v)) {
                          return "Must contain at least one uppercase letter";
                        }

                        if (!RegExp(r'[a-z]').hasMatch(v)) {
                          return "Must contain at least one lowercase letter";
                        }

                        if (!RegExp(r'[0-9]').hasMatch(v)) {
                          return "Must contain at least one number";
                        }

                        if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
                          return "Must contain at least one special character";
                        }

                        return null;
                      },
                    ),

                    CustomTextFormField(
                      hintText: "Confirm Password",
                      keyboardType: TextInputType.visiblePassword,
                      obscureText: true,
                      controller: _confirmationPasswordController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return "Confirm your password";
                        }
                        if (v != _passwordController.text) {
                          return "Passwords do not match";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 30.h),
                    BlocListener<AuthCubit, AuthState>(
                      listener: (context, state) {
                        if (state is AuthLoading) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primaryColor,
                                ),
                              );
                            },
                          );
                        }
                        if (state is AuthSuccess) {
                          Navigator.pop(context);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (c) => HomeScreen()),
                            (r) => false,
                          );
                        }
                        if (state is AuthError) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.errorMessage),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: AppButton(
                        text: "Register",
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            context.read<AuthCubit>().register(
                              name: _nameController.text,
                              email: _emailController.text,
                              password: _passwordController.text,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10.h),

              SizedBox(height: 50.h),
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => LoginScreen()),
                    );
                  },
                  child: CustomTextRich(
                    text1: "Have an account?",
                    text2: "Sign in",
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
