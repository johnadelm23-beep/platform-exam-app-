import 'package:flutter_test/flutter_test.dart';

class GameQuestionModel {
  final String id;
  final int order;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final int timeLimit;
  final int points;

  GameQuestionModel({
    required this.id,
    required this.order,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.timeLimit,
    required this.points,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'order': order,
    'questionText': questionText,
    'options': options,
    'correctAnswerIndex': correctAnswerIndex,
    'timeLimit': timeLimit,
    'points': points,
  };

  factory GameQuestionModel.fromJson(Map<String, dynamic> json) =>
      GameQuestionModel(
        id: json['id'] as String,
        order: json['order'] as int,
        questionText: json['questionText'] as String,
        options: List<String>.from(json['options'] as List),
        correctAnswerIndex: json['correctAnswerIndex'] as int,
        timeLimit: json['timeLimit'] as int,
        points: json['points'] as int,
      );
}

class GameModel {
  final String id;
  final String title;
  final String description;
  final String pin;
  final String status;
  final int currentQuestionIndex;
  final int timePerQuestion;
  final String createdBy;
  final List<GameQuestionModel> questions;

  GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pin,
    required this.status,
    required this.currentQuestionIndex,
    required this.timePerQuestion,
    required this.createdBy,
    required this.questions,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'pin': pin,
    'status': status,
    'currentQuestionIndex': currentQuestionIndex,
    'timePerQuestion': timePerQuestion,
    'createdBy': createdBy,
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  factory GameModel.fromJson(Map<String, dynamic> json) => GameModel(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    pin: json['pin'] as String,
    status: json['status'] as String,
    currentQuestionIndex: json['currentQuestionIndex'] as int,
    timePerQuestion: json['timePerQuestion'] as int,
    createdBy: json['createdBy'] as String,
    questions: (json['questions'] as List)
        .map((q) => GameQuestionModel.fromJson(q as Map<String, dynamic>))
        .toList(),
  );
}

class LocalGameServerService {
  static final LocalGameServerService instance = LocalGameServerService._();
  LocalGameServerService._();

  int calculatePoints({
    required int remainingMs,
    required int totalMs,
    required bool isCorrect,
    required int maxPoints,
  }) {
    if (!isCorrect) return 0;
    if (totalMs <= 0) return maxPoints ~/ 2;
    final ratio = (remainingMs / totalMs).clamp(0.0, 1.0);
    return ((maxPoints * 0.5) + (maxPoints * 0.5 * ratio)).round();
  }
}

void main() {
  group('Local Game Offline Quiz Tests', () {
    test('Kahoot speed scoring formula produces correct points', () {
      final server = LocalGameServerService.instance;

      // Correct answer with 100% time left -> 100 points
      final fullPoints = server.calculatePoints(
        remainingMs: 15000,
        totalMs: 15000,
        isCorrect: true,
        maxPoints: 100,
      );
      expect(fullPoints, equals(100));

      // Correct answer with 0% time left -> 50 points
      final minPoints = server.calculatePoints(
        remainingMs: 0,
        totalMs: 15000,
        isCorrect: true,
        maxPoints: 100,
      );
      expect(minPoints, equals(50));

      // Incorrect answer -> 0 points
      final wrongPoints = server.calculatePoints(
        remainingMs: 10000,
        totalMs: 15000,
        isCorrect: false,
        maxPoints: 100,
      );
      expect(wrongPoints, equals(0));
    });

    test('GameModel & GameQuestionModel JSON serialization works offline', () {
      final question = GameQuestionModel(
        id: "q_test",
        order: 0,
        questionText: "Who led Israel across the Red Sea?",
        options: ["Joshua", "Moses", "Aaron", "David"],
        correctAnswerIndex: 1,
        timeLimit: 20,
        points: 100,
      );

      final game = GameModel(
        id: "game_test",
        title: "Exodus Test",
        description: "Test Bible Quiz",
        pin: "4821",
        status: "draft",
        currentQuestionIndex: 0,
        timePerQuestion: 20,
        createdBy: "Host",
        questions: [question],
      );

      final json = game.toJson();
      final restored = GameModel.fromJson(json);

      expect(restored.id, equals("game_test"));
      expect(restored.title, equals("Exodus Test"));
      expect(restored.questions.length, equals(1));
      expect(
        restored.questions.first.questionText,
        equals("Who led Israel across the Red Sea?"),
      );
      expect(restored.questions.first.correctAnswerIndex, equals(1));
    });
  });
}
