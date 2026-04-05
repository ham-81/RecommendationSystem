import 'package:flutter/material.dart';
import 'package:reel_recommandation/screens/home_page.dart';
import 'package:reel_recommandation/screens/notification_screen.dart';
import 'package:reel_recommandation/screens/profile_page.dart';
import 'package:reel_recommandation/screens/reel_page.dart';
import 'package:reel_recommandation/screens/search_screen.dart';

class BottomNavigationBarWidget extends StatefulWidget {
  const BottomNavigationBarWidget({super.key});

  @override
  State<BottomNavigationBarWidget> createState() =>
      _BottomNavigationBarWidgetState();
}

class _BottomNavigationBarWidgetState extends State<BottomNavigationBarWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.home),
            icon: Icon(Icons.home_outlined),
            label: '',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.search),
            icon: Icon(Icons.search_outlined),
            label: '',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.video_library),
            icon: Icon(Icons.video_library_outlined),
            label: '',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.favorite),
            icon: Icon(Icons.favorite_border),
            label: '',
            backgroundColor: Colors.black,
          ),
          BottomNavigationBarItem(
            activeIcon: Icon(Icons.person,),
            icon: Icon(Icons.person_outline),
            label: '',
            backgroundColor: Colors.black,
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: <Widget>[HomePage(), SearchScreen(), ReelPage(), NotificationScreen(), ProfilePage()],
      ),
    );
  }
}
