import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:lottie/lottie.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/admin/cubit/follow_up_cubit.dart';
import 'package:platformexamapp/features/admin/cubit/follow_up_state.dart';
import 'package:platformexamapp/features/admin/services/follow_up_export_service.dart';
import 'package:platformexamapp/features/admin/ui/widgets/follow_up_details_dialog.dart';
import 'package:platformexamapp/features/admin/ui/widgets/follow_up_filters_widget.dart';
import 'package:platformexamapp/features/admin/ui/widgets/follow_up_user_card.dart';

class AdminFollowUpScreen extends StatelessWidget {
  const AdminFollowUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FollowUpCubit(),
      child: const _AdminFollowUpView(),
    );
  }
}

class _AdminFollowUpView extends StatelessWidget {
  const _AdminFollowUpView();

  void _showExportOptions(BuildContext context, FollowUpState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "export_report".tr(),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.primaryColor,
                ),
              ),
              SizedBox(height: 20.h),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFile01,
                    color: Colors.red,
                  ),
                ),
                title: Text("export_as_pdf".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  try {
                    await FollowUpExportService.exportToPdf(state.filteredUsers);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: EdgeInsets.all(10.r),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedGrid,
                    color: Colors.green,
                  ),
                ),
                title: Text("export_as_excel".tr(), style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  try {
                    await FollowUpExportService.exportToExcel(state.filteredUsers);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
                      );
                    }
                  }
                },
              ),
              SizedBox(height: 10.h),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.primaryColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : AppColors.primaryColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
        title: Text(
          "follow_up".tr(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.only(top: 8.h),
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24.r),
            topRight: Radius.circular(24.r),
          ),
        ),
        child: BlocConsumer<FollowUpCubit, FollowUpState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryColor),
              );
            }

            return CustomScrollView(
              slivers: [
                // 1. Search Bar & Filter Section (Starts directly at the top)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: FollowUpFiltersWidget(
                      searchQuery: state.searchQuery,
                      attendanceFilter: state.attendanceFilter,
                      needVisitFilter: state.needVisitFilter,
                      statusFilter: state.statusFilter,
                      onSearchChanged: (q) => context.read<FollowUpCubit>().setSearchQuery(q),
                      onAttendanceFilterChanged: (f) => context.read<FollowUpCubit>().setAttendanceFilter(f),
                      onNeedVisitFilterChanged: (f) => context.read<FollowUpCubit>().setNeedVisitFilter(f),
                      onStatusFilterChanged: (f) => context.read<FollowUpCubit>().setStatusFilter(f),
                    ),
                  ),
                ),

                // 2. Users List or Empty State
                if (state.filteredUsers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 140.w,
                            height: 140.h,
                            child: Lottie.asset(
                              "assets/lottie/Empty.json",
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.search_off_rounded,
                                size: 70.r,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "no_members_found".tr(),
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final user = state.filteredUsers[index];
                        return FollowUpUserCard(
                          user: user,
                          onCallRecorded: () {
                            if (user.uid != null) {
                              context.read<FollowUpCubit>().recordCall(user.uid!);
                            }
                          },
                          onEdit: () {
                            FollowUpDetailsDialog.show(context, user);
                          },
                          onDetails: () {
                            FollowUpDetailsDialog.show(context, user);
                          },
                        );
                      },
                      childCount: state.filteredUsers.length,
                    ),
                  ),

                SliverToBoxAdapter(child: SizedBox(height: 80.h)),
              ],
            );
          },
        ),
      ),
      floatingActionButton: BlocBuilder<FollowUpCubit, FollowUpState>(
        builder: (context, state) {
          return FloatingActionButton.extended(
            backgroundColor: AppColors.primaryColor,
            elevation: 4,
            onPressed: state.isLoading ? null : () => _showExportOptions(context, state),
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              color: Colors.white,
            ),
            label: Text(
              "export_report".tr(),
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    );
  }
}
