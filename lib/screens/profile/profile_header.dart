import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onFollowToggle;

  const ProfileHeader({
    super.key,
    required this.isFollowing,
    required this.onFollowToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 20),

        const CircleAvatar(
          radius: 40,
          backgroundColor: Colors.grey,
        ),

        const SizedBox(height: 10),

        const Text(
          "Username",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),

        const SizedBox(height: 10),

        ElevatedButton(
          onPressed: onFollowToggle,
          child: Text(isFollowing ? "Unfollow" : "Follow"),
        ),
      ],
    );
  }
}