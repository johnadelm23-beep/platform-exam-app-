import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/ui/register_screen.dart';
import 'package:platformexamapp/features/auth/ui/widgets/custom_container_sigin_with_google.dart';
import 'package:platformexamapp/features/auth/ui/widgets/custom_text_rich.dart';
import 'package:platformexamapp/features/home/ui/home_screen.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';

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
        child: CircularProgressIndicator(color: AppColors.softGold),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo(color: Colors.white)),
        backgroundColor: AppColors.heartRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            children: [
              SizedBox(height: 10.h),

              /// 🖼️ Hero Brand Image
              Hero(
                tag: 'app_logo',
                child: Image.asset(
                  'assets/images/background.png',
                  width: 220.w,
                  height: 220.h,
                ),
              ),

              SizedBox(height: 20.h),

              /// ⚪ GLASS FORM CONTAINER
              GlassCard(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "welcome".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                      ),
                    ),

                    SizedBox(height: 20.h),

                    /// 🧾 FORM
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          CustomTextFormField(
                            hintText: "email".tr(),
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedMail01,
                              size: 20.r,
                              color: AppColors.softGold,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "email_required".tr();
                              }
                              if (!value.contains("@")) {
                                return "email_invalid".tr();
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 14.h),

                          CustomTextFormField(
                            hintText: "password".tr(),
                            controller: _passwordController,
                            obscureText: true,
                            keyboardType: TextInputType.visiblePassword,
                            prefixIcon: HugeIcon(
                              icon: HugeIcons.strokeRoundedLockPassword,
                              size: 20.r,
                              color: AppColors.softGold,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "password_required".tr();
                              }
                              return null;
                            },
                          ),

                          SizedBox(height: 24.h),

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
                                  AppPageRoute(child: const HomeScreen()),
                                  (route) => false,
                                );
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
                                text: "login".tr(),
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

                    SizedBox(height: 16.h),

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
                          AppPageRoute(child: const RegisterScreen()),
                        );
                      },
                      child: CustomTextRich(
                        text1: "dont_have_an_account".tr(),
                        text2: "sign_up".tr(),
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
