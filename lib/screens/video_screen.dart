import 'package:flutter/material.dart';

class ReelsPage extends StatefulWidget {
  const ReelsPage({super.key});

  @override
  State<ReelsPage> createState() => _ReelsPageState();
}

class _ReelsPageState extends State<ReelsPage> {
  late PageController _pageController;
  List<int> reels = [];
  int currentReelIndex = 0;
  
  // Track liked/saved status for each reel
  Map<int, bool> likedReels = {};
  Map<int, bool> savedReels = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(_onPageChanged);
    _loadReels();
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

  void _loadReels() {
    List<int> newReels = [];
    for (int i = 0; i < 20; i++) {
      newReels.add(i);
      likedReels[i] = false;
      savedReels[i] = false;
    }
    setState(() {
      reels = newReels;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'Reel ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
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
              // Like Button
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

              // Comment Button
              _buildActionButton(Icons.chat_bubble_outline, '324', Colors.white),
              const SizedBox(height: 24),

              // Share Button
              _buildActionButton(Icons.share_outlined, 'Share', Colors.white),
              const SizedBox(height: 24),

              // Save Button
              GestureDetector(
                onTap: () {
                  setState(() {
                    savedReels[index] = !isSaved;
                  });
                },
                child: _buildActionButton(
                  isSaved ? Icons.bookmark : Icons.bookmark_outline,
                  'Save',
                  isSaved ? Colors.white : Colors.white,
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
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black,
                ],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // User Info
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

                // Caption
                Text(
                  'Amazing reel content! 🎬 #reels #trending',
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