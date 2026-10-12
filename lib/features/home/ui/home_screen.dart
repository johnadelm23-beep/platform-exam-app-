import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/theme/theme_cubit.dart';
import 'package:platformexamapp/core/widgets/app_bottom_navigation.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/auth/ui/login_screen.dart';
import 'package:platformexamapp/features/exams/ui/exam_list_screen.dart';
import 'package:platformexamapp/features/home/cubit/cubit/home_cubit.dart';
import 'package:platformexamapp/features/home/ui/widgets/body_container.dart';
import 'package:platformexamapp/features/profile/ui/profile_screen.dart';
import 'package:platformexamapp/features/profile/ui/widgets/user_avatar.dart';
import 'package:platformexamapp/features/states/ui/states_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().getUserData();
  }

  void _onNavigateToTab(int index) {
    if (index >= 0 && index <= 3) {
      setState(() => _currentNavIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.warmIvory;

    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) {
        if (state is GetUserDataLoading) {
          return Scaffold(
            backgroundColor: pageBg,
            body: const LoadingState(),
          );
        }

        final user = context.watch<HomeCubit>().userData;
        if (user == null) {
          return Scaffold(
            backgroundColor: pageBg,
            body: const LoadingState(),
          );
        }

        final uid = FirebaseAuth.instance.currentUser?.uid ?? "";

        return PopScope(
          canPop: _currentNavIndex == 0,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop && _currentNavIndex != 0) {
              setState(() => _currentNavIndex = 0);
            }
          },
          child: Scaffold(
            backgroundColor: pageBg,
            extendBody: true,
            body: IndexedStack(
              index: _currentNavIndex,
              children: [
                // Tab 0: Home Content
                SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context, isDark, user),
                      Expanded(
                        child: BodyContainer(
                          uid: uid,
                          user: user,
                          onNavigateToTab: _onNavigateToTab,
                        ),
                      ),
                    ],
                  ),
                ),
                // Tab 1: Exams Screen
                ExamsScreen(user: user, isTab: true),
                // Tab 2: Leaderboard Screen
                const LeaderboardScreen(isTab: true),
                // Tab 3: Profile Screen
                const ProfileScreen(isTab: true),
              ],
            ),
            bottomNavigationBar: AppBottomNavigation(
              currentIndex: _currentNavIndex,
              onTap: _onNavigateToTab,
              items: [
                AppNavItem(
                  label: "nav_home".tr(),
                  icon: HugeIcons.strokeRoundedHome01,
                  onTap: () => _onNavigateToTab(0),
                ),
                AppNavItem(
                  label: "nav_exams".tr(),
                  icon: HugeIcons.strokeRoundedFile01,
                  onTap: () => _onNavigateToTab(1),
                ),
                AppNavItem(
                  label: "nav_results".tr(),
                  icon: HugeIcons.strokeRoundedChart01,
                  onTap: () => _onNavigateToTab(2),
                ),
                AppNavItem(
                  label: "nav_profile".tr(),
                  icon: HugeIcons.strokeRoundedUser02,
                  onTap: () => _onNavigateToTab(3),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, UserData user) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      child: Row(
        children: [
          // Avatar with profile tap
          GestureDetector(
            onTap: () => _onNavigateToTab(3),
            child: UserAvatar(
              imageUrl: user.profileImage,
              radius: 22.r,
              backgroundColor: AppColors.accentTeal.withValues(alpha: 0.15),
              iconColor: AppColors.accentTeal,
              border: Border.all(
                color: AppColors.accentTeal.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
          ),
          SizedBox(width: 12.w),

          // User Greeting & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "welcome_name".tr(args: [user.name ?? "User"]),
                  style: GoogleFonts.cairo(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: isDark
                        ? AppColors.darkTextMain
                        : AppColors.classicNavy,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7.r,
                      height: 7.r,
                      decoration: const BoxDecoration(
                        color: AppColors.accentTeal,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Flexible(
                      child: Text(
                        "Saint John Youth Meeting",
                        style: GoogleFonts.cairo(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.darkTextCaption
                              : AppColors.slate500,
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
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.slate200,
                ),
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
                horizontal: 10.w,
                vertical: 6.h,
              ),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.darkBorder
                      : AppColors.slate200,
                ),
              ),
              child: Text(
                context.locale.languageCode == 'ar'
                    ? "🇺🇸 EN"
                    : "🇪🇬 عربي",
                style: GoogleFonts.cairo(
                  color: isDark
                      ? AppColors.darkTextMain
                      : AppColors.classicNavy,
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
                  size: 34.r,
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
              padding: EdgeInsets.all(8.r),
              decoration: BoxDecoration(
                color: AppColors.heartRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.heartRed.withValues(alpha: 0.2),
                ),
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
    );
  }
}
