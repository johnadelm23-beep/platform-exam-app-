import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class AuthRepo {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// 🔹 Centralized User Initialization & Repair System
  /// Ensures users/{uid} document exists and has all required application fields.
  /// For existing documents, ONLY missing fields are added via SetOptions(merge: true).
  /// Existing fields (streaks, counts, roles, isBlocked, IDs) are NEVER reset.
  static Future<void> ensureUserDocumentInitialized(
    User firebaseUser, {
    String? name,
    String? password,
  }) async {
    final userDocRef = FirebaseFirestore.instance
        .collection("users")
        .doc(firebaseUser.uid);

    final docSnap = await userDocRef.get();

    if (!docSnap.exists) {
      // -------------------------------------------------------------
      // 1. BRAND NEW USER DOCUMENT CREATION
      // -------------------------------------------------------------
      final manualId = await _generateHumanReadableId();

      final initialData = <String, dynamic>{
        "uid": firebaseUser.uid,
        "name": name ?? firebaseUser.displayName ?? "User",
        "email": firebaseUser.email ?? "",
        "password": password,
        "isAdmin": false,
        "subAdmin": false,
        "isSubAdmin": false,
        "isBlocked": false,
        "profileImage": firebaseUser.photoURL,
        "humanReadableId": manualId,
        "attendancePercentage": 0.0,
        "fridayAttendanceCount": 0,
        "sundayAttendanceCount": 0,
        "currentStreak": 0,
        "longestStreak": 0,
        "highestStreak": 0,
        "totalAttendance": 0,
        "totalAbsence": 0,
        "lastAttendanceDate": null,
        "phone": null,
        "fatherPhone": null,
        "motherPhone": null,
        "address": null,
        "school": null,
        "university": null,
        "work": null,
        "group": "General",
        "followUpStatus": "Regular",
        "needVisit": false,
        "lastContact": null,
        "lastCallDate": null,
        "lastVisitDate": null,
        "notes": null,
        "servantNotes": null,
        "callsCount": 0,
        "visitsCount": 0,
      };

      await userDocRef.set(initialData);
    } else {
      // -------------------------------------------------------------
      // 2. EXISTING USER DOCUMENT (MIGRATION / REPAIR INCOMPLETE FIELDS)
      // -------------------------------------------------------------
      final existingData = docSnap.data() ?? {};

      // Safeguard: Check if account is blocked
      if (existingData["isBlocked"] == true) {
        await FirebaseAuth.instance.signOut();
        throw "This account is Blocked";
      }

      final missingFields = <String, dynamic>{};

      void checkAndAdd(String key, dynamic defaultValue) {
        if (!existingData.containsKey(key)) {
          missingFields[key] = defaultValue;
        }
      }

      checkAndAdd("uid", firebaseUser.uid);
      if (!existingData.containsKey("name") || existingData["name"] == null) {
        missingFields["name"] = name ?? firebaseUser.displayName ?? "User";
      }
      if (!existingData.containsKey("email") || existingData["email"] == null) {
        missingFields["email"] = firebaseUser.email ?? "";
      }
      checkAndAdd("isAdmin", false);
      checkAndAdd("subAdmin", false);
      checkAndAdd("isSubAdmin", false);
      checkAndAdd("isBlocked", false);
      checkAndAdd("profileImage", firebaseUser.photoURL);
      checkAndAdd("attendancePercentage", 0.0);
      checkAndAdd("fridayAttendanceCount", 0);
      checkAndAdd("sundayAttendanceCount", 0);
      checkAndAdd("currentStreak", 0);
      checkAndAdd("longestStreak", 0);
      checkAndAdd("highestStreak", 0);
      checkAndAdd("totalAttendance", 0);
      checkAndAdd("totalAbsence", 0);
      checkAndAdd("lastAttendanceDate", null);
      checkAndAdd("phone", null);
      checkAndAdd("fatherPhone", null);
      checkAndAdd("motherPhone", null);
      checkAndAdd("address", null);
      checkAndAdd("school", null);
      checkAndAdd("university", null);
      checkAndAdd("work", null);
      checkAndAdd("group", "General");
      checkAndAdd("followUpStatus", "Regular");
      checkAndAdd("needVisit", false);
      checkAndAdd("lastContact", null);
      checkAndAdd("lastCallDate", null);
      checkAndAdd("lastVisitDate", null);
      checkAndAdd("notes", null);
      checkAndAdd("servantNotes", null);
      checkAndAdd("callsCount", 0);
      checkAndAdd("visitsCount", 0);

      // Special check for humanReadableId
      if (!existingData.containsKey("humanReadableId") ||
          existingData["humanReadableId"] == null ||
          existingData["humanReadableId"].toString().isEmpty) {
        final manualId = await _generateHumanReadableId();
        missingFields["humanReadableId"] = manualId;
      }

      if (missingFields.isNotEmpty) {
        await userDocRef.set(missingFields, SetOptions(merge: true));
      }
    }
  }

  static Future<String> _generateHumanReadableId() async {
    final counterRef = FirebaseFirestore.instance
        .collection("metadata")
        .doc("counters");
    String manualId = "";
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snap = await transaction.get(counterRef);
      int currentSeq = 1;
      if (snap.exists) {
        currentSeq = (snap.data()?["userSequence"] ?? 0) + 1;
      }
      transaction.set(counterRef, {
        "userSequence": currentSeq,
      }, SetOptions(merge: true));
      manualId = "EGT${currentSeq.toString().padLeft(6, '0')}";
    });
    return manualId;
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("${response.user}");
      if (response.user != null) {
        await ensureUserDocumentInitialized(response.user!);
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      } else if (e.code == 'invalid-email') {
        throw Exception('The email address is invalid.');
      } else if (e.code == 'user-disabled') {
        throw Exception('This user has been disabled.');
      } else {
        throw Exception(e.message ?? 'Login failed');
      }
    } catch (e) {
      debugPrint("ERROR${e}");
      return false;
    }
  }

  static Future<bool> register({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final response = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      debugPrint("${response.user}");
      if (response.user != null) {
        await ensureUserDocumentInitialized(
          response.user!,
          name: name,
          password: password,
        );
      }
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw ('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw ('The account already exists for that email.');
      }
      return false;
    } catch (e) {
      debugPrint("ERROR${e}");
      return false;
    }
  }

  static Future<void> addUser({
    required String name,
    required String email,
    required String password,
    required String uid,
  }) async {
    try {
      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        await ensureUserDocumentInitialized(
          currentUser,
          name: name,
          password: password,
        );
      }
    } catch (e) {
      debugPrint("ERROR ADD USER: $e");
    }
  }

  static Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();

      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final user = userCredential.user;

      if (user != null) {
        await ensureUserDocumentInitialized(user);
      }

      return true;
    } catch (e) {
      throw e.toString();
    }
  }

  static Future<UserData?> getUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) return null;

      await ensureUserDocumentInitialized(currentUser);

      final userDocRef = FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid);
      final user = await userDocRef.get();

      final data = user.data();

      if (data?["isBlocked"] == true) return null;

      return UserData.fromJson(data ?? {}, currentUser.uid);
    } catch (e) {
      debugPrint("ERROR GET USER DATA: $e");
      return null;
    }
  }
}
