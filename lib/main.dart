import 'package:flutter/material.dart';
import 'package:sidewalk_analysis_frontend/pages/analysis_screen.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sidewalk AI',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AnalysisScreen(),
    );
  }
}