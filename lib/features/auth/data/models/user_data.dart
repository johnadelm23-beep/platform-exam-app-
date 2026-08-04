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

  // Personal Information
  String? phone;
  String? fatherPhone;
  String? motherPhone;
  String? address;
  String? school;
  String? university;
  String? work;
  String? group;

  // Follow Up Information
  String? followUpStatus; // "Excellent", "Regular", "Needs Follow-up", "Urgent"
  bool? needVisit;
  DateTime? lastContact;
  DateTime? lastCallDate;
  DateTime? lastVisitDate;
  String? notes;
  String? servantNotes;
  int? callsCount;
  int? visitsCount;

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
    this.phone,
    this.fatherPhone,
    this.motherPhone,
    this.address,
    this.school,
    this.university,
    this.work,
    this.group,
    this.followUpStatus,
    this.needVisit,
    this.lastContact,
    this.lastCallDate,
    this.lastVisitDate,
    this.notes,
    this.servantNotes,
    this.callsCount,
    this.visitsCount,
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

    // Personal info parsing
    phone = json["phone"] ?? json["phoneNumber"];
    fatherPhone = json["fatherPhone"];
    motherPhone = json["motherPhone"];
    address = json["address"];
    school = json["school"];
    university = json["university"];
    work = json["work"];
    group = json["group"] ?? "General";

    // Follow Up parsing
    followUpStatus = json["followUpStatus"] ?? "Regular";
    needVisit = json["needVisit"] ?? false;
    notes = json["notes"];
    servantNotes = json["servantNotes"];
    callsCount = json["callsCount"] ?? json["callsCompleted"] ?? 0;
    visitsCount = json["visitsCount"] ?? json["visitsCompleted"] ?? 0;

    // Dates parsing
    lastAttendanceDate = _parseDate(json["lastAttendanceDate"]);
    lastContact = _parseDate(json["lastContact"]);
    lastCallDate = _parseDate(json["lastCallDate"]);
    lastVisitDate = _parseDate(json["lastVisitDate"]);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return null;
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
      "phone": phone,
      "fatherPhone": fatherPhone,
      "motherPhone": motherPhone,
      "address": address,
      "school": school,
      "university": university,
      "work": work,
      "group": group,
      "followUpStatus": followUpStatus ?? "Regular",
      "needVisit": needVisit ?? false,
      "notes": notes,
      "servantNotes": servantNotes,
      "callsCount": callsCount ?? 0,
      "visitsCount": visitsCount ?? 0,
      "lastContact": lastContact == null ? null : Timestamp.fromDate(lastContact!),
      "lastCallDate": lastCallDate == null ? null : Timestamp.fromDate(lastCallDate!),
      "lastVisitDate": lastVisitDate == null ? null : Timestamp.fromDate(lastVisitDate!),
    };
  }

}
