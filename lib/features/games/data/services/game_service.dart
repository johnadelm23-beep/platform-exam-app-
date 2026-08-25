import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';
import 'package:platformexamapp/features/games/data/models/game_model.dart';

class GameService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Centralized Kahoot-style speed scoring formula: 500 to 1000 points
  int calculatePoints({
    required int secondsLeft,
    required int timeLimit,
    required bool isCorrect,
  }) {
    if (!isCorrect || timeLimit <= 0) return 0;
    final double ratio = (secondsLeft / timeLimit).clamp(0.0, 1.0);
    return (1000 * (1 - ratio * 0.5)).round();
  }

  /// Check active session for user across all active games
  Future<Map<String, String>?> checkActiveUserSession(String userId) async {
    try {
      final activeGamesSnap = await _firestore
          .collection("games")
          .where("status", whereIn: ["lobby", "question_active", "question_result", "question_leaderboard", "paused"])
          .get();

      for (var doc in activeGamesSnap.docs) {
        final userTeamSnap = await doc.reference.collection("userTeams").doc(userId).get();
        if (userTeamSnap.exists) {
          final data = userTeamSnap.data();
          return {
            "gameId": doc.id,
            "teamId": data?["teamId"] as String? ?? "",
            "teamName": data?["teamName"] as String? ?? "Team",
            "teamEmoji": data?["teamEmoji"] as String? ?? "🦁",
          };
        }
      }
    } catch (_) {}
    return null;
  }

  /// Generate unique 6-digit Game PIN
  String generateGamePin() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final pin = (now % 900000 + 100000).toString();
    return pin;
  }

  /// Delete old session subcollection documents when a new live lobby is launched
  Future<void> _clearOldSessionData(String gameId) async {
    final gameRef = _firestore.collection("games").doc(gameId);

    // 1. Delete teams subcollection & nested member subcollections
    final teamsSnap = await gameRef.collection("teams").get();
    for (var teamDoc in teamsSnap.docs) {
      final membersSnap = await teamDoc.reference.collection("members").get();
      for (var mDoc in membersSnap.docs) {
        await mDoc.reference.delete();
      }
      await teamDoc.reference.delete();
    }

    // 2. Delete userTeams subcollection
    final userTeamsSnap = await gameRef.collection("userTeams").get();
    for (var uDoc in userTeamsSnap.docs) {
      await uDoc.reference.delete();
    }

    // 3. Delete answers subcollection
    final answersSnap = await gameRef.collection("answers").get();
    for (var aDoc in answersSnap.docs) {
      await aDoc.reference.delete();
    }
  }

  /// Atomic Team Join Transaction enforcing unique team name, 1 team/user, and capacity limit
  Future<void> joinTeam({
    required String gameId,
    required String selectedTeamId,
    required String teamName,
    required String teamEmoji,
    required UserData user,
  }) async {
    final gameRef = _firestore.collection("games").doc(gameId);
    final teamsCollRef = gameRef.collection("teams");
    final teamRef = teamsCollRef.doc(selectedTeamId);
    final memberRef = teamRef.collection("members").doc(user.uid);
    final userTeamRef = gameRef.collection("userTeams").doc(user.uid);

    // Perform Team Name uniqueness check before transaction
    final existingTeamsSnap = await teamsCollRef.get();
    final normalizedNewName = teamName.trim().toLowerCase();

    for (var doc in existingTeamsSnap.docs) {
      if (doc.id != selectedTeamId) {
        final existingName = (doc.data()["name"] as String? ?? doc.data()["teamName"] as String? ?? "").trim().toLowerCase();
        if (existingName == normalizedNewName) {
          throw "Team name already exists!";
        }
      }
    }

    await _firestore.runTransaction((transaction) async {
      final userTeamSnap = await transaction.get(userTeamRef);
      if (userTeamSnap.exists) {
        final existingName = userTeamSnap.data()?["teamName"] as String? ?? "another team";
        throw "You are already a member of $existingName";
      }

      final gameSnap = await transaction.get(gameRef);
      if (!gameSnap.exists) throw "Game session not found";

      final game = GameModel.fromSnapshot(gameSnap);

      final teamSnap = await transaction.get(teamRef);
      int currentMemberCount = 0;
      int maxMembers = game.maxMembersPerTeam;

      if (teamSnap.exists) {
        currentMemberCount = (teamSnap.data()?["memberCount"] as num?)?.toInt() ?? 0;
        maxMembers = (teamSnap.data()?["maxMembers"] as num?)?.toInt() ?? game.maxMembersPerTeam;

        if (currentMemberCount >= maxMembers) {
          throw "This team is already full!";
        }

        transaction.update(teamRef, {
          "name": teamName.trim(),
          "teamName": teamName.trim(),
          "emoji": teamEmoji.trim(),
          "teamEmoji": teamEmoji.trim(),
          "memberCount": currentMemberCount + 1,
          "isParticipating": true,
        });
      } else {
        transaction.set(teamRef, {
          "name": teamName.trim(),
          "teamName": teamName.trim(),
          "emoji": teamEmoji.trim(),
          "teamEmoji": teamEmoji.trim(),
          "score": 0,
          "rank": 0,
          "memberCount": 1,
          "maxMembers": maxMembers,
          "isParticipating": true,
        });
      }

      transaction.set(memberRef, {
        "displayName": user.name ?? "Player",
        "joinedAt": FieldValue.serverTimestamp(),
      });

      transaction.set(userTeamRef, {
        "teamId": selectedTeamId,
        "teamName": teamName,
        "teamEmoji": teamEmoji,
        "joinedAt": FieldValue.serverTimestamp(),
      });
    });
  }

  /// Atomic Team Answer Submission Transaction enforcing 1 answer/team/question & protected server-side answer evaluation
  Future<void> submitTeamAnswer({
    required String gameId,
    required int questionIndex,
    required String teamId,
    required String teamName,
    required String teamEmoji,
    required String userId,
    required String userName,
    required int selectedOption,
  }) async {
    final gameRef = _firestore.collection("games").doc(gameId);
    final questionsRef = gameRef.collection("questions");
    final answerDocId = "q${questionIndex}_team_$teamId";
    final answerRef = gameRef.collection("answers").doc(answerDocId);
    final teamRef = gameRef.collection("teams").doc(teamId);

    // Fetch Question metadata before transaction
    final qQuery = await questionsRef.where("order", isEqualTo: questionIndex).limit(1).get();
    if (qQuery.docs.isEmpty) throw "Question not found";

    final qDoc = qQuery.docs.first;
    final qData = qDoc.data();
    final int correctAnswerIndex = (qData["correctAnswerIndex"] as num?)?.toInt() ?? 0;
    final int questionTimeLimit = (qData["timeLimit"] as num?)?.toInt() ?? 15;

    await _firestore.runTransaction((transaction) async {
      // 1. Fetch Game State inside transaction
      final gameSnap = await transaction.get(gameRef);
      if (!gameSnap.exists) throw "Game session expired";
      final game = GameModel.fromSnapshot(gameSnap);

      // Validate Game Status & Server Deadline inside transaction
      if (game.status != "question_active") {
        throw "Question is not active";
      }

      final endTime = game.questionEndTime?.toDate();
      final now = DateTime.now();
      if (endTime != null && now.isAfter(endTime)) {
        throw "Question timer has ended!";
      }

      final int timeLimit = questionTimeLimit > 0 ? questionTimeLimit : game.timePerQuestion;

      // Calculate remaining seconds
      final int secondsLeft = endTime != null ? (endTime.difference(now).inSeconds).clamp(0, timeLimit) : 0;

      // 2. Verify answer lock inside transaction
      final existingAnswer = await transaction.get(answerRef);
      if (existingAnswer.exists) {
        throw "Your team has already submitted an answer!";
      }

      // 3. Calculate correctness & points securely on server
      final isCorrect = (selectedOption == correctAnswerIndex);
      final pointsEarned = calculatePoints(
        secondsLeft: secondsLeft,
        timeLimit: timeLimit,
        isCorrect: isCorrect,
      );

      transaction.set(answerRef, {
        "gameId": gameId,
        "questionIndex": questionIndex,
        "teamId": teamId,
        "teamName": teamName,
        "teamEmoji": teamEmoji,
        "userId": userId,
        "userName": userName,
        "selectedOption": selectedOption,
        "isCorrect": isCorrect,
        "answeredAt": FieldValue.serverTimestamp(),
        "pointsEarned": pointsEarned,
      });

      final teamSnap = await transaction.get(teamRef);
      final currentScore = (teamSnap.data()?["score"] as num?)?.toInt() ?? 0;

      transaction.update(teamRef, {
        "score": currentScore + pointsEarned,
      });
    });
  }

  /// Host Game Actions
  Future<String> launchLiveLobby(String gameId) async {
    final gameRef = _firestore.collection("games").doc(gameId);

    // Purge old teams and answers from any previous session of this game
    await _clearOldSessionData(gameId);

    final pin = generateGamePin();

    await gameRef.update({
      "pin": pin,
      "status": "lobby",
      "currentQuestionIndex": 0,
      "isPaused": false,
      "pausedRemainingSeconds": 0,
    });

    return pin;
  }

  Future<void> startGame(String gameId) async {
    final gameRef = _firestore.collection("games").doc(gameId);
    final qSnap = await gameRef.collection("questions").where("order", isEqualTo: 0).limit(1).get();

    int duration = 15;
    if (qSnap.docs.isNotEmpty) {
      duration = (qSnap.docs.first.data()["timeLimit"] as num?)?.toInt() ?? 15;
    }

    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: duration));

    await gameRef.update({
      "status": "question_active",
      "currentQuestionIndex": 0,
      "timePerQuestion": duration,
      "questionStartTime": FieldValue.serverTimestamp(),
      "questionEndTime": Timestamp.fromDate(endTime),
      "isPaused": false,
    });
  }

  Future<void> togglePauseResume(GameModel game) async {
    if (game.isPaused) {
      final newEndTime = DateTime.now().add(Duration(seconds: game.pausedRemainingSeconds > 0 ? game.pausedRemainingSeconds : 15));
      await _firestore.collection("games").doc(game.id).update({
        "isPaused": false,
        "status": "question_active",
        "questionEndTime": Timestamp.fromDate(newEndTime),
      });
    } else {
      final remaining = (game.questionEndTime?.toDate().difference(DateTime.now()).inSeconds ?? 15).clamp(0, game.timePerQuestion);
      await _firestore.collection("games").doc(game.id).update({
        "isPaused": true,
        "status": "paused",
        "pausedRemainingSeconds": remaining,
      });
    }
  }

  Future<void> toggleAutoProgress(GameModel game) async {
    await _firestore.collection("games").doc(game.id).update({
      "autoProgress": !game.autoProgress,
    });
  }

  /// Atomic, Idempotent State Machine Progression
  Future<void> processAutomatedStateTransition(GameModel game) async {
    final gameRef = _firestore.collection("games").doc(game.id);

    debugPrint("[GAME] Finalizing question: index=${game.currentQuestionIndex}, gameId=${game.id}");

    // 1. Atomically move to question_result ONLY IF current status is question_active
    bool updatedToResult = false;
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(gameRef);
      if (snap.exists && snap.data()?["status"] == "question_active") {
        transaction.update(gameRef, {
          "status": "question_result",
        });
        updatedToResult = true;
      }
    });

    if (!updatedToResult) {
      debugPrint("[GUARD] Duplicate finalize ignored: status was not question_active");
      return;
    }

    debugPrint("[STATE] question_result published for question index=${game.currentQuestionIndex}");

    await Future.delayed(const Duration(seconds: 3));

    // 2. Atomically move to question_leaderboard ONLY IF current status is question_result
    bool updatedToLeaderboard = false;
    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(gameRef);
      if (snap.exists && snap.data()?["status"] == "question_result") {
        transaction.update(gameRef, {
          "status": "question_leaderboard",
        });
        updatedToLeaderboard = true;
      }
    });

    if (!updatedToLeaderboard) {
      debugPrint("[GUARD] Duplicate transition ignored: status was not question_result");
      return;
    }

    debugPrint("[STATE] question_leaderboard published for question index=${game.currentQuestionIndex}");

    await Future.delayed(const Duration(seconds: 5));

    // 3. Atomically advance to next question or finish ONLY IF current status is question_leaderboard
    final qSnap = await gameRef.collection("questions").orderBy("order").get();

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(gameRef);
      if (!snap.exists || snap.data()?["status"] != "question_leaderboard") {
        debugPrint("[GUARD] Duplicate advance ignored: status was not question_leaderboard");
        return;
      }

      final currentIdx = (snap.data()?["currentQuestionIndex"] as num?)?.toInt() ?? 0;
      final totalQuestions = qSnap.docs.length;

      if (currentIdx + 1 < totalQuestions) {
        final nextIdx = currentIdx + 1;

        // Find timeLimit of next question by order
        final nextQQuery = qSnap.docs.where((d) => (d.data()["order"] as num?)?.toInt() == nextIdx);
        int nextDuration = 15;
        if (nextQQuery.isNotEmpty) {
          nextDuration = (nextQQuery.first.data()["timeLimit"] as num?)?.toInt() ?? 15;
        }

        final newEndTime = DateTime.now().add(Duration(seconds: nextDuration));

        transaction.update(gameRef, {
          "status": "question_active",
          "currentQuestionIndex": nextIdx,
          "timePerQuestion": nextDuration,
          "questionStartTime": FieldValue.serverTimestamp(),
          "questionEndTime": Timestamp.fromDate(newEndTime),
          "isPaused": false,
        });
        debugPrint("[ADVANCE] Advance accepted: index=$currentIdx -> $nextIdx");
      } else {
        transaction.update(gameRef, {
          "status": "finished",
          "isPaused": false,
        });
        debugPrint("[STATE] Final question completed. Game entering finished state.");
      }
    });
  }

  Future<void> endGame(String gameId) async {
    await _firestore.collection("games").doc(gameId).update({
      "status": "finished",
      "isPaused": false,
    });
  }
}
