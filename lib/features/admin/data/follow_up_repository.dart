import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

abstract class IFollowUpRepository {
  Stream<List<UserData>> getUsersStream();
  Future<List<UserData>> getAllUsers();
  Future<void> updateUserFollowUp(String userId, Map<String, dynamic> data);
  Future<void> recordCallCompleted(String userId);
  Future<void> recordVisitCompleted(String userId);
}

class FollowUpRepository implements IFollowUpRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FollowUpRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  /// Helper check for Admin authority (Main Admin or Sub Admin)
  Future<bool> isCurrentUserAdmin() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return false;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (doc.exists) {
        final data = doc.data();
        return data?['isAdmin'] == true ||
            data?['subAdmin'] == true ||
            data?['isSubAdmin'] == true;
      }
    } catch (e) {
      debugPrint('Error verifying admin status: $e');
    }
    return false;
  }

  @override
  Stream<List<UserData>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserData.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  @override
  Future<List<UserData>> getAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        return UserData.fromJson(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching users in repository: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserFollowUp(
    String userId,
    Map<String, dynamic> data,
  ) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) {
      throw Exception(
        'Permission denied: Only admin accounts can update follow-up details.',
      );
    }

    try {
      // Ensure update timestamps
      final updatePayload = Map<String, dynamic>.from(data);
      updatePayload['updatedAt'] = FieldValue.serverTimestamp();

      // Update users collection document directly
      await _firestore
          .collection('users')
          .doc(userId)
          .set(updatePayload, SetOptions(merge: true));

      // Synchronize dedicated follow_ups collection for audit trail
      await _firestore
          .collection('follow_ups')
          .doc(userId)
          .set(updatePayload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving follow-up data: $e');
      rethrow;
    }
  }

  @override
  Future<void> recordCallCompleted(String userId) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) return;

    try {
      final now = Timestamp.fromDate(DateTime.now());
      final payload = {
        'lastCallDate': now,
        'lastContact': now,
        'callsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).update(payload);
      await _firestore
          .collection('follow_ups')
          .doc(userId)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recording call completed: $e');
    }
  }

  @override
  Future<void> recordVisitCompleted(String userId) async {
    final isAdmin = await isCurrentUserAdmin();
    if (!isAdmin) return;

    try {
      final now = Timestamp.fromDate(DateTime.now());
      final payload = {
        'lastVisitDate': now,
        'lastContact': now,
        'visitsCount': FieldValue.increment(1),
        'needVisit': false,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('users').doc(userId).update(payload);
      await _firestore
          .collection('follow_ups')
          .doc(userId)
          .set(payload, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error recording visit completed: $e');
    }
  }
}
