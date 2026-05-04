import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/ui/register_screen.dart';
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

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthCubit>().login(
        _emailController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Center(
                child: Image.asset(
                  "assets/images/background.png",
                  width: 220.w,
                  // fit: BoxFit.contain,
                ),
              ),
            ),

            Expanded(
              flex: 5,
              child: Container(
                width: double.infinity,

                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 25.h),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25.r),
                    topRight: Radius.circular(25.r),
                  ),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(
                              "Welcome back 👋",
                              style: TextStyle(
                                fontSize: 26.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            SizedBox(height: 25.h),

                            CustomTextFormField(
                              hintText: "Email",
                              controller: _emailController,
                              keyboardType: .emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Email is required";
                                }
                                final emailRegex = RegExp(
                                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                );
                                if (!emailRegex.hasMatch(v)) {
                                  return "Enter valid email";
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 12.h),

                            CustomTextFormField(
                              hintText: "Password",
                              keyboardType: .visiblePassword,
                              obscureText: true,
                              controller: _passwordController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Password is required";
                                }
                                return null;
                              },
                            ),

                            SizedBox(height: 25.h),

                            BlocListener<AuthCubit, AuthState>(
                              listener: (context, state) {
                                if (state is AuthLoadingState) {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                if (state is AuthSuccessState) {
                                  Navigator.pop(context);

                                  WidgetsBinding.instance.addPostFrameCallback((
                                    _,
                                  ) {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => HomeScreen(),
                                      ),
                                      (route) => false,
                                    );
                                  });
                                }

                                if (state is AuthErrorState) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(state.errorMessage),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              },

                              child: SizedBox(
                                width: double.infinity,
                                child: AppButton(
                                  text: "Login",
                                  onPressed: _submit,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),

                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(fontSize: 18.sp),
                              ),
                              TextSpan(
                                text: "Sign up",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
