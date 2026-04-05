import 'package:flutter/material.dart';
import 'package:reel_recommandation/screens/profile/profile_header.dart';
import 'package:reel_recommandation/screens/profile/profile_stats.dart';
import 'package:reel_recommandation/utils/orbit_intersests.dart';
import 'package:reel_recommandation/utils/page_center_avatar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int followers = 5200;
  int following = 300;
  int posts = 120;

  bool isFollowing = false;

  void toggleFollow() {
    setState(() {
      if (isFollowing) {
        followers--; // simulate unfollow
      } else {
        followers++; // simulate follow
      }
      isFollowing = !isFollowing;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              ProfileHeader(
                isFollowing: isFollowing,
                onFollowToggle: toggleFollow,
              ),

              const SizedBox(height: 10),

              ProfileStats(
                posts: posts,
                followers: followers,
                following: following,
              ),

              const SizedBox(height: 30),

              SizedBox(
                height: 320,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [ProfileCenterAvatar(), OrbitInterests()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
