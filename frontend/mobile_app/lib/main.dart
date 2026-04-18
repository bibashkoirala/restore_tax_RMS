import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const RtmsApp());
}

class RtmsApp extends StatelessWidget {
  const RtmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RTMS',
      theme: AppTheme.governmentTheme,
      debugShowCheckedModeBanner: false,
      home: const DashboardScreen(),
    );
  }
}
