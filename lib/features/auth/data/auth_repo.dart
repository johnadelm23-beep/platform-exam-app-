import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:platformexamapp/features/auth/data/model/user_data.dart';

class AuthRepo {
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static Future<void> addUser({
    required String name,
    required String email,
    required String uId,
    required String password,
  }) async {
    try {
      await FirebaseFirestore.instance.collection("users").doc(uId).set({
        "name": name,
        "email": email,
        "password": password,
        "isBlocked": false,
      });
    } catch (e) {
      debugPrint("ADD USER ERROR: $e");
      throw e.toString();
    }
  }

  static Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String comfirmPassword,
  }) async {
    try {
      final response = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await addUser(
        name: name,
        email: email,
        uId: response.user!.uid,
        password: password,
      );

      return true;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Registration failed";
    } catch (e) {
      throw e.toString();
    }
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

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(response.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw "User not found in database";
      }

      if (userDoc.data()?["isBlocked"] == true) {
        throw "User is blocked";
      }

      return true;
    } on FirebaseAuthException catch (e) {
      throw e.message ?? "Login failed";
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

      if (!user.exists) return null;
      final data = user.data();
      if (data?["isBlocked"] == true) return null;
      return UserData.fromJson(data ?? {});
    } catch (e) {
      return null;
    }
  }
}
