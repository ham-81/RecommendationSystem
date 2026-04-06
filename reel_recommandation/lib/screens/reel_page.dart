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

  void _onPageChanged(int index) {
    _pauseAll();
    setState(() => currentReelIndex = index);
    _initController(index);
    _preloadReel(index + 1);
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
                  label: '1.2K',
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() {
                      likedReels[index] = !isLiked;
                    });
                  },
                ),
                const SizedBox(height: 24),
                _iconButton(icon: Icons.chat_bubble_outline, label: '324'),
                const SizedBox(height: 24),
                _iconButton(icon: Icons.share_outlined, label: 'Share'),
                const SizedBox(height: 24),
                _iconButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border,
                  label: 'Save',
                  onTap: () {
                    setState(() {
                      savedReels[index] = !isSaved;
                    });
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
      fit: BoxFit.cover,
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