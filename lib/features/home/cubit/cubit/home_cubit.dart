import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());
  UserData? userData;
  StreamSubscription<DocumentSnapshot>? _userSubscription;

  Future<void> getUserData() async {
    emit(GetUserDataLoading());
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      emit(GetUserDaraError());
      return;
    }

    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection("users")
        .doc(currentUser.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        userData = UserData.fromJson(data, currentUser.uid);

        debugPrint('''
=== CURRENT USER ROLE DEBUG INFO ===
Current user UID: ${currentUser.uid}
Firestore user document: users/${currentUser.uid}
isAdmin: ${userData?.isAdminVal}
subAdmin: ${userData?.subAdmin}
canAccessFollowUp: ${userData?.canAccessFollowUp}
canAccessAttendanceScanner: ${userData?.canAccessAttendanceScanner}
canAccessAttendanceState: ${userData?.canAccessAttendanceState}
canAccessContentHistory: ${userData?.canAccessContentHistory}
===================================
''');

        emit(GetUserDataSuccess());
      } else {
        emit(GetUserDaraError());
      }
    }, onError: (error) {
      debugPrint("Error listening to user doc: $error");
      emit(GetUserDaraError());
    });
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}

