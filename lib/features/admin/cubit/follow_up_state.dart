import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class FollowUpState {
  final List<UserData> allUsers;
  final List<UserData> filteredUsers;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  // Filter criteria
  final String searchQuery;
  final String attendanceFilter; // 'All', '<50%', '50-75%', '>75%'
  final String groupFilter; // 'All', ...
  final String needVisitFilter; // 'All', 'Yes', 'No'
  final String statusFilter; // 'All', 'Excellent', 'Regular', 'Needs Follow-up', 'Urgent'

  // Statistics
  final int totalUsersCount;
  final int activeUsersCount;
  final int needFollowUpCount;
  final int urgentCasesCount;
  final int callsCompletedCount;
  final int visitsCompletedCount;

  const FollowUpState({
    this.allUsers = const [],
    this.filteredUsers = const [],
    this.isLoading = true,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
    this.searchQuery = '',
    this.attendanceFilter = 'All',
    this.groupFilter = 'All',
    this.needVisitFilter = 'All',
    this.statusFilter = 'All',
    this.totalUsersCount = 0,
    this.activeUsersCount = 0,
    this.needFollowUpCount = 0,
    this.urgentCasesCount = 0,
    this.callsCompletedCount = 0,
    this.visitsCompletedCount = 0,
  });

  FollowUpState copyWith({
    List<UserData>? allUsers,
    List<UserData>? filteredUsers,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    String? searchQuery,
    String? attendanceFilter,
    String? groupFilter,
    String? needVisitFilter,
    String? statusFilter,
    int? totalUsersCount,
    int? activeUsersCount,
    int? needFollowUpCount,
    int? urgentCasesCount,
    int? callsCompletedCount,
    int? visitsCompletedCount,
  }) {
    return FollowUpState(
      allUsers: allUsers ?? this.allUsers,
      filteredUsers: filteredUsers ?? this.filteredUsers,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
      successMessage: successMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      attendanceFilter: attendanceFilter ?? this.attendanceFilter,
      groupFilter: groupFilter ?? this.groupFilter,
      needVisitFilter: needVisitFilter ?? this.needVisitFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      totalUsersCount: totalUsersCount ?? this.totalUsersCount,
      activeUsersCount: activeUsersCount ?? this.activeUsersCount,
      needFollowUpCount: needFollowUpCount ?? this.needFollowUpCount,
      urgentCasesCount: urgentCasesCount ?? this.urgentCasesCount,
      callsCompletedCount: callsCompletedCount ?? this.callsCompletedCount,
      visitsCompletedCount: visitsCompletedCount ?? this.visitsCompletedCount,
    );
  }
}
