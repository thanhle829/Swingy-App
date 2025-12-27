import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/camera/camera_page.dart';
import 'features/feedback/feedback_page.dart';
import 'features/poses/poses_page.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const CameraPage()),
        GoRoute(path: '/feedback', builder: (context, state) => const FeedbackPage()),
        GoRoute(path: '/poses', builder: (context, state) => const PosesPage()),
      ],
    );

    return MaterialApp.router(
      title: 'Posture Analyzer',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        scaffoldBackgroundColor: const Color(0xFF0F1720),
      ),
      routerConfig: _router,
    );
  }
}
