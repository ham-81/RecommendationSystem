import 'package:flutter/material.dart';
import 'package:reel_recommandation/utils/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> reels = [];
  bool isLoading = true;
  final Map<int, bool> likedPosts = {};
  final Map<int, bool> savedPosts = {};

  @override
  void initState() {
    super.initState();
    fetchReels();
  }

 Future<void> fetchReels() async {
  try {
    final response = await http.get(
      Uri.parse("http://localhost:8001/api/reels/feed"),
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        reels = List<Map<String, dynamic>>.from(data["data"]);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  } catch (e) {
    debugPrint("ERROR: $e");
    setState(() {
      isLoading = false;
    });
  }
}

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
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : reels.isEmpty
              ? const Center(
                  child: Text("No posts found",
                      style: TextStyle(color: Colors.white)))
              : CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          return Column(
                            children: [
                              _buildInstagramPost(index),
                              const SizedBox(height: 8)
                            ],
                          );
                        },
                        childCount: reels.length,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildInstagramPost(int index) {
    final reel = reels[index];
    final caption = reel["caption"] ?? "";
    final reelId = reel["id"] ?? index;
    final isLiked = likedPosts[index] ?? false;
    final isSaved = savedPosts[index] ?? false;

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
          // Header
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
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
                        'Reel #$reelId',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.more_horiz, color: Colors.grey[400]),
                  onPressed: () {},
                  splashRadius: 24,
                ),
              ],
            ),
          ),

          // Post Image placeholder with caption overlay
          Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[900]!.withValues(alpha: 0.5),
                  Colors.purple[900]!.withValues(alpha: 0.5),
                ],
              ),
            ),
            child: Center(
              child: Text(
                caption,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[400],
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      likedPosts[index] = !isLiked;
                    });
                  },
                  splashRadius: 24,
                ),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline,
                      color: Colors.grey[400], size: 24),
                  onPressed: () {},
                  splashRadius: 24,
                ),
                IconButton(
                  icon: Icon(Icons.share_outlined,
                      color: Colors.grey[400], size: 24),
                  onPressed: () {},
                  splashRadius: 24,
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Colors.white : Colors.grey[400],
                    size: 24,
                  ),
                  onPressed: () {
                    setState(() {
                      savedPosts[index] = !isSaved;
                    });
                  },
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
                    text: caption,
                    style:
                        TextStyle(color: Colors.grey[300], fontSize: 14),
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