import 'package:flutter/material.dart';
import 'package:reel_recommandation/screens/liked_reel_page.dart';
import 'package:reel_recommandation/screens/login_page.dart';
import 'package:reel_recommandation/screens/saved_posts_page.dart';
import 'package:reel_recommandation/screens/settings_page.dart';
import 'package:reel_recommandation/screens/signup_page.dart';

class AppRoutes {
  static const String login = '/login';
  static const String signup = '/signup';
  static const String settings = '/settings';
  static const String likedReelsPage = '/liked_reels';
  static const String savedPostsPage = '/saved_posts';

  static final Map<String, WidgetBuilder> routes = {
    login: (_) => LoginPage(),
    signup: (_) => SignupPage(),
    settings: (_) => SettingsPage(),
    likedReelsPage: (_) => const LikedReelsPage(),
    savedPostsPage: (_) => const SavedPostsPage(),
  };
}
