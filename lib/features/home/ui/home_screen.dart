import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/theme_cubit.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/ui/login_screen.dart';
import 'package:platformexamapp/features/home/cubit/cubit/home_cubit.dart';
import 'package:platformexamapp/features/home/ui/widgets/body_container.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().getUserData();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is GetUserDataLoading) {
              return const LoadingState();
            }
            final user = context.watch<HomeCubit>().userData;
            if (user == null) {
              return const LoadingState();
            }
            final uid = FirebaseAuth.instance.currentUser!.uid;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🌟 HERO APP BAR / HEADER
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 14.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "welcome_name".tr(args: [user.name ?? "User"]),
                              style: GoogleFonts.cairo(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.w900,
                                color: isDark
                                    ? AppColors.darkTextMain
                                    : AppColors.lightTextMain,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 2.h),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8.r,
                                  height: 8.r,
                                  decoration: const BoxDecoration(
                                    color: AppColors.softGold,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 6.w),
                                Flexible(
                                  child: Text(
                                    "Saint John Youth Meeting",
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.sp,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.softGold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      SizedBox(width: 8.w),

                      /// ☀️/🌙 THEME TOGGLE
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          context.read<ThemeCubit>().toggleTheme();
                        },
                        icon: Container(
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.cinematicNavy.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            color: AppColors.softGold,
                            size: 18.r,
                          ),
                        ),
                      ),

                      SizedBox(width: 6.w),

                      /// 🌐 LANGUAGE SWITCHER
                      GestureDetector(
                        onTap: () {
                          if (context.locale.languageCode == 'ar') {
                            context.setLocale(const Locale('en'));
                          } else {
                            context.setLocale(const Locale('ar'));
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : AppColors.cinematicNavy.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder,
                            ),
                          ),
                          child: Text(
                            context.locale.languageCode == 'ar'
                                ? "🇺🇸 EN"
                                : "🇪🇬 عربي",
                            style: GoogleFonts.cairo(
                              color: isDark
                                  ? AppColors.darkTextMain
                                  : AppColors.lightTextMain,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(width: 6.w),

                      /// 🚪 LOGOUT BUTTON
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          AppDialog.show(
                            context: context,
                            iconWidget: HugeIcon(
                              icon: HugeIcons.strokeRoundedLogout01,
                              color: AppColors.heartRed,
                              size: 36.r,
                            ),
                            iconColor: AppColors.heartRed,
                            title: "logout".tr(),
                            description: "logout_confirmation".tr(),
                            confirmText: "logout".tr(),
                            confirmButtonColor: AppColors.heartRed,
                            cancelText: "cancel".tr(),
                            onConfirm: () async {
                              Navigator.pop(context); // Close dialog
                              await FirebaseAuth.instance.signOut();
                              if (!context.mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                    create: (_) => AuthCubit(),
                                    child: const LoginScreen(),
                                  ),
                                ),
                                (route) => false,
                              );
                            },
                            onCancel: () => Navigator.pop(context),
                          );
                        },
                        icon: Container(
                          padding: EdgeInsets.all(7.r),
                          decoration: BoxDecoration(
                            color: AppColors.heartRed.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedLogout01,
                            color: AppColors.heartRed,
                            size: 18.r,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: BodyContainer(uid: uid, user: user),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
