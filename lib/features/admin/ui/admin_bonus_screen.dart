import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_dialog.dart';
import 'package:platformexamapp/core/widgets/empty_state.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';
import 'package:platformexamapp/core/widgets/loading_state.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class AdminBonusUserBreakdown {
  final String userId;
  final String userName;
  double totalGranted;
  double totalSpent;
  final List<String> reasons;

  double get remaining => totalGranted - totalSpent;

  AdminBonusUserBreakdown({
    required this.userId,
    required this.userName,
    required this.totalGranted,
    required this.totalSpent,
    required this.reasons,
  });
}

class AdminBonusScreen extends StatefulWidget {
  const AdminBonusScreen({super.key, required this.user});
  final UserData user;

  @override
  State<AdminBonusScreen> createState() => _AdminBonusScreenState();
}

class _AdminBonusScreenState extends State<AdminBonusScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    debugPrint("[BonusStatistics] Screen initialized");
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        debugPrint("[BonusStatistics] Active tab index: ${_tabController.index}");
      }
    });
  }

  Stream<QuerySnapshot> _getBonusStream() {
    return FirebaseFirestore.instance.collection("bonuses").snapshots();
  }

  Stream<QuerySnapshot> _getUsersStream() {
    return FirebaseFirestore.instance.collection("users").snapshots();
  }

  @override
  void dispose() {
    debugPrint("[BonusStatistics] Screen disposed");
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ================= ADMIN ACTIONS =================

  /// Open Dialog to Add Bonus to a selected user
  void _showAddBonusDialog(UserData targetUser) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            "${"add_bonus".tr()}: ${targetUser.name}",
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "bonus_amount".tr(),
                    prefixIcon: const Icon(Icons.star_rate_rounded, color: AppColors.softGold),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "invalid_amount".tr();
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) return "invalid_amount".tr();
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: "reason_optional".tr(),
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.softGold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("cancel".tr(), style: GoogleFonts.cairo(color: AppColors.darkTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amount = double.parse(amountController.text.trim());
                final reason = reasonController.text.trim();
                final adminUid = FirebaseAuth.instance.currentUser?.uid ?? "";

                Navigator.pop(ctx);

                await FirebaseFirestore.instance.collection("bonuses").add({
                  "userId": targetUser.uid,
                  "userName": targetUser.name,
                  "amount": amount,
                  "spent": 0.0,
                  "reason": reason.isEmpty ? "Outstanding Participation" : reason,
                  "createdAt": FieldValue.serverTimestamp(),
                  "createdBy": adminUid,
                  "updatedAt": FieldValue.serverTimestamp(),
                  "updatedBy": adminUid,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("bonus_added_success".tr(), style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              child: Text("save".tr(), style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Open Dialog to Record Spent Bonus for a user
  void _showRecordSpentDialog(UserData targetUser, double currentRemaining) {
    final spentController = TextEditingController();
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            "${"record_spent".tr()}: ${targetUser.name}",
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Available: ${_formatNum(currentRemaining)} pts",
                  style: GoogleFonts.cairo(
                    fontSize: 13.sp,
                    color: AppColors.softGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                TextFormField(
                  controller: spentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "spent_amount".tr(),
                    prefixIcon: const Icon(Icons.remove_circle_outline, color: AppColors.heartRed),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "invalid_amount".tr();
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal <= 0) return "invalid_amount".tr();
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: "reason_optional".tr(),
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.softGold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("cancel".tr(), style: GoogleFonts.cairo(color: AppColors.darkTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.heartRed,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final spentVal = double.parse(spentController.text.trim());
                final reason = reasonController.text.trim();
                final adminUid = FirebaseAuth.instance.currentUser?.uid ?? "";

                Navigator.pop(ctx);

                await FirebaseFirestore.instance.collection("bonuses").add({
                  "userId": targetUser.uid,
                  "userName": targetUser.name,
                  "amount": 0.0,
                  "spent": spentVal,
                  "reason": reason.isEmpty ? "Spent" : reason,
                  "createdAt": FieldValue.serverTimestamp(),
                  "createdBy": adminUid,
                  "updatedAt": FieldValue.serverTimestamp(),
                  "updatedBy": adminUid,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("bonus_spent_success".tr(), style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              child: Text("save".tr(), style: GoogleFonts.cairo(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Edit existing bonus document
  void _showEditBonusDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final amountController = TextEditingController(text: (data["amount"] ?? 0.0).toString());
    final spentController = TextEditingController(text: (data["spent"] ?? 0.0).toString());
    final reasonController = TextEditingController(text: (data["reason"] ?? "").toString());
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            "edit_bonus".tr(),
            style: GoogleFonts.cairo(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.darkTextMain : AppColors.lightTextMain,
            ),
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "bonus_amount".tr(),
                    prefixIcon: const Icon(Icons.star_rate_rounded, color: AppColors.softGold),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "invalid_amount".tr();
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal < 0) return "invalid_amount".tr();
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: spentController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: "spent_amount".tr(),
                    prefixIcon: const Icon(Icons.remove_circle_outline, color: AppColors.heartRed),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return "invalid_amount".tr();
                    final numVal = double.tryParse(val.trim());
                    if (numVal == null || numVal < 0) return "invalid_amount".tr();
                    return null;
                  },
                ),
                SizedBox(height: 12.h),
                TextFormField(
                  controller: reasonController,
                  decoration: InputDecoration(
                    labelText: "reason_optional".tr(),
                    prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.softGold),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("cancel".tr(), style: GoogleFonts.cairo(color: AppColors.darkTextMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.softGold,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final amountVal = double.parse(amountController.text.trim());
                final spentVal = double.parse(spentController.text.trim());
                final reason = reasonController.text.trim();
                final adminUid = FirebaseAuth.instance.currentUser?.uid ?? "";

                Navigator.pop(ctx);

                await FirebaseFirestore.instance.collection("bonuses").doc(doc.id).update({
                  "amount": amountVal,
                  "spent": spentVal,
                  "reason": reason,
                  "updatedAt": FieldValue.serverTimestamp(),
                  "updatedBy": adminUid,
                });

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("success".tr(), style: GoogleFonts.cairo()),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              child: Text("save".tr(), style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  /// Delete bonus document with confirmation dialog
  void _deleteBonusDoc(String docId) {
    AppDialog.show(
      context: context,
      iconWidget: HugeIcon(
        icon: HugeIcons.strokeRoundedDelete01,
        color: AppColors.heartRed,
        size: 36.r,
      ),
      iconColor: AppColors.heartRed,
      title: "delete_bonus_title".tr(),
      description: "delete_bonus_confirm".tr(),
      confirmText: "delete".tr(),
      confirmButtonColor: AppColors.heartRed,
      cancelText: "cancel".tr(),
      onConfirm: () async {
        Navigator.pop(context);
        try {
          await FirebaseFirestore.instance.collection("bonuses").doc(docId).delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("bonus_deleted_success".tr(), style: GoogleFonts.cairo()),
                backgroundColor: AppColors.successGreen,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Failed to delete bonus: $e", style: GoogleFonts.cairo()),
                backgroundColor: AppColors.heartRed,
              ),
            );
          }
        }
      },
    );
  }

  // ================= UI BUILD =================
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;

    if (!widget.user.canManageBonus) {
      return Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(backgroundColor: pageBg, elevation: 0),
        body: Center(
          child: Text(
            "Access Denied",
            style: GoogleFonts.cairo(color: AppColors.heartRed, fontSize: 16.sp),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            /// App Bar Header
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(10.r),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: textColor,
                        size: 18.r,
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      "bonus_management".tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 20.sp,
                        color: textColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// Tabs Header (Management vs Statistics)
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.softGold,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                labelColor: Colors.black87,
                unselectedLabelColor: textColor,
                labelStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14.sp),
                tabs: [
                  Tab(text: "bonus_management".tr()),
                  Tab(text: "bonus_stats".tr()),
                ],
              ),
            ),

            SizedBox(height: 12.h),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    /// TAB 1: BONUS MANAGEMENT & USERS LIST
                    _buildManagementTab(isDark, textColor, mutedColor, borderColor),

                    /// TAB 2: BONUS STATISTICS DASHBOARD
                    _buildStatisticsTab(isDark, textColor, mutedColor, borderColor),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// MANAGEMENT TAB: Search user, view details, Add/Spent bonus
  Widget _buildManagementTab(bool isDark, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      children: [
        /// Search Bar
        TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
          style: GoogleFonts.cairo(color: textColor),
          decoration: InputDecoration(
            hintText: "search_by_name_hint".tr(),
            hintStyle: GoogleFonts.cairo(color: mutedColor),
            prefixIcon: const Icon(Icons.search_rounded, color: AppColors.softGold),
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03),
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: borderColor),
            ),
          ),
        ),

        SizedBox(height: 14.h),

        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getUsersStream(),
            builder: (context, userSnap) {
              if (userSnap.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Error loading users: ${userSnap.error}",
                        style: GoogleFonts.cairo(color: AppColors.heartRed, fontSize: 14.sp),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 12.h),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.softGold),
                        onPressed: () => setState(() {}),
                        child: Text("retry".tr(), style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }

              if (!userSnap.hasData && userSnap.connectionState == ConnectionState.waiting) {
                return const LoadingState();
              }

              final userDocs = userSnap.data?.docs ?? [];
              final filteredUsers = userDocs.map((doc) => UserData.fromJson(doc.data() as Map<String, dynamic>, doc.id)).where((u) {
                if (_searchQuery.isEmpty) return true;
                final name = (u.name ?? "").toLowerCase();
                final phone = (u.phone ?? "").toLowerCase();
                return name.contains(_searchQuery) || phone.contains(_searchQuery);
              }).toList();

              if (filteredUsers.isEmpty) {
                return EmptyState(
                  title: "no_members_found".tr(),
                  hugeIcon: HugeIcons.strokeRoundedUserGroup,
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _getBonusStream(),
                builder: (context, bonusSnap) {
                  if (bonusSnap.hasError) {
                    return Center(
                      child: Text(
                        "Error loading bonus records: ${bonusSnap.error}",
                        style: GoogleFonts.cairo(color: AppColors.heartRed, fontSize: 13.sp),
                      ),
                    );
                  }

                  if (!bonusSnap.hasData && bonusSnap.connectionState == ConnectionState.waiting) {
                    return const LoadingState();
                  }

                  final bonusDocs = bonusSnap.data?.docs ?? [];

                  // Map totals per user
                  final Map<String, double> userGrantedMap = {};
                  final Map<String, double> userSpentMap = {};

                  for (var doc in bonusDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final uId = data["userId"] as String? ?? "";
                    if (uId.isEmpty) continue;
                    final amt = (data["amount"] as num?)?.toDouble() ?? 0.0;
                    final spnt = (data["spent"] as num?)?.toDouble() ?? 0.0;
                    userGrantedMap[uId] = (userGrantedMap[uId] ?? 0.0) + amt;
                    userSpentMap[uId] = (userSpentMap[uId] ?? 0.0) + spnt;
                  }

                  return ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredUsers.length,
                    separatorBuilder: (_, __) => SizedBox(height: 10.h),
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      final granted = userGrantedMap[u.uid] ?? 0.0;
                      final spent = userSpentMap[u.uid] ?? 0.0;
                      final remaining = granted - spent;

                      return GlassCard(
                        padding: EdgeInsets.all(14.r),
                        borderRadius: 18.r,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20.r,
                                  backgroundColor: AppColors.softGold.withOpacity(0.15),
                                  child: Text(
                                    (u.name?.isNotEmpty == true) ? u.name![0].toUpperCase() : "U",
                                    style: GoogleFonts.cairo(color: AppColors.softGold, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        u.name ?? "User",
                                        style: GoogleFonts.cairo(
                                          fontSize: 15.sp,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        "Granted: ${_formatNum(granted)} | Remaining: ${_formatNum(remaining)} pts",
                                        style: GoogleFonts.cairo(
                                          fontSize: 12.sp,
                                          color: AppColors.successGreen,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: "add_bonus".tr(),
                                  icon: const Icon(Icons.add_circle_outline, color: AppColors.softGold),
                                  onPressed: () => _showAddBonusDialog(u),
                                ),
                                IconButton(
                                  tooltip: "record_spent".tr(),
                                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.heartRed),
                                  onPressed: () => _showRecordSpentDialog(u, remaining),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// STATISTICS TAB: Aggregated Summary + Per-User Breakdown Table + History Log
  Widget _buildStatisticsTab(bool isDark, Color textColor, Color mutedColor, Color borderColor) {
    debugPrint("[BonusStatistics] Building Statistics Tab UI");
    return StreamBuilder<QuerySnapshot>(
      stream: _getBonusStream(),
      builder: (context, snapshot) {
        debugPrint("[BonusStatistics] StreamBuilder update: connectionState=${snapshot.connectionState}, hasData=${snapshot.hasData}, hasError=${snapshot.hasError}");

        // 1. Error state with Retry button
        if (snapshot.hasError) {
          debugPrint("[BonusStatistics][ERROR] Firestore snapshot error: ${snapshot.error}");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "failed_load_bonus_stats".tr() + "\n(${snapshot.error})",
                  style: GoogleFonts.cairo(color: AppColors.heartRed, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.softGold),
                  onPressed: () {
                    debugPrint("[BonusStatistics] Retry button pressed");
                    setState(() {});
                  },
                  child: Text("retry".tr(), style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }

        // 2. Loading state ONLY when no data exists yet
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          debugPrint("[BonusStatistics] Loading started... waiting for initial snapshot");
          return const LoadingState();
        }

        // 3. Data exists or stream snapshot active
        final rawDocs = snapshot.data?.docs ?? [];
        debugPrint("[BonusStatistics] Raw bonus documents retrieved from Firestore = ${rawDocs.length}");

        // 4. Empty State
        if (rawDocs.isEmpty) {
          debugPrint("[BonusStatistics] Empty state: 0 bonus documents in collection");
          return EmptyState(
            title: "no_bonus_records".tr(),
            hugeIcon: HugeIcons.strokeRoundedAward01,
          );
        }

        try {
          // Sort documents safely client-side by createdAt DESC
          final docs = rawDocs.toList()
            ..sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>? ?? {};
              final dataB = b.data() as Map<String, dynamic>? ?? {};
              final tA = _parseTimestamp(dataA["createdAt"]);
              final tB = _parseTimestamp(dataB["createdAt"]);
              if (tA != null && tB != null) return tB.compareTo(tA);
              if (tA != null) return -1;
              if (tB != null) return 1;
              return 0;
            });

          double totalGranted = 0.0;
          double totalSpent = 0.0;
          final Set<String> usersWithBonus = {};
          final Map<String, AdminBonusUserBreakdown> userAggMap = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final uId = _parseString(data["userId"] ?? data["uid"] ?? data["user_id"] ?? data["id"]);
            final uName = _parseString(data["userName"] ?? data["name"] ?? data["user_name"] ?? "Member");
            final amt = _parseDouble(data["amount"] ?? data["points"] ?? data["bonus"]);
            final spnt = _parseDouble(data["spent"] ?? data["spentAmount"] ?? data["spent_amount"]);
            final reason = _parseString(data["reason"] ?? data["note"]);

            totalGranted += amt;
            totalSpent += spnt;

            final effectiveKey = uId.isNotEmpty ? uId : (uName.isNotEmpty ? uName : doc.id);
            final effectiveName = uName.isNotEmpty ? uName : "Member ($effectiveKey)";

            if (!userAggMap.containsKey(effectiveKey)) {
              userAggMap[effectiveKey] = AdminBonusUserBreakdown(
                userId: effectiveKey,
                userName: effectiveName,
                totalGranted: 0.0,
                totalSpent: 0.0,
                reasons: [],
              );
            }

            final userAgg = userAggMap[effectiveKey]!;
            userAgg.totalGranted += amt;
            userAgg.totalSpent += spnt;

            if (userAgg.totalGranted > 0) {
              usersWithBonus.add(effectiveKey);
            }

            if (reason.isNotEmpty && !userAgg.reasons.contains(reason)) {
              userAgg.reasons.add(reason);
            }
          }

          final double totalRemaining = totalGranted - totalSpent;
          final int transactionsCount = docs.length;

          final userBreakdownList = userAggMap.values.toList()
            ..sort((a, b) => b.totalGranted.compareTo(a.totalGranted));

          debugPrint("[BonusStatistics] Statistics calculated successfully:");
          debugPrint("[BonusStatistics] - Total Granted: $totalGranted");
          debugPrint("[BonusStatistics] - Total Spent: $totalSpent");
          debugPrint("[BonusStatistics] - Total Remaining: $totalRemaining");
          debugPrint("[BonusStatistics] - Users with Bonus: ${usersWithBonus.length}");
          debugPrint("[BonusStatistics] - Total Transactions: $transactionsCount");
          debugPrint("[BonusStatistics] - Breakdown Rows: ${userBreakdownList.length}");
          debugPrint("[BonusStatistics] UI received Loaded state");

        return ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            /// 1. Overall Summary Statistics Grid Cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.6,
              children: [
                _buildStatCard("total_bonus".tr(), _formatNum(totalGranted), AppColors.softGold, HugeIcons.strokeRoundedAward01, isDark, textColor),
                _buildStatCard("total_spent".tr(), _formatNum(totalSpent), AppColors.heartRed, HugeIcons.strokeRoundedMinusSignCircle, isDark, textColor),
                _buildStatCard("remaining_bonus".tr(), _formatNum(totalRemaining), AppColors.successGreen, HugeIcons.strokeRoundedCheckmarkCircle02, isDark, textColor),
                _buildStatCard("users_with_bonus".tr(), "${usersWithBonus.length}", AppColors.primaryLightNavy, HugeIcons.strokeRoundedUserGroup, isDark, textColor),
              ],
            ),

            SizedBox(height: 12.h),

            /// Total Transactions Counter
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: AppColors.softGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.softGold.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "total_transactions".tr(),
                    style: GoogleFonts.cairo(fontSize: 14.sp, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    "$transactionsCount",
                    style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.w900, color: AppColors.softGold),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            /// 2. Per-User Bonus Statistics Breakdown Table
            Text(
              "user_breakdown".tr(),
              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
            ),

            SizedBox(height: 10.h),

            GlassCard(
              padding: EdgeInsets.all(12.r),
              borderRadius: 18.r,
              child: Column(
                children: [
                  /// Table Header
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      children: [
                        Expanded(flex: 3, child: Text("User", style: GoogleFonts.cairo(fontSize: 12.sp, fontWeight: FontWeight.bold, color: textColor))),
                        Expanded(flex: 2, child: Text("Granted", textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.softGold))),
                        Expanded(flex: 2, child: Text("Spent", textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.heartRed))),
                        Expanded(flex: 2, child: Text("Remaining", textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.bold, color: AppColors.successGreen))),
                      ],
                    ),
                  ),

                  SizedBox(height: 6.h),

                  /// User Table Rows
                  ...userBreakdownList.map((userAgg) {
                    final primaryReason = userAgg.reasons.isNotEmpty ? userAgg.reasons.first : "";

                    return Container(
                      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderColor.withOpacity(0.5))),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  userAgg.userName,
                                  style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold, color: textColor),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(flex: 2, child: Text(_formatNum(userAgg.totalGranted), textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.softGold))),
                              Expanded(flex: 2, child: Text(_formatNum(userAgg.totalSpent), textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.heartRed))),
                              Expanded(flex: 2, child: Text(_formatNum(userAgg.remaining), textAlign: TextAlign.center, style: GoogleFonts.cairo(fontSize: 13.sp, fontWeight: FontWeight.bold, color: AppColors.successGreen))),
                            ],
                          ),
                          if (primaryReason.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Row(
                              children: [
                                Icon(Icons.star_rounded, size: 12.r, color: AppColors.softGold),
                                SizedBox(width: 4.w),
                                Expanded(
                                  child: Text(
                                    primaryReason,
                                    style: GoogleFonts.cairo(fontSize: 11.sp, color: mutedColor),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            SizedBox(height: 20.h),

            /// 3. All Bonus Transaction Log with Edit & Delete Actions
            Text(
              "total_transactions".tr(),
              style: GoogleFonts.cairo(fontSize: 16.sp, fontWeight: FontWeight.bold, color: textColor),
            ),

            SizedBox(height: 10.h),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => SizedBox(height: 8.h),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final userName = (data["userName"] ?? "User").toString();
                final amount = (data["amount"] as num?)?.toDouble() ?? 0.0;
                final spent = (data["spent"] as num?)?.toDouble() ?? 0.0;
                final reason = (data["reason"] ?? "").toString();

                final bool isGrant = amount > 0;

                return GlassCard(
                  padding: EdgeInsets.all(12.r),
                  borderRadius: 14.r,
                  child: Row(
                    children: [
                      Icon(
                        isGrant ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        color: isGrant ? AppColors.successGreen : AppColors.heartRed,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName,
                              style: GoogleFonts.cairo(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            if (reason.isNotEmpty)
                              Text(
                                reason,
                                style: GoogleFonts.cairo(fontSize: 11.sp, color: mutedColor),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        isGrant ? "+${_formatNum(amount)}" : "-${_formatNum(spent)}",
                        style: GoogleFonts.cairo(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: isGrant ? AppColors.successGreen : AppColors.heartRed,
                        ),
                      ),
                      SizedBox(width: 6.w),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(4.r),
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.softGold),
                        onPressed: () => _showEditBonusDialog(doc),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.all(4.r),
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.heartRed),
                        onPressed: () => _deleteBonusDoc(doc.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
        } catch (e, st) {
          debugPrint("[BONUS_STATS][ERROR] Calculation failed: $e\n$st");
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Error calculating statistics: $e",
                  style: GoogleFonts.cairo(color: AppColors.heartRed, fontSize: 14.sp),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12.h),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.softGold),
                  onPressed: () {
                    debugPrint("[BonusStatistics] Retry button pressed after exception");
                    setState(() {});
                  },
                  child: Text("retry".tr(), style: GoogleFonts.cairo(color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatCard(String title, String val, Color color, List<List<dynamic>> iconData, bool isDark, Color textColor) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.cairo(fontSize: 11.sp, fontWeight: FontWeight.bold, color: textColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              HugeIcon(icon: iconData, color: color, size: 18.r),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            val,
            style: GoogleFonts.cairo(fontSize: 18.sp, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }

  String _formatNum(double val) {
    if (val.truncateToDouble() == val) {
      return val.truncate().toString();
    }
    return val.toStringAsFixed(1);
  }

  static double _parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val.trim()) ?? 0.0;
    return 0.0;
  }

  static String _parseString(dynamic val) {
    if (val == null) return "";
    return val.toString().trim();
  }

  static Timestamp? _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val;
    if (val is String) {
      final dt = DateTime.tryParse(val.trim());
      if (dt != null) return Timestamp.fromDate(dt);
    }
    if (val is int) return Timestamp.fromMillisecondsSinceEpoch(val);
    return null;
  }
}
