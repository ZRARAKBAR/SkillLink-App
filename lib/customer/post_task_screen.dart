import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cloudinary_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';




class PostTaskScreen extends StatefulWidget {
  final String? initialCategory;
  const PostTaskScreen({super.key, this.initialCategory});

  @override
  State<PostTaskScreen> createState() => _PostTaskScreenState();
}

class _PostTaskScreenState extends State<PostTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();

  final Color primaryBlack = const Color(0xFF121212);
  final Color inDriveGreen = const Color(0xFFC6FF00);

  bool _isPosting = false;
  bool _uploadingImage = false;

  File? _selectedImage;
  Uint8List? _imageBytes;

  final ImagePicker _picker = ImagePicker();

  String? _imageUrl;

  // ---------------- IMAGE PICK ----------------
  Future<void> _pickImage() async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;

        if (!kIsWeb) {
          _selectedImage = File(file.path);
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image pick error: $e")),
      );
    }
  }
  // ---------------- IMAGE UPLOAD ----------------
  Future<void> _uploadImage() async {
    setState(() => _uploadingImage = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Image uploaded successfully"),
        backgroundColor: Colors.green,
      ),
    );

    try {
      String? url;

      if (kIsWeb) {
        if (_imageBytes == null) return;

        url = await CloudinaryService.uploadImageFromBytes(
          _imageBytes!,
          fileName: "task_image.jpg",
        );
      } else {
        if (_selectedImage == null) return;

        url = await CloudinaryService.uploadImage(
          _selectedImage!,
        );
      }

      if (!mounted) return;

      setState(() {
        _imageUrl = url;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _uploadingImage = false);
      }
    }
  }
  // ---------------- POST TASK ----------------
  Future<void> _handlePostTask() async {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final budgetText = _budgetController.text.trim();

    if (title.isEmpty || budgetText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and Budget are required")),
      );
      return;
    }

    final double? budget = double.tryParse(budgetText);

    if (budget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter a valid budget")),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      Map<String, dynamic> taskData = {
        "customerId": user.uid,
        "title": title,
        "category": widget.initialCategory ?? "General",
        "description": desc,
        "budget": budget,
        "status": "pending",
        "imageUrl": _imageUrl ?? "",
        "createdAt": FieldValue.serverTimestamp(),
        "assignedWorkerId": null,
        "customerRating": null,
        "workerRating": null,
        "priority": "normal",
        "allowAiMatching": true,
      };

      try {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        taskData["location"] = GeoPoint(pos.latitude, pos.longitude);
      } catch (_) {
        taskData["location"] = null;
      }

      await FirebaseFirestore.instance.collection("tasks").add(taskData);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: inDriveGreen,
          content: const Text(
            "Task Posted Successfully!",
            style: TextStyle(color: Colors.black),
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  // ---------------- UI ----------------
  @override
  @override
  Widget build(BuildContext context) {
    final Color neonGreen = const Color(0xFFC6FF00);
    final Color dark = const Color(0xFF121212);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        title: const Text("SkillLink Task"),
        backgroundColor: dark,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // 🌟 HERO HEADER (ANIMATED STYLE LOOK)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    dark,
                    Colors.black87,
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: neonGreen.withOpacity(0.2),
                    blurRadius: 20,
                    spreadRadius: 1,
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Post a SkillLink Task ⚡",
                    style: TextStyle(
                      color: neonGreen,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Get instant help from skilled workers near you",
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // TITLE
            _buildField(
              controller: _titleController,
              label: "What do you need?",
              icon: Icons.title,
            ),

            const SizedBox(height: 12),

            // BUDGET
            _buildField(
              controller: _budgetController,
              label: "Your Budget (Rs.)",
              icon: Icons.attach_money,
              number: true,
            ),

            const SizedBox(height: 12),

            // DESCRIPTION
            _buildField(
              controller: _descController,
              label: "Describe your task",
              icon: Icons.description,
              maxLines: 4,
            ),

            const SizedBox(height: 20),

            // IMAGE CARD (SKILLINK STYLE)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Column(
                children: [

                  // IMAGE
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: _imageBytes != null
                        ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        height: 170,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: [
                            Colors.grey.shade200,
                            Colors.grey.shade100,
                          ],
                        ),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.cloud_upload,
                              size: 40, color: Colors.grey),
                          SizedBox(height: 5),
                          Text("Upload Task Image"),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // BUTTONS
                  Row(
                    children: [

                      Expanded(
                        child: _miniButton(
                          text: "Pick",
                          icon: Icons.photo,
                          color: Colors.blueGrey,
                          onTap: _pickImage,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: _miniButton(
                          text: _uploadingImage ? "Uploading..." : "Upload",
                          icon: Icons.cloud_upload,
                          color: neonGreen,
                          onTap: _uploadingImage ? null : _uploadImage,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // POST BUTTON (SKILLINK STYLE)
            GestureDetector(
              onTap: _isPosting ? null : _handlePostTask,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: double.infinity,
                height: 55,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isPosting
                        ? [Colors.grey, Colors.grey]
                        : [dark, neonGreen],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: neonGreen.withOpacity(0.25),
                      blurRadius: 12,
                    )
                  ],
                ),
                child: Center(
                  child: _isPosting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "POST TASK ⚡",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }}
Widget _buildField({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  bool number = false,
  int maxLines = 1,
}) {
  return TextField(
    controller: controller,
    keyboardType: number ? TextInputType.number : TextInputType.text,
    maxLines: maxLines,
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}
Widget _miniButton({
  required String text,
  required IconData icon,
  required Color color,
  required VoidCallback? onTap,
}) {
  return ElevatedButton.icon(
    onPressed: onTap,
    icon: Icon(icon),
    label: Text(text),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
    ),
  );
}