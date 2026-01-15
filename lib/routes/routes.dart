import 'package:flutter/material.dart';
import 'package:reel_recommandation/screens/home_page.dart';
import 'package:reel_recommandation/screens/login_page.dart';
import 'package:reel_recommandation/screens/notification_screen.dart';
import 'package:reel_recommandation/screens/profile_page.dart';
import 'package:reel_recommandation/screens/reel_page.dart';
import 'package:reel_recommandation/screens/search_screen.dart';
import 'package:reel_recommandation/screens/signup_page.dart';

class AppRoutes {
  static const String home = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String reel = '/reel';
  static const String profile = '/profile';
  static const String search = '/search';
  static const String notification = '/notification';

  static final Map<String, WidgetBuilder> routes = {
    home: (_) => HomePage(),
    login: (_) => LoginPage(),
    signup: (_) => SignupPage(),
    reel: (_) => ReelPage(),
    profile: (_) => ProfilePage(),
    search: (_) => SearchScreen(),
    notification: (_) => NotificationScreen(),
  };
}