import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/theme_cubit.dart';
import 'package:platformexamapp/core/widgets/app_bottom_navigation.dart';

void main() {
  group('1. Localization Completeness & Parity Tests', () {
    late Map<String, dynamic> enJson;
    late Map<String, dynamic> arJson;

    setUpAll(() {
      final enFile = File('assets/translations/en.json');
      final arFile = File('assets/translations/ar.json');

      expect(enFile.existsSync(), isTrue, reason: 'en.json must exist');
      expect(arFile.existsSync(), isTrue, reason: 'ar.json must exist');

      enJson = json.decode(enFile.readAsStringSync()) as Map<String, dynamic>;
      arJson = json.decode(arFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('Both en.json and ar.json contain valid non-empty JSON maps', () {
      expect(enJson.isNotEmpty, isTrue);
      expect(arJson.isNotEmpty, isTrue);
      expect(enJson.length, greaterThan(350));
      expect(arJson.length, greaterThan(350));
    });

    test('en.json and ar.json have 100% key parity with 0 missing keys', () {
      final enKeys = enJson.keys.toSet();
      final arKeys = arJson.keys.toSet();

      final missingInAr = enKeys.difference(arKeys);
      final missingInEn = arKeys.difference(enKeys);

      expect(missingInAr, isEmpty, reason: 'Keys in en.json missing from ar.json: $missingInAr');
      expect(missingInEn, isEmpty, reason: 'Keys in ar.json missing from en.json: $missingInEn');
      expect(enKeys.length, equals(arKeys.length));
    });

    test('Specific keys requested by prompt exist in both languages and are non-empty', () {
      final requiredKeys = [
        'student_progress',
        'quick_access',
        'exams',
        'nav_home',
        'nav_exams',
        'nav_results',
        'nav_profile',
        'my_profile',
        'attendance',
        'attendance_history',
        'grades',
        'notifications',
        'settings',
        'loading',
        'error',
        'retry',
        'cancel',
        'save',
        'submit',
        'search',
        'no_data',
        'see_all',
        'share_to_whatsapp',
        'members_needing_followup',
        'all_members_healthy',
        'no_questions_found',
        'no_exams',
        'Highest',
        'attendance_analytics',
        'Attended',
        'Absent',
        'admin_full_privileges',
        'sub_admin_access',
        'role_admin',
        'role_sub_admin',
        'honoring_achievements',
        'you',
      ];

      for (final key in requiredKeys) {
        expect(enJson.containsKey(key), isTrue, reason: 'en.json missing key: $key');
        expect(arJson.containsKey(key), isTrue, reason: 'ar.json missing key: $key');

        final enVal = enJson[key]?.toString().trim() ?? '';
        final arVal = arJson[key]?.toString().trim() ?? '';

        expect(enVal, isNotEmpty, reason: 'en.json has empty value for key: $key');
        expect(arVal, isNotEmpty, reason: 'ar.json has empty value for key: $key');
      }
    });

    test('Arabic translations contain authentic Arabic unicode characters', () {
      final arabicRegex = RegExp(r'[\u0600-\u06FF]');

      // Check key translations to guarantee genuine Arabic strings
      expect(arabicRegex.hasMatch(arJson['student_progress']), isTrue);
      expect(arabicRegex.hasMatch(arJson['quick_access']), isTrue);
      expect(arabicRegex.hasMatch(arJson['exams']), isTrue);
      expect(arabicRegex.hasMatch(arJson['nav_home']), isTrue);
      expect(arabicRegex.hasMatch(arJson['my_profile']), isTrue);
    });
  });

  group('2. ThemeCubit & Persistent Preferences Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('ThemeCubit initializes to dark mode by default when no preference is stored', () async {
      final cubit = ThemeCubit();
      expect(cubit.state, equals(ThemeMode.dark));
      cubit.close();
    });

    test('ThemeCubit persists light and dark mode to SharedPreferences across restarts', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit1 = ThemeCubit();

      // Change to light mode
      await cubit1.setThemeMode(ThemeMode.light);
      expect(cubit1.state, equals(ThemeMode.light));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_theme_mode'), equals('light'));
      await cubit1.close();

      // Simulate app restart by instantiating new ThemeCubit with pre-stored value
      final cubit2 = ThemeCubit();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit2.state, equals(ThemeMode.light), reason: 'Must restore light mode from SharedPreferences');
      await cubit2.close();
    });

    test('ThemeCubit toggleTheme cycles between dark and light modes correctly', () async {
      SharedPreferences.setMockInitialValues({});
      final cubit = ThemeCubit();
      expect(cubit.state, equals(ThemeMode.dark));

      await cubit.toggleTheme();
      expect(cubit.state, equals(ThemeMode.light));

      await cubit.toggleTheme();
      expect(cubit.state, equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('user_theme_mode'), equals('dark'));

      await cubit.close();
    });
  });

  group('3. Persistent Bottom Navigation Architecture Tests', () {
    testWidgets('AppBottomNavigation renders all 4 items and handles tab switching', (tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(375, 812),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: const Text("Body Content"),
              bottomNavigationBar: StatefulBuilder(
                builder: (context, setState) {
                  return AppBottomNavigation(
                    currentIndex: selectedIndex,
                    onTap: (index) {
                      setState(() {
                        selectedIndex = index;
                      });
                    },
                    items: [
                      AppNavItem(
                        label: "Home",
                        icon: HugeIcons.strokeRoundedHome01,
                        onTap: () => setState(() => selectedIndex = 0),
                      ),
                      AppNavItem(
                        label: "Exams",
                        icon: HugeIcons.strokeRoundedFile01,
                        onTap: () => setState(() => selectedIndex = 1),
                      ),
                      AppNavItem(
                        label: "Results",
                        icon: HugeIcons.strokeRoundedChart01,
                        onTap: () => setState(() => selectedIndex = 2),
                      ),
                      AppNavItem(
                        label: "Profile",
                        icon: HugeIcons.strokeRoundedUser02,
                        onTap: () => setState(() => selectedIndex = 3),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify all 4 tabs exist
      expect(find.text("Home"), findsOneWidget);
      expect(find.byType(HugeIcon), findsNWidgets(4));

      // Tap on Exams (second tab)
      await tester.tap(find.byType(InkWell).at(1));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(1));

      // Tap on Profile (fourth tab)
      await tester.tap(find.byType(InkWell).at(3));
      await tester.pumpAndSettle();

      expect(selectedIndex, equals(3));
    });

    testWidgets('IndexedStack preserves tab state without destroying non-active screens', (tester) async {
      int activeIndex = 0;
      int tab0BuildCount = 0;
      int tab1BuildCount = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: IndexedStack(
                  index: activeIndex,
                  children: [
                    Builder(
                      builder: (context) {
                        tab0BuildCount++;
                        return const Text("Tab 0 Screen");
                      },
                    ),
                    Builder(
                      builder: (context) {
                        tab1BuildCount++;
                        return const Text("Tab 1 Screen");
                      },
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () {
                    setState(() {
                      activeIndex = (activeIndex == 0) ? 1 : 0;
                    });
                  },
                ),
              ),
            );
          },
        ),
      );

      expect(find.text("Tab 0 Screen"), findsOneWidget);
      expect(tab0BuildCount, equals(1));
      expect(tab1BuildCount, equals(1));

      // Switch to tab 1
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text("Tab 1 Screen"), findsOneWidget);
      // Both tabs remain in tree, preserved by IndexedStack
      expect(find.text("Tab 0 Screen", skipOffstage: false), findsOneWidget);
    });
  });
}
