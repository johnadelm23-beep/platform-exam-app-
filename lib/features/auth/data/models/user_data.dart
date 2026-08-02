import 'package:cloud_firestore/cloud_firestore.dart';

class UserData {
  String? uid;
  String? name;
  String? email;
  String? password;
  bool? isAdmin;
  String? profileImage;

  double? attendancePercentage;

  int? fridayAttendanceCount;
  int? sundayAttendanceCount;
  int? currentStreak;
  int? longestStreak;
  int? highestStreak;
  int? totalAttendance;
  int? totalAbsence;

  String? humanReadableId;

  DateTime? lastAttendanceDate;

  UserData({
    this.uid,
    this.name,
    this.email,
    this.password,
    this.isAdmin,
    this.profileImage,
    this.attendancePercentage,
    this.fridayAttendanceCount,
    this.sundayAttendanceCount,
    this.currentStreak,
    this.longestStreak,
    this.highestStreak,
    this.totalAttendance,
    this.totalAbsence,
    this.humanReadableId,
    this.lastAttendanceDate,
  });

  /// Getter for highest streak taking highestStreak or longestStreak fallback
  int get highestStreakVal => highestStreak ?? longestStreak ?? 0;

  /// Helper to calculate current active streak on display (resets to 0 if missed > 1 day)
  int get displayStreak {
    if (lastAttendanceDate == null) return 0;
    final now = DateTime.now();
    final lastDay = DateTime(
      lastAttendanceDate!.year,
      lastAttendanceDate!.month,
      lastAttendanceDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final diffInDays = today.difference(lastDay).inDays;
    if (diffInDays <= 1) {
      return currentStreak ?? 0;
    } else {
      return 0;
    }
  }

  UserData.fromJson(Map<String, dynamic> json, [String? docId]) {
    uid = docId ?? json["uid"];
    name = json["name"];
    email = json["email"];
    password = json["password"];
    isAdmin = json["isAdmin"] ?? false;
    profileImage = json["profileImage"];

    final attendance = json["attendancePercentage"];
    if (attendance is int) {
      attendancePercentage = attendance.toDouble();
    } else if (attendance is double) {
      attendancePercentage = attendance;
    } else {
      attendancePercentage = 0.0;
    }

    fridayAttendanceCount = json["fridayAttendanceCount"] ?? 0;
    sundayAttendanceCount = json["sundayAttendanceCount"] ?? 0;
    currentStreak = json["currentStreak"] ?? 0;
    longestStreak = json["longestStreak"] ?? json["highestStreak"] ?? 0;
    highestStreak = json["highestStreak"] ?? json["longestStreak"] ?? 0;
    totalAttendance = json["totalAttendance"] ?? 0;
    totalAbsence = json["totalAbsence"] ?? 0;
    humanReadableId = json["humanReadableId"];

    // Handle Firestore Timestamp safely
    final ts = json["lastAttendanceDate"];
    if (ts is Timestamp) {
      lastAttendanceDate = ts.toDate();
    } else {
      lastAttendanceDate = null;
    }
  }

  Map<String, dynamic> toJson() {
    final highest = highestStreakVal;
    return {
      "uid": uid,
      "name": name,
      "email": email,
      "password": password,
      "isAdmin": isAdmin ?? false,
      "profileImage": profileImage,
      "attendancePercentage": attendancePercentage ?? 0.0,
      "fridayAttendanceCount": fridayAttendanceCount ?? 0,
      "sundayAttendanceCount": sundayAttendanceCount ?? 0,
      "currentStreak": currentStreak ?? 0,
      "longestStreak": highest,
      "highestStreak": highest,
      "totalAttendance": totalAttendance ?? 0,
      "totalAbsence": totalAbsence ?? 0,
      "humanReadableId": humanReadableId,
      "lastAttendanceDate": lastAttendanceDate == null
          ? null
          : Timestamp.fromDate(lastAttendanceDate!),
    };
  }
}
