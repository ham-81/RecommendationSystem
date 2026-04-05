import 'package:flutter/material.dart';
import 'package:reel_recommandation/routes/routes.dart';
import 'package:reel_recommandation/utils/bottom_navigation_bar_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reel Recommendation',
      debugShowCheckedModeBanner: false,
      home: BottomNavigationBarWidget(),
      routes: AppRoutes.routes,
    );
  }
}
