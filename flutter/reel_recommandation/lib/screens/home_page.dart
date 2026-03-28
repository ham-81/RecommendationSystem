import 'package:flutter/material.dart';
import 'package:reel_recommandation/utils/colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        leading: Icon(Icons.camera_alt_outlined, color: darkTextPrimary),
        backgroundColor: darkBackground,
        centerTitle: true,
        title: Image.asset('assets/insta_logo.png', height: 32),
      ),
      body: CustomScrollView(
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              return Column(
                children: [_buildInstagramPost(index), SizedBox(height: 8)],
              );
            }, childCount: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildInstagramPost(int index) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(color: Colors.grey[800]!, width: 0.5),
          bottom: BorderSide(color: Colors.grey[800]!, width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with User Info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey[700],
                  child: Text(
                    'U${index + 1}',
                    style: TextStyle(
                      color: Colors.grey[300],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'user_${index + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${index + 1}h ago',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // More Options
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                  onPressed: () {},
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          // Post Image
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[900]!.withOpacity(0.6),
                  Colors.purple[900]!.withOpacity(0.6),
                ],
              ),
            ),
            child: Center(
              child: Text(
                'Post ${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                // Like Button
                IconButton(
                  icon: Icon(
                    Icons.favorite_border,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  onPressed: () {},
                  splashRadius: 24,
                ),
                // Comment Button
                IconButton(
                  icon: Icon(
                    Icons.chat_bubble_outline,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  onPressed: () {},
                  splashRadius: 24,
                ),
                // Share Button
                IconButton(
                  icon: Icon(
                    Icons.share_outlined,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  onPressed: () {},
                  splashRadius: 24,
                ),
                const Spacer(),
                // Save Button
                IconButton(
                  icon: Icon(
                    Icons.bookmark_border,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                  onPressed: () {},
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          // Likes Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              '${1234 + (index * 100)} likes',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 4),
          // Caption
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'user_${index + 1} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  TextSpan(
                    text: 'Amazing moment captured! 📸 #instagram #photography',
                    style: TextStyle(color: Colors.grey[300], fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          // View Comments
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: GestureDetector(
              onTap: () {},
              child: Text(
                'View all ${(index + 1) * 50} comments',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
