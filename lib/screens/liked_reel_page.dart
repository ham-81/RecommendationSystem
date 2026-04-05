import 'package:flutter/material.dart';

class LikedReelsPage extends StatelessWidget {
  const LikedReelsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 Temporary dummy data
    final List<String> likedReels = List.generate(
      12,
      (index) => "https://picsum.photos/200/300?random=$index",
    );

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Liked Reels"),
      ),

      body: GridView.builder(
        padding: const EdgeInsets.all(2),
        itemCount: likedReels.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // Open reel (we'll improve later)
            },
            child: Image.network(
              likedReels[index],
              fit: BoxFit.cover,
            ),
          );
        },
      ),
    );
  }
}