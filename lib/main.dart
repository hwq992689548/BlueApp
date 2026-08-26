import 'package:blue_app/core/app_names.dart';
import 'package:blue_app/pages/blue_home_page.dart';
import 'package:blue_app/widgets/lp_toast.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BlueApp());
}

class BlueApp extends StatelessWidget {
  const BlueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppNames.en,
      navigatorObservers: [lpToastNavigatorObserver],
      builder: (context, child) => lpToastInit(context, child),
      home: const BlueHomePage(),
    );
  }
}
