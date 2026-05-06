import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:platformexamapp/exam_app.dart';
import 'package:platformexamapp/features/auth/cubit/cubit/auth_cubit.dart';
import 'package:platformexamapp/features/home/cubit/cubit/home_cubit.dart';
import 'package:platformexamapp/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => HomeCubit()..getUserData()),
      ],
      child: const ExamApp(),
    ),
  );
}
