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
import 'package:platformexamapp/features/auth/ui/login_screen.dart';
import 'package:platformexamapp/features/auth/ui/widgets/custom_text_rich.dart';
import 'package:platformexamapp/features/home/ui/home_screen.dart';
import 'package:platformexamapp/core/theme/app_page_route.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10.h),
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back_ios,
                      color: textColor,
                      size: 20.r,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "create_account".tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 26.sp,
                      fontWeight: FontWeight.w900,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              GlassCard(
                padding: EdgeInsets.all(20.r),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      CustomTextFormField(
                        hintText: "name".tr(),
                        keyboardType: TextInputType.name,
                        controller: _nameController,
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedUser,
                          size: 20.r,
                          color: AppColors.softGold,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "name_required".tr();
                          }
                          if (v.trim().length < 3) {
                            return "name_length".tr();
                          }
                          if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(v)) {
                            return "name_invalid".tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),
                      CustomTextFormField(
                        hintText: "email".tr(),
                        keyboardType: TextInputType.emailAddress,
                        controller: _emailController,
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMail01,
                          size: 20.r,
                          color: AppColors.softGold,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return "email_required".tr();
                          }

                          final emailRegex = RegExp(
                            r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                          );

                          if (!emailRegex.hasMatch(v.trim())) {
                            return "email_invalid".tr();
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),
                      CustomTextFormField(
                        hintText: "password".tr(),
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: true,
                        controller: _passwordController,
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedLockPassword,
                          size: 20.r,
                          color: AppColors.softGold,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "password_required".tr();
                          }

                          if (v.length < 8) {
                            return "password_length".tr();
                          }

                          if (!RegExp(r'[A-Z]').hasMatch(v)) {
                            return "password_uppercase".tr();
                          }

                          if (!RegExp(r'[a-z]').hasMatch(v)) {
                            return "password_lowercase".tr();
                          }

                          if (!RegExp(r'[0-9]').hasMatch(v)) {
                            return "password_number".tr();
                          }

                          if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(v)) {
                            return "password_special".tr();
                          }

                          return null;
                        },
                      ),
                      SizedBox(height: 14.h),
                      CustomTextFormField(
                        hintText: "confirm_password".tr(),
                        keyboardType: TextInputType.visiblePassword,
                        obscureText: true,
                        controller: _confirmationPasswordController,
                        prefixIcon: HugeIcon(
                          icon: HugeIcons.strokeRoundedLockPassword,
                          size: 20.r,
                          color: AppColors.softGold,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return "confirm_password_required".tr();
                          }
                          if (v != _passwordController.text) {
                            return "passwords_dont_match".tr();
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 24.h),
                      BlocListener<AuthCubit, AuthState>(
                        listener: (context, state) {
                          if (state is AuthLoading) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (c) {
                                return const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.softGold,
                                  ),
                                );
                              },
                            );
                          }
                          if (state is AuthSuccess) {
                            Navigator.pop(context);
                            Navigator.pushAndRemoveUntil(
                              context,
                              AppPageRoute(child: const HomeScreen()),
                              (r) => false,
                            );
                          }
                          if (state is AuthError) {
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  state.errorMessage,
                                  style: GoogleFonts.cairo(color: Colors.white),
                                ),
                                backgroundColor: AppColors.heartRed,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                              ),
                            );
                          }
                        },
                        child: AppButton(
                          text: "register".tr(),
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
              ),
              SizedBox(height: 24.h),
              Center(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      AppPageRoute(child: const LoginScreen()),
                    );
                  },
                  child: CustomTextRich(
                    text1: "have_an_account".tr(),
                    text2: "sign_in".tr(),
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
