import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:platformexamapp/exam_app.dart';
import 'package:platformexamapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(ExamApp());
}
