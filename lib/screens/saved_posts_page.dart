import 'package:flutter/material.dart';

class SavedPostsPage extends StatelessWidget {
  const SavedPostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔥 Dummy data for now
    final List<String> savedPosts = List.generate(
      12,
      (index) => "https://picsum.photos/200/300?random=${index + 50}",
    );

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Saved Posts"),
      ),

      body: savedPosts.isEmpty
          ? const Center(
              child: Text(
                "No saved posts yet",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(2),
              itemCount: savedPosts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    // 🔥 Later: open post/reel
                  },
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          savedPosts[index],
                          fit: BoxFit.cover,
                        ),
                      ),

                      /// Bookmark icon overlay
                      const Positioned(
                        right: 5,
                        top: 5,
                        child: Icon(
                          Icons.bookmark,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}