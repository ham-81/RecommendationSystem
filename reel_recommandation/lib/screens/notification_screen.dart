import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, dynamic>> notifications = [];
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
        notifications = List<Map<String, dynamic>>.from(data["data"]);
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
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Notifications',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : notifications.isEmpty
              ? const Center(
                  child: Text("No notifications",
                      style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final reel = notifications[index];
                    return _buildNotificationItem(reel, index);
                  },
                ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> reel, int index) {
    final icons = [
      Icons.favorite,
      Icons.comment,
      Icons.person_add,
      Icons.video_library,
    ];
    final colors = [Colors.red, Colors.blue, Colors.green, Colors.purple];
    final messages = [
      'liked your reel',
      'commented on your reel',
      'started following you',
      'posted a new reel',
    ];

    final type = index % 4;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        child: Text(
          'U${index + 1}',
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      title: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'user_${index + 1} ',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            TextSpan(
              text: messages[type],
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
            TextSpan(
              text: ' "${reel["caption"]}"',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
      subtitle: Text(
        '${index + 1}h ago',
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Icon(icons[type], color: colors[type], size: 20),
    );
  }
}