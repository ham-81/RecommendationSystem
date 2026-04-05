import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ReelPage extends StatefulWidget {
  const ReelPage({super.key});

  @override
  State<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<ReelPage> {
  late final PageController _pageController;

  int currentReelIndex = 0;

  final List<int> reels = List.generate(20, (index) => index);

  final List<String> videoPaths = [
    'assets/videos/reel1.mp4',
    'assets/videos/reel2.mp4',
    'assets/videos/reel3.mp4',
    'assets/videos/reel4.mp4',
    'assets/videos/reel5.mp4',
    'assets/videos/reel6.mp4',
  ];

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> likedReels = {};
  final Map<int, bool> savedReels = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Load first reel ONLY (no autoplay)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initController(0);
      _preloadReel(1);
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  // ---------------- VIDEO CONTROL ----------------

  Future<void> _initController(int index) async {
    if (_controllers.containsKey(index)) return;

    final controller = VideoPlayerController.asset(
      videoPaths[index % videoPaths.length],
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

    setState(() {
      currentReelIndex = index;
    });

    _initController(index);      // load only
    _preloadReel(index + 1);     // preload next
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
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
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'user_1 • Follow',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Amazing reel content 🎬 #reels #flutter',
                    style: TextStyle(color: Colors.white, fontSize: 13),
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
