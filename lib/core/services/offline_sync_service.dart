import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

          int currentStreak = 1;
          int longestStreak = 1;

          if (userSnap.exists) {
            final userData = userSnap.data() as Map<String, dynamic>;
            currentStreak = (userData["currentStreak"] ?? 0) + 1;
            longestStreak = (userData["longestStreak"] ?? 0) as int;
          }

          if (currentStreak > longestStreak) {
            longestStreak = currentStreak;
          }

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
            "longestStreak": longestStreak,
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
      if (seasonId.isEmpty) return;

      final nowStr = DateTime.now().toIso8601String().substring(0, 10);
      final eventsSnap = await FirebaseFirestore.instance
          .collection("events")
          .where("seasonId", isEqualTo: seasonId)
          .get();

      int totalPastEvents = 0;
      for (var doc in eventsSnap.docs) {
        final date = doc.data()["date"] as String? ?? "";
        if (date.compareTo(nowStr) <= 0) {
          totalPastEvents++;
        }
      }

      final attendanceSnap = await FirebaseFirestore.instance
          .collection("attendance")
          .where("userId", isEqualTo: userId)
          .where("seasonId", isEqualTo: seasonId)
          .get();

      final attendedCount = attendanceSnap.docs.length;
      final percentage = totalPastEvents > 0
          ? (attendedCount / totalPastEvents) * 100.0
          : 0.0;

      await FirebaseFirestore.instance.collection("users").doc(userId).update({
        "attendancePercentage": percentage,
      });
    } catch (e) {
      print("Error recalculating percentage: $e");
    }
  }

  /// 🔹 Reset all attendance data (Clears collection and updates users to default zero parameters)
  static Future<void> resetAttendanceData() async {
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
        "fridayAttendanceCount": 0,
        "sundayAttendanceCount": 0,
      });
    }
    await usersBatch.commit();
  }
}
