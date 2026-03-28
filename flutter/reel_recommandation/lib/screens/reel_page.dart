import 'package:flutter/material.dart';
import 'package:reel_recommandation/models/reel_item.dart';
import 'package:reel_recommandation/services/reel_feed_service.dart';
import 'package:video_player/video_player.dart';

class ReelPage extends StatefulWidget {
  const ReelPage({super.key});

  @override
  State<ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<ReelPage> {
  late final PageController _pageController;
  final ReelFeedService _feedService = ReelFeedService();
  static const int _userId = 1;

  int currentReelIndex = 0;
  bool _isLoading = true;

  List<ReelItem> reels = const [];

  final Map<int, VideoPlayerController> _controllers = {};
  final Map<int, bool> likedReels = {};
  final Map<int, bool> savedReels = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    try {
      final feed = await _feedService.fetchFeed(_userId);

      if (!mounted) return;

      setState(() {
        reels = feed;
        _isLoading = false;
      });

      if (reels.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initController(0);
          _preloadReel(1);
        });
      }
    } catch (_) {
      if (!mounted) return;

      // Fallback keeps reels usable if API is unreachable.
      setState(() {
        reels = const [
          ReelItem(
            reelId: 1,
            creator: 'user_1',
            caption: 'Amazing reel content #reels #flutter',
            assetPath: 'assets/videos/reel1.mp4',
            videoUrl: '',
            likeCount: 1200,
            commentCount: 324,
          ),
          ReelItem(
            reelId: 2,
            creator: 'user_2',
            caption: 'Street vibes and transitions #cinematic',
            assetPath: 'assets/videos/reel2.mp4',
            videoUrl: '',
            likeCount: 980,
            commentCount: 211,
          ),
          ReelItem(
            reelId: 3,
            creator: 'user_3',
            caption: 'Travel edit from last weekend #travel',
            assetPath: 'assets/videos/reel3.mp4',
            videoUrl: '',
            likeCount: 1450,
            commentCount: 407,
          ),
        ];
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _initController(0);
        _preloadReel(1);
      });
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

  // ---------------- VIDEO CONTROL ----------------

  Future<void> _initController(int index) async {
    if (_controllers.containsKey(index) || index < 0 || index >= reels.length) return;

    final reel = reels[index];
    final controller = reel.videoUrl.isNotEmpty
        ? VideoPlayerController.networkUrl(Uri.parse(reel.videoUrl))
        : VideoPlayerController.asset(reel.assetPath);

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
    if (index >= reels.length || index < 0) return;
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

    if (index >= 0 && index < reels.length) {
      _feedService.sendInteraction(
        userId: _userId,
        reelId: reels[index].reelId,
        event: 'view',
      ).catchError((_) {});
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (reels.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No reels available',
            style: TextStyle(color: Colors.white),
          ),
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
    final reel = reels[index];
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
                  label: '${reel.likeCount}',
                  color: isLiked ? Colors.red : Colors.white,
                  onTap: () {
                    setState(() {
                      likedReels[index] = !isLiked;
                    });

                    _feedService.sendInteraction(
                      userId: _userId,
                      reelId: reel.reelId,
                      event: 'like',
                    ).catchError((_) {});
                  },
                ),
                const SizedBox(height: 24),
                _iconButton(
                  icon: Icons.chat_bubble_outline,
                  label: '${reel.commentCount}',
                ),
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

                    _feedService.sendInteraction(
                      userId: _userId,
                      reelId: reel.reelId,
                      event: 'save',
                    ).catchError((_) {});
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
                  SizedBox(height: 1),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 90,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${reel.creator} • Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  reel.caption,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ],
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
