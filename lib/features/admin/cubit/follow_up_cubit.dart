import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:platformexamapp/features/admin/cubit/follow_up_state.dart';
import 'package:platformexamapp/features/admin/data/follow_up_repository.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class FollowUpCubit extends Cubit<FollowUpState> {
  final IFollowUpRepository _repository;
  StreamSubscription<List<UserData>>? _usersSubscription;

  FollowUpCubit({IFollowUpRepository? repository})
    : _repository = repository ?? FollowUpRepository(),
      super(const FollowUpState()) {
    init();
  }

  void init() {
    emit(state.copyWith(isLoading: true));
    _usersSubscription?.cancel();
    _usersSubscription = _repository.getUsersStream().listen(
      (users) {
        _processUsers(users);
      },
      onError: (error) {
        emit(
          state.copyWith(
            isLoading: false,
            errorMessage: 'Failed to load users: $error',
          ),
        );
      },
    );
  }

  void _processUsers(List<UserData> users) {
    int total = users.length;
    int active = 0;
    int needFollowUp = 0;
    int urgent = 0;
    int calls = 0;
    int visits = 0;

    for (var u in users) {
      final pct = u.attendancePercentage ?? 0.0;
      final status = u.followUpStatus ?? "Regular";

      if (pct > 0 || (u.totalAttendance ?? 0) > 0) {
        active++;
      }
      if (status == "Needs Follow-up" || pct < 50.0 || (u.needVisit == true)) {
        needFollowUp++;
      }
      if (status == "Urgent") {
        urgent++;
      }
      calls += (u.callsCount ?? 0);
      visits += (u.visitsCount ?? 0);
    }

    final filtered = _filterUsersList(
      users,
      searchQuery: state.searchQuery,
      attendanceFilter: state.attendanceFilter,
      groupFilter: state.groupFilter,
      needVisitFilter: state.needVisitFilter,
      statusFilter: state.statusFilter,
    );

    emit(
      state.copyWith(
        allUsers: users,
        filteredUsers: filtered,
        isLoading: false,
        totalUsersCount: total,
        activeUsersCount: active,
        needFollowUpCount: needFollowUp,
        urgentCasesCount: urgent,
        callsCompletedCount: calls,
        visitsCompletedCount: visits,
      ),
    );
  }

  void setSearchQuery(String query) {
    final filtered = _filterUsersList(
      state.allUsers,
      searchQuery: query,
      attendanceFilter: state.attendanceFilter,
      groupFilter: state.groupFilter,
      needVisitFilter: state.needVisitFilter,
      statusFilter: state.statusFilter,
    );
    emit(state.copyWith(searchQuery: query, filteredUsers: filtered));
  }

  void setAttendanceFilter(String filter) {
    final filtered = _filterUsersList(
      state.allUsers,
      searchQuery: state.searchQuery,
      attendanceFilter: filter,
      groupFilter: state.groupFilter,
      needVisitFilter: state.needVisitFilter,
      statusFilter: state.statusFilter,
    );
    emit(state.copyWith(attendanceFilter: filter, filteredUsers: filtered));
  }

  void setGroupFilter(String filter) {
    final filtered = _filterUsersList(
      state.allUsers,
      searchQuery: state.searchQuery,
      attendanceFilter: state.attendanceFilter,
      groupFilter: filter,
      needVisitFilter: state.needVisitFilter,
      statusFilter: state.statusFilter,
    );
    emit(state.copyWith(groupFilter: filter, filteredUsers: filtered));
  }

  void setNeedVisitFilter(String filter) {
    final filtered = _filterUsersList(
      state.allUsers,
      searchQuery: state.searchQuery,
      attendanceFilter: state.attendanceFilter,
      groupFilter: state.groupFilter,
      needVisitFilter: filter,
      statusFilter: state.statusFilter,
    );
    emit(state.copyWith(needVisitFilter: filter, filteredUsers: filtered));
  }

  void setStatusFilter(String filter) {
    final filtered = _filterUsersList(
      state.allUsers,
      searchQuery: state.searchQuery,
      attendanceFilter: state.attendanceFilter,
      groupFilter: state.groupFilter,
      needVisitFilter: state.needVisitFilter,
      statusFilter: filter,
    );
    emit(state.copyWith(statusFilter: filter, filteredUsers: filtered));
  }

  List<UserData> _filterUsersList(
    List<UserData> users, {
    required String searchQuery,
    required String attendanceFilter,
    required String groupFilter,
    required String needVisitFilter,
    required String statusFilter,
  }) {
    return users.where((u) {
      // 1. Search Query
      if (searchQuery.isNotEmpty) {
        final nameMatches = (u.name ?? '').toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
        final phoneMatches = (u.phone ?? '').contains(searchQuery);
        final emailMatches = (u.email ?? '').toLowerCase().contains(
          searchQuery.toLowerCase(),
        );
        if (!nameMatches && !phoneMatches && !emailMatches) return false;
      }

      // 2. Attendance % Filter
      final pct = u.attendancePercentage ?? 0.0;
      if (attendanceFilter == '<50%' && pct >= 50.0) return false;
      if (attendanceFilter == '50-75%' && (pct < 50.0 || pct > 75.0))
        return false;
      if (attendanceFilter == '>75%' && pct <= 75.0) return false;

      // 3. Group Filter
      if (groupFilter != 'All' && (u.group ?? 'General') != groupFilter)
        return false;

      // 4. Need Visit Filter
      if (needVisitFilter == 'Yes' && u.needVisit != true) return false;
      if (needVisitFilter == 'No' && u.needVisit == true) return false;

      // 5. Follow-up Status Filter
      if (statusFilter != 'All' &&
          (u.followUpStatus ?? 'Regular') != statusFilter)
        return false;

      return true;
    }).toList();
  }

  Future<bool> saveUserFollowUp(
    String userId,
    Map<String, dynamic> data,
  ) async {
    emit(state.copyWith(isSaving: true));
    try {
      await _repository.updateUserFollowUp(userId, data);
      emit(
        state.copyWith(
          isSaving: false,
          successMessage: 'Follow-up information saved successfully!',
        ),
      );
      return true;
    } catch (e) {
      emit(
        state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save follow-up: $e',
        ),
      );
      return false;
    }
  }

  Future<void> recordCall(String userId) async {
    try {
      await _repository.recordCallCompleted(userId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to record call: $e'));
    }
  }

  Future<void> recordVisit(String userId) async {
    try {
      await _repository.recordVisitCompleted(userId);
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Failed to record visit: $e'));
    }
  }

  @override
  Future<void> close() {
    _usersSubscription?.cancel();
    return super.close();
  }
}
