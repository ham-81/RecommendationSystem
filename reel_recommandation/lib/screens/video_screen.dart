import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late PageController _pageController;
  List<Map<String, dynamic>> reels = [];
  int currentReelIndex = 0;
  bool isLoading = true;

  Map<int, bool> likedReels = {};
  Map<int, bool> savedReels = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    fetchReels();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged() {
    setState(() {
      currentReelIndex = _pageController.page?.round() ?? 0;
    });
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
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text("No reels found",
              style: TextStyle(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: reels.length,
        itemBuilder: (context, index) {
          return _buildReelItem(index);
        },
      ),
    );
  }

  Widget _buildReelItem(int index) {
    final reel = reels[index];
    final caption = reel["caption"] ?? "";
    final reelId = reel["id"] ?? index + 1;
    bool isLiked = likedReels[index] ?? false;
    bool isSaved = savedReels[index] ?? false;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video Background
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[900]!,
                Colors.purple[900]!,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ID: $reelId',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Right Side Action Buttons
        Positioned(
          right: 16,
          bottom: 100,
          child: Column(
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    likedReels[index] = !isLiked;
                  });
                },
                child: _buildActionButton(
                  isLiked ? Icons.favorite : Icons.favorite_outline,
                  '1.2K',
                  isLiked ? Colors.red : Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                  Icons.chat_bubble_outline, '324', Colors.white),
              const SizedBox(height: 24),
              _buildActionButton(
                  Icons.share_outlined, 'Share', Colors.white),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  setState(() {
                    savedReels[index] = !isSaved;
                  });
                },
                child: _buildActionButton(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  'Save',
                  Colors.white,
                ),
              ),
            ],
          ),
        ),

        // Bottom User Info
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[700],
                      child: Text(
                        'U${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'user_${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      'Follow',
                      style: TextStyle(
                        color: Colors.blue[400],
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}