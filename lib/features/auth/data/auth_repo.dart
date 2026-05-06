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
      await FirebaseFirestore.instance.collection("users").doc(uid).set({
        "name": name,
        "password": password,
        "email": email,
      });
    } catch (e) {}
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

      final user = await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .get();

      final data = user.data();

      if (data?["isBlocked"] == true) return null;

      return UserData.fromJson(data ?? {});
    } catch (e) {
      return null;
    }
  }
}
