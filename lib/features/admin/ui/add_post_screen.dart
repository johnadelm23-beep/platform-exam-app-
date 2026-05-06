import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/core/widgets/app_button.dart';
import 'package:platformexamapp/core/widgets/custom_text_form_field.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _postController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLoading = false;

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  Future<void> addPost() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      await FirebaseFirestore.instance.collection("posts").add({
        "text": _postController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
        "createdBy": "admin",
      });

      _postController.clear();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Post added successfully ✅")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.whiteColor,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios),
        ),
        title: Text(
          "Create a post",
          style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      backgroundColor: AppColors.whiteColor,

      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 10.h),

                /// 🖼️ image
                Image.asset(
                  'assets/images/background.png',
                  width: 120.w,
                  height: 120.h,
                ),

                SizedBox(height: 30.h),

                /// ✍️ input
                CustomTextFormField(
                  hintText: "Write something for church...",
                  keyboardType: TextInputType.text,
                  controller: _postController,
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return "Post cannot be empty";
                    }
                    return null;
                  },
                ),

                SizedBox(height: 40.h),

                /// 🚀 button
                AppButton(
                  text: isLoading ? "Posting..." : "Add Post",
                  onPressed: isLoading ? null : addPost,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
