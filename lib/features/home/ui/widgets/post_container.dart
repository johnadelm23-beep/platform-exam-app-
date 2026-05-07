import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:iconly/iconly.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/auth/data/models/user_data.dart';

class PostContainer extends StatelessWidget {
  const PostContainer({
    super.key,
    required this.isArabic,
    required this.isLiked,
    required this.text,
    required this.user,
    required this.uid,
    required this.likeCount,
    required this.post,
  });

  final bool isArabic;
  final bool isLiked;
  final String text;
  final UserData user;
  final String uid;
  final int likeCount;
  final QueryDocumentSnapshot<Object?> post;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// 🔹 TEXT + DELETE
            Row(
              children: [
                Icon(Icons.campaign, color: Colors.blue),
                SizedBox(width: 10.w),

                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (user.isAdmin == true)
                  IconButton(
                    icon: Icon(IconlyLight.delete, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context),
                  ),
              ],
            ),

            SizedBox(height: 10.h),

            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final ref = FirebaseFirestore.instance
                        .collection("posts")
                        .doc(post.id);

                    if (isLiked) {
                      await ref.update({"likes.$uid": FieldValue.delete()});
                    } else {
                      await ref.update({"likes.$uid": true});
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? IconlyBold.heart : IconlyBroken.heart,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      SizedBox(width: 5.w),
                      Text("Like"),
                    ],
                  ),
                ),

                SizedBox(width: 10.w),

                Text("$likeCount likes", style: TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: AppColors.whiteColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(15.r),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 35.r,
                ),
              ),

              SizedBox(height: 15.h),

              Text(
                "Delete Post",
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 10.h),

              Text(
                "Are you sure you want to delete this post?\nThis action cannot be undone.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: Colors.black),
              ),

              SizedBox(height: 20.h),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Cancel",
                        style: TextStyle(fontSize: 18.sp, color: Colors.black),
                      ),
                    ),
                  ),

                  SizedBox(width: 10.w),

                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => _deletePost(context),
                      child: Text(
                        "Delete",
                        style: TextStyle(
                          fontSize: 18.sp,
                          color: AppColors.whiteColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deletePost(BuildContext context) async {
    Navigator.pop(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Deleting post..."),
          duration: Duration(seconds: 1),
        ),
      );
      await FirebaseFirestore.instance
          .collection("posts")
          .doc(post.id)
          .delete();
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Post deleted successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Failed to delete post"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
