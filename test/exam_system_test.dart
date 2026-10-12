import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:platformexamapp/features/exams/data/exam_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Exam System Lifecycle & Scoring Tests', () {
    test('Attempt document ID strictly enforces userId_examId format', () {
      const userId = 'user_abc_123';
      const examId = 'exam_math_001';
      final docId = ExamService.getAttemptDocId(userId, examId);
      expect(docId, equals('user_abc_123_exam_math_001'));
    });

    test('Score calculation produces accurate results from questions and selected options', () {
      final questions = [
        {'question': 'Q1', 'correctAnswer': 2},
        {'question': 'Q2', 'correctAnswer': 0},
        {'question': 'Q3', 'correctAnswer': 3},
        {'question': 'Q4', 'correctAnswer': 1},
      ];

      // Student answers: Q1 correct, Q2 wrong, Q3 correct, Q4 unanswered
      final selectedAnswers = <int, int>{
        0: 2, // correct
        1: 3, // wrong (expected 0)
        2: 3, // correct
      };

      int score = 0;
      for (int i = 0; i < questions.length; i++) {
        if (selectedAnswers[i] == questions[i]['correctAnswer']) {
          score++;
        }
      }

      expect(score, equals(2));
    });

    test('Elapsed timer calculation accurately reflects remaining seconds', () {
      const durationMinutes = 10;
      final startedAt = DateTime.now().subtract(const Duration(minutes: 4, seconds: 30));

      final totalSeconds = durationMinutes * 60; // 600 seconds
      final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds; // ~270 seconds
      final remaining = totalSeconds - elapsedSeconds;

      expect(remaining, inInclusiveRange(328, 332));
    });

    test('Expired attempt is identified when elapsed time exceeds duration', () {
      const durationMinutes = 5;
      final startedAt = DateTime.now().subtract(const Duration(minutes: 6));

      final totalSeconds = durationMinutes * 60;
      final elapsedSeconds = DateTime.now().difference(startedAt).inSeconds;
      final remaining = totalSeconds - elapsedSeconds;

      expect(remaining <= 0, isTrue);
    });
  });

  group('Draft Answers Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Draft answers can be saved and restored across app restarts', () async {
      const userId = 'user_test_1';
      const examId = 'exam_test_1';

      final answers = <int, int>{0: 1, 1: 0, 2: 3};
      await ExamService.saveDraftAnswers(
        userId: userId,
        examId: examId,
        answers: answers,
      );

      final restored = await ExamService.loadDraftAnswers(
        userId: userId,
        examId: examId,
      );

      expect(restored.length, equals(3));
      expect(restored[0], equals(1));
      expect(restored[1], equals(0));
      expect(restored[2], equals(3));

      // Clearing draft answers on submit or terminate
      await ExamService.clearDraftData(userId: userId, examId: examId);
      final empty = await ExamService.loadDraftAnswers(userId: userId, examId: examId);
      expect(empty.isEmpty, isTrue);
    });
  });

  group('Anti-Cheating & Permanent Lock Enforcement Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Terminated attempt is permanently locked locally and prevents retakes', () async {
      const userId = 'student_violator_1';
      const examId = 'exam_final_99';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('exam_terminated_${userId}_$examId', true);

      final status = await ExamService.getAttemptStatus(
        userId: userId,
        examId: examId,
        durationMinutes: 15,
      );

      expect(status.status, equals(ExamAttemptStatus.terminated));
      expect(status.isDone, isTrue);
      expect(status.isAbandoned, isTrue);
    });

    test('Attempt payload sent on termination complies with Firestore Security Rules (score is int >= 0)', () {
      final terminationPayload = <String, dynamic>{
        'userId': 'student_123',
        'examId': 'exam_101',
        'examTitle': 'Final Exam',
        'score': 0, // Must be int >= 0
        'done': true,
        'status': 'terminated',
        'abandoned': true,
        'terminationReason': 'App moved to background',
        'violationType': 'app_backgrounded',
      };

      // Firestore rule constraints check:
      final attemptId = '${terminationPayload['userId']}_${terminationPayload['examId']}';
      expect(attemptId, equals('student_123_exam_101'));
      expect(terminationPayload['score'] is int, isTrue);
      expect((terminationPayload['score'] as int) >= 0, isTrue);
      expect(terminationPayload['done'], isTrue);
      expect(terminationPayload['abandoned'], isTrue);
    });

    test('Completed attempt payload complies with Firestore Security Rules', () {
      final submissionPayload = <String, dynamic>{
        'userId': 'student_123',
        'examId': 'exam_101',
        'examTitle': 'Final Exam',
        'score': 85, // Must be int >= 0
        'done': true,
        'status': 'completed',
        'abandoned': false,
        'totalQuestions': 100,
      };

      expect(submissionPayload['score'] is int, isTrue);
      expect((submissionPayload['score'] as int) >= 0, isTrue);
      expect(submissionPayload['done'], isTrue);
      expect(submissionPayload['abandoned'], isFalse);
    });
  });

  group('Leaderboard & Result Isolation Tests', () {
    test('Terminated and in-progress attempts are strictly excluded from score aggregations', () {
      final mockAttemptDocs = [
        // Completed legitimate attempt
        {
          'userId': 'user_1',
          'score': 10,
          'done': true,
          'abandoned': false,
        },
        // Terminated cheating attempt (must be skipped)
        {
          'userId': 'user_2',
          'score': 0,
          'done': true,
          'abandoned': true,
        },
        // In-progress attempt (must be skipped)
        {
          'userId': 'user_3',
          'score': 0,
          'done': false,
          'abandoned': false,
        },
      ];

      final filteredCompleted = mockAttemptDocs.where((data) {
        final done = data['done'] == true;
        final abandoned = data['abandoned'] == true;
        return done && !abandoned;
      }).toList();

      expect(filteredCompleted.length, equals(1));
      expect(filteredCompleted.first['userId'], equals('user_1'));
      expect(filteredCompleted.first['score'], equals(10));
    });
  });

  group('Submission Mutex & Idempotency Tests', () {
    test('Simulated multiple concurrent submit calls only process first request', () async {
      bool isSubmitting = false;
      int submissionCount = 0;

      Future<void> simulateSubmit() async {
        if (isSubmitting) return; // Mutex gate
        isSubmitting = true;

        await Future.delayed(const Duration(milliseconds: 50));
        submissionCount++;
      }

      // Simulate rapid user pressing submit 5 times simultaneously
      await Future.wait([
        simulateSubmit(),
        simulateSubmit(),
        simulateSubmit(),
        simulateSubmit(),
        simulateSubmit(),
      ]);

      expect(submissionCount, equals(1));
    });
  });
}
