import 'package:flutter/material.dart';
import 'app_shell.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // gets rid of the debug banner
      home: AppShell(), // the shell is now the home
    );
  }
}