import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileCenterAvatar extends StatefulWidget {
  const ProfileCenterAvatar({super.key});

  @override
  State<ProfileCenterAvatar> createState() => _ProfileCenterAvatarState();
}

class _ProfileCenterAvatarState extends State<ProfileCenterAvatar> {
  File? _image;
  final ImagePicker _picker = ImagePicker();

  /// 📷 Pick from Camera
  Future<void> _pickFromCamera() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// 🖼️ Pick from Gallery
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  /// 🔽 Bottom Sheet
  void _showPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              /// Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.white),
                title: const Text(
                  "Take Photo",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera();
                },
              ),

              ListTile(
                leading: const Icon(Icons.photo, color: Colors.white),
                title: const Text(
                  "Choose from Gallery",
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery();
                },
              ),

              const Divider(color: Colors.grey),

              ListTile(
                title: const Center(
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _showPicker,
      child: Stack(
        alignment: Alignment.center,
        children: [
          /// Glow Background
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [Colors.purple, Colors.black],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.6),
                  blurRadius: 25,
                  spreadRadius: 5,
                )
              ],
            ),
          ),

          /// Profile Image / Placeholder
          ClipOval(
            child: _image != null
                ? Image.file(
                    _image!,
                    width: 130,
                    height: 130,
                    fit: BoxFit.cover,
                  )
                : CircleAvatar(
                    radius: 65,
                    backgroundColor: Colors.grey[900],
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
          ),

          /// Edit Icon
          Positioned(
            bottom: 5,
            right: 5,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: const Icon(Icons.edit, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}