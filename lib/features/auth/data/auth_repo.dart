import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class AuthRepo {
  static FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

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
      debugPrint(response.user!.uid);
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw ('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw ('The account already exists for that email.');
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _firebaseAuth.signInWithEmailLink(
        email: email,
        emailLink: email,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw "No user found with this email";
      } else if (e.code == 'wrong-password') {
        throw "Wrong password";
      } else if (e.code == 'invalid-email') {
        throw "Invalid email";
      } else {
        throw "Login failed";
      }
    } catch (e) {
      debugPrint("$e");
      return false;
    }
  }
}
