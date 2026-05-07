import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CustomPoduim extends StatelessWidget {
  const CustomPoduim({
    super.key,
    required this.user,
    required this.rank,
    required this.color,
  });
  final Map<String, dynamic> user;
  final int rank;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getUserName(user["userId"]),
      builder: (context, snap) {
        final name = snap.data ?? "...";

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CircleAvatar(
              radius: rank == 1 ? 34 : 28,
              backgroundColor: color,
              child: Text("$rank", style: const TextStyle(color: Colors.white)),
            ),

            SizedBox(height: 8),

            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),

            SizedBox(height: 4),

            Text(
              "${user["totalScore"]}",
              style: const TextStyle(color: Colors.green),
            ),

            SizedBox(height: 10),

            Container(
              width: 70,
              height: rank == 1 ? 160 : 120,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        );
      },
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
