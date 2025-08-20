import 'package:flutter/material.dart';
import 'main_window.dart';

void main() {
  print('main() called');
  runApp(const AIRSimulatorApp());
}

class AIRSimulatorApp extends StatelessWidget {
  const AIRSimulatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIR Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainWindow(),
      debugShowCheckedModeBanner: false,
    );
  }
}
