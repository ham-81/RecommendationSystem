import 'package:flutter/material.dart';

class ProfileStats extends StatelessWidget {
  final int posts;
  final int followers;
  final int following;

  const ProfileStats({
    super.key,
    required this.posts,
    required this.followers,
    required this.following,
  });
  Widget stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        stat(posts.toString(), "Posts"),
        stat(followers.toString(), "Followers"),
        stat(following.toString(), "Following"),
      ],
    );
  }
}
