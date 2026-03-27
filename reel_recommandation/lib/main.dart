import 'package:flutter/material.dart';
import 'package:reel_recommandation/utils/bottom_navigation_bar_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reel Recommendation',
      debugShowCheckedModeBanner: false,

      home: BottomNavigationBarWidget(),
    );
  }
}
