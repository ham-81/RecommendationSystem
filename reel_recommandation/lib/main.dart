import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ReelFeedPage(),
    );
  }
}

class ReelFeedPage extends StatefulWidget {
  const ReelFeedPage({super.key});

  @override
  State<ReelFeedPage> createState() => _ReelFeedPageState();
}

class _ReelFeedPageState extends State<ReelFeedPage> {
  List reels = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReels();
  }

 Future<void> fetchReels() async {
  try {
    final response = await http.get(
      Uri.parse("http://localhost:8000/api/reels/feed"),
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
      backgroundColor: Colors.black,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reels.isEmpty
              ? const Center(
                  child: Text("No reels found",
                      style: TextStyle(color: Colors.white)))
              : PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemCount: reels.length,
                  itemBuilder: (context, index) {
                    return ReelItem(reel: reels[index]);
                  },
                ),
    );
  }
}

class ReelItem extends StatefulWidget {
  final Map reel;
  const ReelItem({super.key, required this.reel});

  @override
  State<ReelItem> createState() => _ReelItemState();
}

class _ReelItemState extends State<ReelItem> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.reel["video_url"]),
    )..initialize().then((_) {
        setState(() => _isInitialized = true);
        _controller.setLooping(true);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          _isInitialized
              ? FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller.value.size.width,
                    height: _controller.value.size.height,
                    child: VideoPlayer(_controller),
                  ),
                )
              : const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 60,
            left: 16,
            child: Text(
              widget.reel["caption"] ?? "",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}