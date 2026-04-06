import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class ReelPage extends StatefulWidget {
  const ReelPage({super.key});

  @override
  State<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<ReelPage> {
  late final PageController _pageController;

  int currentReelIndex = 0;
  List<Map<String, dynamic>> reels = [];
  bool isLoading = true;

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> likedReels = {};
  final Map<int, bool> savedReels = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    fetchReels();
  }

  // ---------------- API ----------------

 Future<void> fetchReels() async {
  try {
    final response = await http.get(
      Uri.parse("http://localhost:8001/api/reels/feed?user_id=1"),
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
  // ---------------- VIDEO CONTROL ----------------

  Future<void> _initController(int index) async {
    if (_controllers.containsKey(index)) return;
    if (index >= reels.length) return;

    final videoUrl = reels[index]["video_url"];

    final controller = VideoPlayerController.networkUrl(
      Uri.parse(videoUrl),
    );

    controller.addListener(() {
      if (controller.value.hasError) {
        debugPrint('VIDEO ERROR: ${controller.value.errorDescription}');
      }
    });

    await controller.initialize();
    controller.setLooping(true);

    _controllers[index] = controller;

    if (mounted) setState(() {});
  }

  void _preloadReel(int index) {
    if (index >= reels.length) return;
    _initController(index);
  }

  void _pauseAll() {
    for (final controller in _controllers.values) {
      controller.pause();
    }
  }

  // ---------------- PAGE CHANGE ----------------

  Future<void> _recordInteraction(int reelId, String eventType) async {
    try {
      await http.post(
        Uri.parse("http://localhost:8001/api/interact"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_id": 1, // Using user 1 for demo
          "reel_id": reelId,
          "event_type": eventType,
        }),
      );
    } catch (e) {
      debugPrint("Failed to record interaction: $e");
    }
  }

  void _onPageChanged(int index) {
    _pauseAll();
    setState(() => currentReelIndex = index);
    _initController(index);
    _preloadReel(index + 1);
    
    final reelId = reels[index]["id"] ?? -1;
    if (reelId != -1) {
      _recordInteraction(reelId, "view");
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------

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
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          return _buildReelItem(index);
        },
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  void _showCommentsSheet(BuildContext context, int reelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "Comments",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const Divider(color: Colors.grey),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: 1, // Placeholder single comment
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.grey,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: const Text("user_test", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        subtitle: const Text("Great video! I have tested the comment section successfully.", style: TextStyle(color: Colors.white70)),
                      );
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[800],
                        hintText: "Add a comment...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildReelItem(int index) {
    final isLiked = likedReels[index] ?? false;
    final isSaved = savedReels[index] ?? false;
    final caption = reels[index]["caption"] ?? "";

    return GestureDetector(
      onTap: () async {
        await _initController(index);
        final c = _controllers[index];
        if (c == null || !c.value.isInitialized) return;
        setState(() {
          c.value.isPlaying ? c.pause() : c.play();
        });
      },
      onDoubleTap: () {
        setState(() {
          likedReels[index] = !isLiked;
        });
        if (!isLiked) {
           _recordInteraction(reels[index]["id"] ?? 0, "like");
        }
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildVideo(index),

          // Right buttons
          Positioned(
            right: 16,
            bottom: 100,
            child: Column(
              children: [
                _iconButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: _formatCount(reels[index]["like_count"] ?? 0),
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() {
                      likedReels[index] = !isLiked;
                    });
                     if (!isLiked) {
                       _recordInteraction(reels[index]["id"] ?? 0, "like");
                     }
                  },
                ),
                const SizedBox(height: 24),
                _iconButton(
                  icon: Icons.chat_bubble_outline, 
                  label: _formatCount(reels[index]["comment_count"] ?? 0),
                  onTap: () {
                    _showCommentsSheet(context, reels[index]["id"] ?? 0);
                  },
                ),
                const SizedBox(height: 24),
                _iconButton(icon: Icons.share_outlined, label: 'Share', onTap: () {}),
                const SizedBox(height: 24),
                _iconButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Save',
                  onTap: () {
                    setState(() {
                      savedReels[index] = !isSaved;
                    });
                    if (!isSaved) {
                        _recordInteraction(reels[index]["id"] ?? 0, "save");
                    }
                  },
                ),
              ],
            ),
          ),

          // Bottom info
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: .5),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'user_1 • Follow',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    caption,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo(int index) {
    final controller = _controllers[index];

    if (controller == null || !controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: controller.value.size.width,
        height: controller.value.size.height,
        child: VideoPlayer(controller),
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String label,
    Color color = Colors.white,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
    );
  }
}