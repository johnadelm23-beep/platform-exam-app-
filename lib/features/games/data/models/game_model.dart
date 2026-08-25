import 'package:cloud_firestore/cloud_firestore.dart';

class GameModel {
  final String id;
  final String title;
  final String description;
  final String pin;
  final String status; // "draft", "lobby", "question_active", "question_result", "question_leaderboard", "paused", "finished"
  final int currentQuestionIndex;
  final int timePerQuestion;
  final int maxTeams;
  final int maxMembersPerTeam;
  final bool isPaused;
  final int pausedRemainingSeconds;
  final bool autoProgress;
  final Timestamp? questionStartTime;
  final Timestamp? questionEndTime;
  final Timestamp? createdAt;
  final String createdBy;

  GameModel({
    required this.id,
    required this.title,
    required this.description,
    required this.pin,
    required this.status,
    required this.currentQuestionIndex,
    required this.timePerQuestion,
    this.maxTeams = 8,
    this.maxMembersPerTeam = 5,
    this.isPaused = false,
    this.pausedRemainingSeconds = 0,
    this.autoProgress = true,
    this.questionStartTime,
    this.questionEndTime,
    this.createdAt,
    required this.createdBy,
  });

  factory GameModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GameModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      pin: data['pin'] as String? ?? '',
      status: data['status'] as String? ?? 'draft',
      currentQuestionIndex: (data['currentQuestionIndex'] as num?)?.toInt() ?? 0,
      timePerQuestion: (data['timePerQuestion'] as num?)?.toInt() ?? 15,
      maxTeams: (data['maxTeams'] as num?)?.toInt() ?? 8,
      maxMembersPerTeam: (data['maxMembersPerTeam'] as num?)?.toInt() ?? 5,
      isPaused: data['isPaused'] as bool? ?? false,
      pausedRemainingSeconds: (data['pausedRemainingSeconds'] as num?)?.toInt() ?? 0,
      autoProgress: data['autoProgress'] as bool? ?? true,
      questionStartTime: data['questionStartTime'] as Timestamp?,
      questionEndTime: data['questionEndTime'] as Timestamp?,
      createdAt: data['createdAt'] as Timestamp?,
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'pin': pin,
      'status': status,
      'currentQuestionIndex': currentQuestionIndex,
      'timePerQuestion': timePerQuestion,
      'maxTeams': maxTeams,
      'maxMembersPerTeam': maxMembersPerTeam,
      'isPaused': isPaused,
      'pausedRemainingSeconds': pausedRemainingSeconds,
      'autoProgress': autoProgress,
      'questionStartTime': questionStartTime,
      'questionEndTime': questionEndTime,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'createdBy': createdBy,
    };
  }
}

class GameQuestionModel {
  final String id;
  final int order;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final int timeLimit;

  GameQuestionModel({
    required this.id,
    required this.order,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.timeLimit,
  });

  factory GameQuestionModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final opts = (data['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return GameQuestionModel(
      id: doc.id,
      order: (data['order'] as num?)?.toInt() ?? 0,
      questionText: data['questionText'] as String? ?? '',
      options: opts,
      correctAnswerIndex: (data['correctAnswerIndex'] as num?)?.toInt() ?? 0,
      timeLimit: (data['timeLimit'] as num?)?.toInt() ?? 15,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'questionText': questionText,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'timeLimit': timeLimit,
    };
  }
}

class GameTeamModel {
  final String id;
  final String name;
  final String emoji;
  final int score;
  final int rank;
  final int memberCount;
  final int maxMembers;
  final bool isParticipating;

  GameTeamModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.score,
    required this.rank,
    required this.memberCount,
    required this.maxMembers,
    required this.isParticipating,
  });

  factory GameTeamModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final String rawName = (data['name'] as String? ?? data['teamName'] as String?) ?? '';
    final String rawEmoji = (data['emoji'] as String? ?? data['teamEmoji'] as String?) ?? '';
    final int mCount = (data['memberCount'] as num?)?.toInt() ?? 0;
    final bool explicitJoined = (data['isParticipating'] as bool?) ?? false;

    // A team is ONLY participating if it was explicitly joined (memberCount > 0) or has an explicit non-default chosen name
    final bool isParticipating = explicitJoined || mCount > 0 || (rawName.trim().isNotEmpty && rawName.trim() != doc.id);

    String parsedName = rawName.trim();
    if (parsedName.isEmpty || parsedName == doc.id) {
      parsedName = doc.id.startsWith("team_")
          ? "Team ${doc.id.replaceAll('team_', '')}"
          : "Team";
    }

    return GameTeamModel(
      id: doc.id,
      name: parsedName,
      emoji: rawEmoji.trim().isNotEmpty ? rawEmoji.trim() : '🦁',
      score: (data['score'] as num?)?.toInt() ?? 0,
      rank: (data['rank'] as num?)?.toInt() ?? 0,
      memberCount: mCount,
      maxMembers: (data['maxMembers'] as num?)?.toInt() ?? 5,
      isParticipating: isParticipating,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'emoji': emoji,
      'score': score,
      'rank': rank,
      'memberCount': memberCount,
      'maxMembers': maxMembers,
      'isParticipating': isParticipating,
    };
  }
}

class GameTeamMemberModel {
  final String uid;
  final String displayName;
  final Timestamp? joinedAt;

  GameTeamMemberModel({
    required this.uid,
    required this.displayName,
    this.joinedAt,
  });

  factory GameTeamMemberModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GameTeamMemberModel(
      uid: doc.id,
      displayName: data['displayName'] as String? ?? 'Member',
      joinedAt: data['joinedAt'] as Timestamp?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayName': displayName,
      'joinedAt': joinedAt ?? FieldValue.serverTimestamp(),
    };
  }
}

class GameTeamAnswerModel {
  final String id;
  final String gameId;
  final int questionIndex;
  final String teamId;
  final String teamName;
  final String teamEmoji;
  final String userId;
  final String userName;
  final int selectedOption;
  final bool isCorrect;
  final Timestamp? answeredAt;
  final int pointsEarned;

  GameTeamAnswerModel({
    required this.id,
    required this.gameId,
    required this.questionIndex,
    required this.teamId,
    required this.teamName,
    required this.teamEmoji,
    required this.userId,
    required this.userName,
    required this.selectedOption,
    required this.isCorrect,
    this.answeredAt,
    required this.pointsEarned,
  });

  factory GameTeamAnswerModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return GameTeamAnswerModel(
      id: doc.id,
      gameId: data['gameId'] as String? ?? '',
      questionIndex: (data['questionIndex'] as num?)?.toInt() ?? 0,
      teamId: data['teamId'] as String? ?? '',
      teamName: data['teamName'] as String? ?? 'Team',
      teamEmoji: data['teamEmoji'] as String? ?? '🦁',
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? 'Player',
      selectedOption: (data['selectedOption'] as num?)?.toInt() ?? 0,
      isCorrect: data['isCorrect'] as bool? ?? false,
      answeredAt: data['answeredAt'] as Timestamp?,
      pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gameId': gameId,
      'questionIndex': questionIndex,
      'teamId': teamId,
      'teamName': teamName,
      'teamEmoji': teamEmoji,
      'userId': userId,
      'userName': userName,
      'selectedOption': selectedOption,
      'isCorrect': isCorrect,
      'answeredAt': answeredAt ?? FieldValue.serverTimestamp(),
      'pointsEarned': pointsEarned,
    };
  }
}
