import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:platformexamapp/core/theme/app_colors.dart';
import 'package:platformexamapp/features/states/ui/widgets/custom_poduim.dart';

class CustomBodyContainer extends StatelessWidget {
  const CustomBodyContainer({
    super.key,
    required this.top3,
    required this.others,
  });
  final List<Map<String, dynamic>> top3;
  final List<Map<String, dynamic>> others;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),

      child: Column(
        children: [
          SizedBox(height: 10.h),

          SizedBox(
            height: 210.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (top3.length > 1)
                  CustomPoduim(user: top3[1], rank: 2, color: Colors.grey),
                if (top3.isNotEmpty)
                  CustomPoduim(user: top3[0], rank: 1, color: Colors.amber),
                if (top3.length > 2)
                  CustomPoduim(
                    user: top3[2],
                    rank: 3,
                    color: AppColors.primaryColor,
                  ),
              ],
            ),
          ),

          const Divider(),

          Expanded(
            child: ListView.separated(
              itemCount: others.length,
              separatorBuilder: (_, __) => SizedBox(height: 10.h),
              itemBuilder: (context, index) {
                final user = others[index];

                return FutureBuilder<String>(
                  future: getUserName(user["userId"]),
                  builder: (context, snap) {
                    final name = snap.data ?? "...";

                    return Container(
                      padding: EdgeInsets.all(16.r),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.blue.shade100),
                      ),

                      child: Row(
                        children: [
                          Text(
                            "#${index + 4}",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          SizedBox(width: 12.w),

                          Expanded(
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12.w,
                              vertical: 6.h,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "${user["totalScore"]}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> getUserName(String userId) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get();

    return doc.data()?["name"] ?? "Unknown";
  }
}
