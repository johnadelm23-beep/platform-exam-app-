import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class AuthRepo {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
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
      addUser(
        name: name,
        email: email,
        password: password,
        uid: response.user?.uid ?? "",
      );
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

      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "uid": uid,
        "name": name,
        "password": password,
        "email": email,
        "isAdmin": false,
        "isSubAdmin": false,
        "profileImage": null,
        "attendancePercentage": 0.0,
        "fridayAttendanceCount": 0,
        "sundayAttendanceCount": 0,
        "currentStreak": 0,
        "longestStreak": 0,
        "totalAttendance": 0,
        "totalAbsence": 0,
        "humanReadableId": manualId,
        "lastAttendanceDate": null,
      });
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
        final doc = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.uid)
            .get();
        final data = doc.data();

        if (data?["isBlocked"] == true) {
          await FirebaseAuth.instance.signOut();
          throw "This account is Blocked";
        }

        await FirebaseFirestore.instance.collection("users").doc(user.uid).set({
          "name": user.displayName ?? "User",
          "email": user.email ?? "",
          "isBlocked": false,
        }, SetOptions(merge: true));
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

      final userDocRef = FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid);
      final user = await userDocRef.get();

      final data = user.data();

      if (data?["isBlocked"] == true) return null;

      // Lazy initialization of attendance fields and human-readable IDs for older/third-party accounts
      if (data != null && data["humanReadableId"] == null) {
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

        final bool isAdminVal = data["isAdmin"] == true;
        final bool isSubVal =
            (data["subAdmin"] == true) || (data["isSubAdmin"] == true);
        final bool finalSubVal = isAdminVal ? false : isSubVal;

        final updatedData = {
          "uid": currentUser.uid,
          "humanReadableId": manualId,
          "profileImage": data["profileImage"] ?? currentUser.photoURL,
          "attendancePercentage": data["attendancePercentage"] ?? 0.0,
          "fridayAttendanceCount": data["fridayAttendanceCount"] ?? 0,
          "sundayAttendanceCount": data["sundayAttendanceCount"] ?? 0,
          "currentStreak": data["currentStreak"] ?? 0,
          "longestStreak": data["longestStreak"] ?? 0,
          "totalAttendance": data["totalAttendance"] ?? 0,
          "totalAbsence": data["totalAbsence"] ?? 0,
          "lastAttendanceDate": data["lastAttendanceDate"],
          "isAdmin": isAdminVal,
          "subAdmin": finalSubVal,
          "isSubAdmin": finalSubVal,
        };
        await userDocRef.set(updatedData, SetOptions(merge: true));
        final finalSnap = await userDocRef.get();
        return UserData.fromJson(finalSnap.data() ?? {}, currentUser.uid);
      }

      return UserData.fromJson(data ?? {}, currentUser.uid);
    } catch (e) {
      debugPrint("ERROR GET USER DATA: $e");
      return null;
    }
  }
}
