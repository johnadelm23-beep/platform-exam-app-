import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';
import 'package:platformexamapp/core/widgets/glass_card.dart';

class DraftQuestion {
  final TextEditingController questionController = TextEditingController();
  final List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  int correctIndex = 0;
}

class AddGameScreen extends StatefulWidget {
  const AddGameScreen({super.key});

  @override
  State<AddGameScreen> createState() => _AddGameScreenState();
}

class _AddGameScreenState extends State<AddGameScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _timeController = TextEditingController(text: "15");
  final _maxTeamsController = TextEditingController(text: "8");
  final _maxMembersController = TextEditingController(text: "5");

  final List<DraftQuestion> _questions = [DraftQuestion()];
  bool _isPublishing = false;

  void _addQuestionField() {
    setState(() => _questions.add(DraftQuestion()));
  }

  void _removeQuestionField(int index) {
    if (_questions.length > 1) {
      setState(() => _questions.removeAt(index));
    }
  }

  bool _validate() {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar("Game title cannot be empty", isError: true);
      return false;
    }

    final timeLimit = int.tryParse(_timeController.text.trim());
    if (timeLimit == null || timeLimit <= 0) {
      _showSnackBar("Enter valid time per question in seconds", isError: true);
      return false;
    }

    final maxTeams = int.tryParse(_maxTeamsController.text.trim());
    if (maxTeams == null || maxTeams <= 0) {
      _showSnackBar("Enter valid number of teams", isError: true);
      return false;
    }

    final maxMembers = int.tryParse(_maxMembersController.text.trim());
    if (maxMembers == null || maxMembers <= 0) {
      _showSnackBar("Enter valid max members per team", isError: true);
      return false;
    }

    for (int i = 0; i < _questions.length; i++) {
      final q = _questions[i];
      if (q.questionController.text.trim().isEmpty) {
        _showSnackBar("Question #${i + 1} text cannot be empty", isError: true);
        return false;
      }

      int validOptionsCount = 0;
      for (var opt in q.optionControllers) {
        if (opt.text.trim().isNotEmpty) validOptionsCount++;
      }

      if (validOptionsCount < 2) {
        _showSnackBar("Question #${i + 1} must have at least 2 options", isError: true);
        return false;
      }
    }

    return true;
  }

  Future<void> _publishGame() async {
    if (!_validate()) return;

    final adminUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    setState(() => _isPublishing = true);

    try {
      final timeLimit = int.parse(_timeController.text.trim());
      final maxTeams = int.parse(_maxTeamsController.text.trim());
      final maxMembers = int.parse(_maxMembersController.text.trim());

      final gameRef = await FirebaseFirestore.instance.collection("games").add({
        "title": _titleController.text.trim(),
        "description": _descController.text.trim(),
        "pin": "",
        "status": "draft",
        "currentQuestionIndex": 0,
        "timePerQuestion": timeLimit,
        "maxTeams": maxTeams,
        "maxMembersPerTeam": maxMembers,
        "isPaused": false,
        "pausedRemainingSeconds": 0,
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": adminUid,
      });

      final batch = FirebaseFirestore.instance.batch();

      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        final qRef = gameRef.collection("questions").doc();
        final optionsList = q.optionControllers
            .map((c) => c.text.trim())
            .where((text) => text.isNotEmpty)
            .toList();

        batch.set(qRef, {
          "order": i,
          "questionText": q.questionController.text.trim(),
          "options": optionsList,
          "correctAnswerIndex": q.correctIndex.clamp(0, optionsList.length - 1),
          "timeLimit": timeLimit,
        });
      }

      await batch.commit();

      if (!mounted) return;

      _showSnackBar("✅ Game created successfully!", isError: false);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showSnackBar("Failed to create game: $e", isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _isPublishing = false);
      }
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.cairo()),
        backgroundColor: isError ? AppColors.heartRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? AppColors.darkPageBg : AppColors.lightPageBg;
    final textColor = isDark ? AppColors.darkTextMain : AppColors.lightTextMain;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
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
                  Text(
                    "create_game".tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 20.sp,
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
                  border: Border(top: BorderSide(color: borderColor, width: 1)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      CustomTextFormField(
                        hintText: "Game Title (e.g. Bible Challenge 🔥)",
                        controller: _titleController,
                      ),
                      SizedBox(height: 10.h),
                      CustomTextFormField(
                        hintText: "Description (Optional)",
                        controller: _descController,
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextFormField(
                              hintText: "Time Limit (s)",
                              controller: _timeController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomTextFormField(
                              hintText: "max_teams".tr(),
                              controller: _maxTeamsController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: CustomTextFormField(
                              hintText: "max_members".tr(),
                              controller: _maxMembersController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Questions (${_questions.length})",
                            style: GoogleFonts.cairo(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          IconButton(
                            onPressed: _addQuestionField,
                            icon: const Icon(Icons.add_circle_outline, color: AppColors.softGold),
                          ),
                        ],
                      ),
                      SizedBox(height: 10.h),
                      ...List.generate(_questions.length, (qIdx) {
                        final q = _questions[qIdx];
                        return Padding(
                          padding: EdgeInsets.only(bottom: 16.h),
                          child: GlassCard(
                            padding: EdgeInsets.all(16.r),
                            borderRadius: 20.r,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Question #${qIdx + 1}",
                                      style: GoogleFonts.cairo(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.softGold,
                                      ),
                                    ),
                                    if (_questions.length > 1)
                                      IconButton(
                                        onPressed: () => _removeQuestionField(qIdx),
                                        icon: const Icon(Icons.delete_outline, color: AppColors.heartRed),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 8.h),
                                CustomTextFormField(
                                  hintText: "Enter question text...",
                                  controller: q.questionController,
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  "Options & Correct Answer:",
                                  style: GoogleFonts.cairo(fontSize: 12.sp, color: textColor, fontWeight: FontWeight.w600),
                                ),
                                SizedBox(height: 8.h),
                                ...List.generate(4, (optIdx) {
                                  return Padding(
                                    padding: EdgeInsets.only(bottom: 8.h),
                                    child: Row(
                                      children: [
                                        Radio<int>(
                                          value: optIdx,
                                          groupValue: q.correctIndex,
                                          activeColor: AppColors.softGold,
                                          onChanged: (val) {
                                            if (val != null) {
                                              setState(() => q.correctIndex = val);
                                            }
                                          },
                                        ),
                                        Expanded(
                                          child: CustomTextFormField(
                                            hintText: "Option ${optIdx + 1}",
                                            controller: q.optionControllers[optIdx],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 20.h),
                      AppButton(
                        onPressed: _isPublishing ? null : _publishGame,
                        text: _isPublishing ? "Saving..." : "Save & Publish Game",
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
