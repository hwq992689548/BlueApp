import 'package:blue_app/pages/blue_home_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BlueApp());
}

class BlueApp extends StatelessWidget {
  const BlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'BlueApp',
      home: BlueHomePage(),
    );
  }
}
