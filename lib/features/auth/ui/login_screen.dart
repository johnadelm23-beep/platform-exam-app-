import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/ui/register_screen.dart';
import 'package:platformexamapp/features/auth/ui/widgets/custom_container_sigin_with_google.dart';
import 'package:platformexamapp/features/auth/ui/widgets/custom_text_rich.dart';
import 'package:platformexamapp/features/home/ui/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryColor),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.indigo.shade500,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              SizedBox(height: 20.h),

              /// 🖼️ Image
              Image.asset(
                'assets/images/background.png',
                width: 270.w,
                height: 270.h,
              ),

              SizedBox(height: 20.h),

              /// ⚪ FORM CONTAINER
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Welcome back 👋",
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 25.h),

                    /// 🧾 FORM
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextFormField(
                            hintText: "Email",
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Email is required";
                              }
                              if (!value.contains("@")) {
                                return "Enter valid email";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 12.h),

                          CustomTextFormField(
                            hintText: "Password",
                            controller: _passwordController,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Password is required";
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 25.h),

                          /// 🔥 LOGIN BUTTON + LISTENER
                          BlocListener<AuthCubit, AuthState>(
                            listener: (context, state) {
                              if (state is AuthLoading) {
                                _showLoading();
                              }

                              if (state is AuthSuccess) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();

                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                  (route) => false,
                                );
                                //  context.read<HomeCubit>().getUserData();
                              }

                              if (state is AuthError) {
                                Navigator.of(
                                  context,
                                  rootNavigator: true,
                                ).pop();

                                _showError(state.errorMessage);
                              }
                            },
                            child: SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                text: "Login",
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    context.read<AuthCubit>().login(
                                      _emailController.text,
                                      _passwordController.text,
                                    );
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10.h),

                    /// 🔵 GOOGLE
                    CustomContainerSiginWithGoogle(
                      onTap: () {
                        context.read<AuthCubit>().signInWithGoogle();
                      },
                    ),

                    SizedBox(height: 20.h),

                    /// 🔗 REGISTER
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: CustomTextRich(
                        text1: "Dont't have an account? ",
                        text2: "Sign up",
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
