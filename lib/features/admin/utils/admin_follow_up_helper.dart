import 'package:flutter/material.dart';

class AdminFollowUpHelper {
  /// Attendance rule: User needs follow-up (محتاجين افتقاد) if percentage <= 70%
  static bool isNeedingFollowUp(double attendancePercentage) {
    return attendancePercentage <= 70.0;
  }

  /// Dynamic Status Key for internal state/filter mapping:
  /// 90% – 100% → Excellent
  /// 71% – 89%  → Regular
  /// 50% – 70%  → Needs Follow-up
  /// 0%  – 49%  → Urgent / Needs Visitation
  static String getDynamicStatusKey(double attendancePercentage) {
    if (attendancePercentage >= 90.0) {
      return "Excellent";
    } else if (attendancePercentage >= 71.0) {
      return "Regular";
    } else if (attendancePercentage >= 50.0) {
      return "Needs Follow-up";
    } else {
      return "Urgent";
    }
  }

  /// Dynamic Status Text display (Arabic/English localized fallback):
  /// 90% – 100% → ممتاز
  /// 71% – 89%  → منتظم
  /// 50% – 70%  → محتاج متابعة
  /// 0%  – 49%  → محتاج افتقاد
  static String getDynamicStatusText(
    double attendancePercentage, {
    bool isArabic = true,
  }) {
    if (attendancePercentage >= 90.0) {
      return isArabic ? "ممتاز" : "Excellent";
    } else if (attendancePercentage >= 71.0) {
      return isArabic ? "منتظم" : "Regular";
    } else if (attendancePercentage >= 50.0) {
      return isArabic ? "محتاج متابعة" : "Needs Follow-up";
    } else {
      return isArabic ? "محتاج افتقاد" : "Needs Visitation";
    }
  }

  /// Dynamic status badge color based on attendance percentage range
  static Color getStatusColor(double attendancePercentage) {
    if (attendancePercentage >= 90.0) {
      return const Color(0xFF2E7D32); // Green for ممتاز
    } else if (attendancePercentage >= 71.0) {
      return const Color(0xFF1976D2); // Blue for منتظم
    } else if (attendancePercentage >= 50.0) {
      return const Color(0xFFED6C02); // Orange for محتاج متابعة
    } else {
      return const Color(0xFFD32F2F); // Red for محتاج افتقاد
    }
  }
}
