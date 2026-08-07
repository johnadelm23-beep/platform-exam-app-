import 'dart:convert';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineSyncService {
  static const String _queueKey = "offline_attendance_queue";
  static const String _seasonCacheKey = "cached_active_season_id";

  /// 🔹 Get Active Season ID (Queries Firestore when online, otherwise uses local cache)
  static Future<String> getActiveSeasonId() async {
    try {
      final query = await FirebaseFirestore.instance
          .collection("seasons")
          .where("status", isEqualTo: "active")
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final activeSeasonId = query.docs.first.id;
        // Cache locally for offline usage
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_seasonCacheKey, activeSeasonId);
        return activeSeasonId;
      }
    } catch (_) {
      // Offline fallback
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_seasonCacheKey) ?? "";
  }

  /// 🔹 Queue Attendance locally when offline
  static Future<void> queueAttendance({
    required String userId,
    required String eventId,
    required String adminId,
    required String dayType,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? queueStr = prefs.getString(_queueKey);
      List<dynamic> jsonList = [];
      if (queueStr != null && queueStr.isNotEmpty) {
        jsonList = json.decode(queueStr);
      }

      final isDuplicate = jsonList.any((item) =>
          item["userId"] == userId && item["eventId"] == eventId);

      if (!isDuplicate) {
        jsonList.add({
          "userId": userId,
          "eventId": eventId,
          "adminId": adminId,
          "dayType": dayType,
          "timestamp": DateTime.now().toIso8601String(),
        });
        await prefs.setString(_queueKey, json.encode(jsonList));
      }
    } catch (e) {
      print("Error queueing attendance: $e");
    }
  }

  /// 🔹 Calculates updated streak values (currentStreak, highestStreak)
  /// Rules:
  /// - Same calendar day: currentStreak stays unchanged
  /// - Yesterday (1 day difference): currentStreak + 1
  /// - Missed day (>1 day difference or null): currentStreak = 1
  /// - highestStreak = max(highestStreak, currentStreak)
  static Map<String, int> calculateStreakUpdate({
    required Map<String, dynamic>? userDataMap,
    required DateTime now,
  }) {
    int oldCurrentStreak = (userDataMap?["currentStreak"] ?? 0) as int;
    int oldHighestStreak = (userDataMap?["highestStreak"] ?? userDataMap?["longestStreak"] ?? 0) as int;

    DateTime? lastDate;
    final ts = userDataMap?["lastAttendanceDate"];
    if (ts is Timestamp) {
      lastDate = ts.toDate();
    } else if (ts is DateTime) {
      lastDate = ts;
    }

    int newCurrentStreak;
    if (lastDate == null) {
      newCurrentStreak = 1;
    } else {
      final lastDay = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final today = DateTime(now.year, now.month, now.day);
      final diffInDays = today.difference(lastDay).inDays;

      if (diffInDays == 0) {
        // Same day scan: do not increment streak
        newCurrentStreak = oldCurrentStreak > 0 ? oldCurrentStreak : 1;
      } else if (diffInDays == 1) {
        // Attended yesterday: continue streak
        newCurrentStreak = oldCurrentStreak + 1;
      } else {
        // Missed 1 or more days: reset streak to 1
        newCurrentStreak = 1;
      }
    }

    final newHighestStreak = math.max(oldHighestStreak, newCurrentStreak);

    return {
      "currentStreak": newCurrentStreak,
      "highestStreak": newHighestStreak,
    };
  }

  /// 🔹 Sync queued attendance items to Firestore
  static Future<void> syncQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? queueStr = prefs.getString(_queueKey);
      if (queueStr == null || queueStr.isEmpty) return;

      final List<dynamic> jsonList = json.decode(queueStr);
      if (jsonList.isEmpty) return;

      final seasonId = await getActiveSeasonId();
      if (seasonId.isEmpty) return;

      final firestore = FirebaseFirestore.instance;
      List<dynamic> remainingItems = [];

      for (var item in jsonList) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(item);
        final String userId = data["userId"];
        final String eventId = data["eventId"];
        final String adminId = data["adminId"];
        final String dayType = data["dayType"];

        final docId = "${eventId}_$userId";
        final docRef = firestore.collection("attendance").doc(docId);

        try {
          final docSnap = await docRef.get();
          if (docSnap.exists) {
            // Already synced
            continue;
          }

          final userRef = firestore.collection("users").doc(userId);
          final userSnap = await userRef.get();

          final streakResult = calculateStreakUpdate(
            userDataMap: userSnap.exists ? userSnap.data() as Map<String, dynamic> : null,
            now: DateTime.now(),
          );
          final currentStreak = streakResult["currentStreak"]!;
          final highestStreak = streakResult["highestStreak"]!;

          final batch = firestore.batch();

          batch.set(docRef, {
            "id": docId,
            "userId": userId,
            "eventId": eventId,
            "adminId": adminId,
            "timestamp": FieldValue.serverTimestamp(),
            "dayType": dayType,
            "seasonId": seasonId,
          });

          final Map<String, dynamic> userUpdates = {
            "totalAttendance": FieldValue.increment(1),
            "currentStreak": currentStreak,
            "longestStreak": highestStreak,
            "highestStreak": highestStreak,
            "lastAttendanceDate": FieldValue.serverTimestamp(),
          };

          if (dayType == "friday_meeting") {
            userUpdates["fridayAttendanceCount"] = FieldValue.increment(1);
          } else if (dayType == "sunday_activity") {
            userUpdates["sundayAttendanceCount"] = FieldValue.increment(1);
          }

          batch.update(userRef, userUpdates);

          await batch.commit();

          await recalculateAttendancePercentage(userId);
        } catch (e) {
          remainingItems.add(item);
        }
      }

      if (remainingItems.isEmpty) {
        await prefs.remove(_queueKey);
      } else {
        await prefs.setString(_queueKey, json.encode(remainingItems));
      }
    } catch (e) {
      print("Error syncing queue: $e");
    }
  }

  /// 🔹 Recalculate Attendance Percentage for a user
  static Future<void> recalculateAttendancePercentage(String userId) async {
    try {
      final seasonId = await getActiveSeasonId();
      final nowStr = DateTime.now().toIso8601String().substring(0, 10);

      QuerySnapshot eventsSnap;
      if (seasonId.isNotEmpty) {
        eventsSnap = await FirebaseFirestore.instance
            .collection("events")
            .where("seasonId", isEqualTo: seasonId)
            .get();
      } else {
        eventsSnap = await FirebaseFirestore.instance.collection("events").get();
      }

      final pastEventIds = <String>{};
      for (var doc in eventsSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final date = data["date"] as String? ?? "";
        if (date.isNotEmpty && date.compareTo(nowStr) <= 0) {
          pastEventIds.add(doc.id);
        }
      }

      if (pastEventIds.isEmpty) {
        await FirebaseFirestore.instance.collection("users").doc(userId).update({
          "attendancePercentage": 0.0,
        });
        return;
      }

      QuerySnapshot attendanceSnap;
      if (seasonId.isNotEmpty) {
        attendanceSnap = await FirebaseFirestore.instance
            .collection("attendance")
            .where("userId", isEqualTo: userId)
            .where("seasonId", isEqualTo: seasonId)
            .get();
      } else {
        attendanceSnap = await FirebaseFirestore.instance
            .collection("attendance")
            .where("userId", isEqualTo: userId)
            .get();
      }

      final attendedPastEventIds = <String>{};
      for (var doc in attendanceSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final eventId = data["eventId"] as String? ?? "";
        if (pastEventIds.contains(eventId)) {
          attendedPastEventIds.add(eventId);
        }
      }

      final rawPercentage = (attendedPastEventIds.length / pastEventIds.length) * 100.0;
      final roundedPercentage = double.parse(rawPercentage.toStringAsFixed(1));

      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "attendancePercentage": roundedPercentage,
      });
    } catch (e) {
      print("Error recalculating percentage: $e");
    }
  }

  /// 🔹 Reset all attendance data (Clears collection and updates users to default zero parameters)
  static Future<void> resetAttendanceData() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    final userDoc = await FirebaseFirestore.instance.collection("users").doc(currentUser.uid).get();
    if (userDoc.data()?["isAdmin"] != true) {
      throw Exception("Permission denied: Only Main Admin can reset attendance data.");
    }

    final firestore = FirebaseFirestore.instance;

    final attendanceSnap = await firestore.collection("attendance").get();
    final batch = firestore.batch();
    for (var doc in attendanceSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    final usersSnap = await firestore.collection("users").get();
    final usersBatch = firestore.batch();
    for (var doc in usersSnap.docs) {
      usersBatch.update(doc.reference, {
        "attendancePercentage": 0.0,
        "totalAttendance": 0,
        "currentStreak": 0,
        "longestStreak": 0,
        "highestStreak": 0,
        "fridayAttendanceCount": 0,
        "sundayAttendanceCount": 0,
      });
    }
    await usersBatch.commit();
  }
}
