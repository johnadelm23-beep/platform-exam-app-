import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/admin/ui/dashboard.dart';

void main() {
  group('UI Redesign & Theme Tokens Validation', () {
    test('Design Tokens match specified requirements', () {
      expect(AppColors.classicNavy, const Color(0xFF172B4D));
      expect(AppColors.accentTeal, const Color(0xFF16A6A1));
      expect(AppColors.warmIvory, const Color(0xFFF5F3EE));
      expect(AppColors.slate200, const Color(0xFFE2E8F0));
      expect(AppColors.slate500, const Color(0xFF64748B));
    });

    test('English and Arabic localization files contain all required redesign keys', () {
      final enFile = File('assets/translations/en.json');
      final arFile = File('assets/translations/ar.json');

      expect(enFile.existsSync(), isTrue);
      expect(arFile.existsSync(), isTrue);

      final Map<String, dynamic> enJson = jsonDecode(enFile.readAsStringSync());
      final Map<String, dynamic> arJson = jsonDecode(arFile.readAsStringSync());

      final requiredKeys = [
        "quick_access",
        "student_progress",
        "admin_command_center",
        "kpi_total_users",
        "kpi_total_exams",
        "kpi_active_events",
        "kpi_attendance_records",
        "attendance_and_pastoral",
        "exams_and_curriculum",
        "community_engagement",
        "system_administration",
        "scanner_desc",
        "followup_desc",
        "analytics_desc",
        "add_exam_desc",
        "grades_desc",
        "daily_content_desc",
        "content_history_desc",
        "add_post_desc",
        "top_interactions_desc",
        "bonus_desc",
        "users_desc",
        "events_desc",
        "seasons_desc",
        "nav_home",
        "nav_exams",
        "nav_results",
        "nav_profile"
      ];

      for (var key in requiredKeys) {
        expect(enJson.containsKey(key), isTrue, reason: "Missing English key: $key");
        expect(arJson.containsKey(key), isTrue, reason: "Missing Arabic key: $key");
        expect(enJson[key].toString().isNotEmpty, isTrue);
        expect(arJson[key].toString().isNotEmpty, isTrue);
      }
    });

    test('UserData role and permission access gates', () {
      final student = UserData(
        isAdmin: false,
        isSubAdmin: false,
      );
      expect(student.canAccessDashboard, isFalse);
      expect(student.canCreateExam, isFalse);
      expect(student.canAccessScanner, isFalse);

      final subAdmin = UserData(
        isAdmin: false,
        isSubAdmin: true,
      );
      expect(subAdmin.canAccessDashboard, isTrue);
      expect(subAdmin.canAccessScanner, isTrue);
      expect(subAdmin.canAccessFollowUp, isTrue);
      expect(subAdmin.canCreateExam, isFalse); // SubAdmin cannot create exams
      expect(subAdmin.canCreateContent, isFalse);

      final fullAdmin = UserData(
        isAdmin: true,
        isSubAdmin: false,
      );
      expect(fullAdmin.canAccessDashboard, isTrue);
      expect(fullAdmin.canCreateExam, isTrue);
      expect(fullAdmin.canManageEvents, isTrue);
      expect(fullAdmin.canManageSeasons, isTrue);
      expect(fullAdmin.canAccessScanner, isTrue);
    });

    testWidgets('AdminDashboardScreen denies access to non-admin users', (tester) async {
      final student = UserData(
        name: "John Student",
        isAdmin: false,
        isSubAdmin: false,
      );

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: AdminDashboardScreen(user: student),
          ),
        ),
      );

      expect(find.text("Access Denied"), findsOneWidget);
      expect(find.text("You do not have permission to access the Dashboard."), findsOneWidget);
    });
  });
}
