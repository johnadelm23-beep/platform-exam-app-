import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ExamAttemptStatus {
  available,
  inProgress,
  completed,
  terminated,
}

class ExamAttemptResult {
  final ExamAttemptStatus status;
  final int score;
  final String? terminationReason;
  final DateTime? startedAt;
  final int remainingSeconds;
  final Map<int, int> savedAnswers;
  final bool isDone;
  final bool isAbandoned;

  const ExamAttemptResult({
    required this.status,
    this.score = 0,
    this.terminationReason,
    this.startedAt,
    this.remainingSeconds = 0,
    this.savedAnswers = const {},
    this.isDone = false,
    this.isAbandoned = false,
  });
}

class ExamService {
  ExamService._();

  static String getAttemptDocId(String userId, String examId) =>
      "${userId}_$examId";

  static String _answersPrefKey(String userId, String examId) =>
      "exam_answers_${userId}_$examId";

  static String _startedAtPrefKey(String userId, String examId) =>
      "exam_started_at_${userId}_$examId";

  static String _terminatedPrefKey(String userId, String examId) =>
      "exam_terminated_${userId}_$examId";

  /// 🔹 Get Attempt Status and Timing Information
  static Future<ExamAttemptResult> getAttemptStatus({
    required String userId,
    required String examId,
    required int durationMinutes,
  }) async {
    if (userId.isEmpty || examId.isEmpty) {
      return const ExamAttemptResult(status: ExamAttemptStatus.available);
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // Check local permanent termination lock first for instant offline response
      final localTerminated = prefs.getBool(_terminatedPrefKey(userId, examId)) ?? false;
      if (localTerminated) {
        return const ExamAttemptResult(
          status: ExamAttemptStatus.terminated,
          terminationReason: "Exam was terminated due to a violation",
          isDone: true,
          isAbandoned: true,
        );
      }

      final docRef = FirebaseFirestore.instance
          .collection("examAttempts")
          .doc(getAttemptDocId(userId, examId));

      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final isDone = data["done"] == true;
        final isAbandoned = data["abandoned"] == true;
        final statusStr = (data["status"] as String?) ?? "";
        final score = (data["score"] as num?)?.toInt() ?? 0;
        final terminationReason = data["terminationReason"] as String?;

        if (isAbandoned || statusStr == "terminated" || localTerminated) {
          return ExamAttemptResult(
            status: ExamAttemptStatus.terminated,
            score: score,
            terminationReason: terminationReason ?? "Violation of exam rules",
            isDone: true,
            isAbandoned: true,
          );
        }

        if (isDone || statusStr == "completed") {
          return ExamAttemptResult(
            status: ExamAttemptStatus.completed,
            score: score,
            isDone: true,
            isAbandoned: false,
          );
        }

        // In Progress Attempt
        DateTime? startedAt;
        final ts = data["startedAt"];
        if (ts is Timestamp) {
          startedAt = ts.toDate();
        } else {
          final localStartedMs = prefs.getInt(_startedAtPrefKey(userId, examId));
          if (localStartedMs != null) {
            startedAt = DateTime.fromMillisecondsSinceEpoch(localStartedMs);
          }
        }

        // Load any saved draft answers
        final savedAnswers = await loadDraftAnswers(userId: userId, examId: examId);

        if (startedAt != null) {
          final totalSeconds = durationMinutes * 60;
          final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
          final remainingSeconds = totalSeconds - elapsedSeconds;

          return ExamAttemptResult(
            status: ExamAttemptStatus.inProgress,
            startedAt: startedAt,
            remainingSeconds: remainingSeconds > 0 ? remainingSeconds : 0,
            savedAnswers: savedAnswers,
            isDone: false,
            isAbandoned: false,
          );
        }

        return ExamAttemptResult(
          status: ExamAttemptStatus.inProgress,
          remainingSeconds: durationMinutes * 60,
          savedAnswers: savedAnswers,
          isDone: false,
          isAbandoned: false,
        );
      }

      if (localTerminated) {
        return const ExamAttemptResult(
          status: ExamAttemptStatus.terminated,
          terminationReason: "Exam was terminated",
          isDone: true,
          isAbandoned: true,
        );
      }
    } catch (e) {
      debugPrint("Error fetching exam attempt status: $e");
    }

    return const ExamAttemptResult(status: ExamAttemptStatus.available);
  }

  /// 🔹 Start New Exam Attempt (persisted on Firestore & SharedPreferences)
  static Future<void> startExamAttempt({
    required String userId,
    required String examId,
    required String title,
    required int durationMinutes,
  }) async {
    final now = DateTime.now();

    // 1. Save local timing immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_startedAtPrefKey(userId, examId), now.millisecondsSinceEpoch);

    // 2. Persist in Firestore
    final docRef = FirebaseFirestore.instance
        .collection("examAttempts")
        .doc(getAttemptDocId(userId, examId));

    await docRef.set({
      "userId": userId,
      "examId": examId,
      "examTitle": title,
      "score": 0,
      "done": false,
      "status": "in_progress",
      "abandoned": false,
      "startedAt": FieldValue.serverTimestamp(),
      "createdAt": FieldValue.serverTimestamp(),
      "timestamp": FieldValue.serverTimestamp(),
      "totalDurationMinutes": durationMinutes,
    }, SetOptions(merge: true));
  }

  /// 🔹 Save Draft Answers
  static Future<void> saveDraftAnswers({
    required String userId,
    required String examId,
    required Map<int, int> answers,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stringMap = answers.map((k, v) => MapEntry(k.toString(), v));
      await prefs.setString(_answersPrefKey(userId, examId), json.encode(stringMap));
    } catch (e) {
      debugPrint("Error saving draft answers locally: $e");
    }
  }

  /// 🔹 Load Draft Answers
  static Future<Map<int, int>> loadDraftAnswers({
    required String userId,
    required String examId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_answersPrefKey(userId, examId));
      if (str != null && str.isNotEmpty) {
        final decoded = json.decode(str) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(int.parse(k), (v as num).toInt()));
      }
    } catch (e) {
      debugPrint("Error loading draft answers: $e");
    }
    return {};
  }

  /// 🔹 Submit Exam (Idempotent, Atomic, Permanently Locks Attempt)
  static Future<bool> submitExamAttempt({
    required String userId,
    required String examId,
    required String title,
    required int score,
    required int totalQuestions,
  }) async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection("examAttempts")
          .doc(getAttemptDocId(userId, examId));

      // Check current state before writing
      final existingDoc = await docRef.get();
      if (existingDoc.exists) {
        final data = existingDoc.data();
        if (data != null && data["done"] == true) {
          // Already submitted or terminated; preserve first result
          await clearDraftData(userId: userId, examId: examId);
          return true;
        }
      }

      await docRef.set({
        "userId": userId,
        "examId": examId,
        "examTitle": title,
        "score": score,
        "done": true, // PERMANENT LOCK via firestore.rules
        "status": "completed",
        "abandoned": false,
        "totalQuestions": totalQuestions,
        "completedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await clearDraftData(userId: userId, examId: examId);
      return true;
    } catch (e) {
      debugPrint("Error submitting exam: $e");
      rethrow;
    }
  }

  /// 🔹 Terminate Exam for Anti-Cheating Violation (Permanently Locked)
  static Future<bool> terminateExamAttempt({
    required String userId,
    required String examId,
    required String title,
    required String reason,
    required String violationType,
  }) async {
    try {
      // 1. Permanently lock locally first
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_terminatedPrefKey(userId, examId), true);

      final docRef = FirebaseFirestore.instance
          .collection("examAttempts")
          .doc(getAttemptDocId(userId, examId));

      // 2. Check if already marked done
      final existingDoc = await docRef.get();
      if (existingDoc.exists) {
        final data = existingDoc.data();
        if (data != null && data["done"] == true) {
          await clearDraftData(userId: userId, examId: examId);
          return true;
        }
      }

      // 3. Atomically write termination record to Firestore
      await docRef.set({
        "userId": userId,
        "examId": examId,
        "examTitle": title,
        "score": 0,
        "done": true, // PERMANENT LOCK via firestore.rules
        "status": "terminated",
        "abandoned": true, // Compatible with leaderboard & stats filtering
        "terminationReason": reason,
        "violationType": violationType,
        "terminatedAt": FieldValue.serverTimestamp(),
        "timestamp": FieldValue.serverTimestamp(),
        "createdAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await clearDraftData(userId: userId, examId: examId);
      return true;
    } catch (e) {
      debugPrint("Error terminating exam attempt: $e");
      return false;
    }
  }

  /// 🔹 Clear Draft Data from SharedPreferences
  static Future<void> clearDraftData({
    required String userId,
    required String examId,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_answersPrefKey(userId, examId));
      await prefs.remove(_startedAtPrefKey(userId, examId));
    } catch (e) {
      debugPrint("Error clearing draft data: $e");
    }
  }
}
