import 'package:flutter/material.dart';
import 'package:reel_recommandation/routes/routes.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Widget buildTile({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 16)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        color: Colors.grey,
        size: 16,
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 2,
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: ListView(
        children: [
          const SizedBox(height: 10),

          /// ACCOUNT
          _sectionTitle("Account"),
          buildTile(icon: Icons.person, title: "Edit Profile", onTap: () {}),
          buildTile(
            icon: Icons.favorite,
            title: "Liked Photos",
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.likedReelsPage);
            },
          ),
          buildTile(icon: Icons.bookmark, title: "Saved Posts", onTap: () {
            Navigator.pushNamed(context, AppRoutes.savedPostsPage);
          }),

          const SizedBox(height: 20),

          /// APP
          _sectionTitle("App"),
          buildTile(
            icon: Icons.notifications,
            title: "Notifications",
            onTap: () {},
          ),
          buildTile(icon: Icons.lock, title: "Privacy", onTap: () {}),

          const SizedBox(height: 20),

          /// LOGOUT
          buildTile(
            icon: Icons.logout,
            title: "Logout",
            color: Colors.red,
            onTap: () {
              // logout logic here
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.grey,
          fontSize: 12,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
