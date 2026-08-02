import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
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
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            if (state is GetUserDataLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            final user = context.watch<HomeCubit>().userData;
            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            final uid = FirebaseAuth.instance.currentUser!.uid;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "welcome_name".tr(args: [user.name ?? "User"]),
                          style: TextStyle(
                            fontSize: 26.sp,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            context.locale.languageCode == 'ar'
                                ? "🇺🇸 English"
                                : "🇪🇬 عربي",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton(
                        onPressed: () {
                          AppDialog.show(
                            context: context,
                            icon: IconlyLight.logout,
                            iconColor: Colors.red,
                            title: "logout".tr(),
                            description: "logout_confirmation".tr(),
                            confirmText: "logout".tr(),
                            confirmButtonColor: Colors.red,
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
                        icon: Icon(
                          IconlyLight.logout,
                          color: Colors.white,
                          size: 24.r,
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
