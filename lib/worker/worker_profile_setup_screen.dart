import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import 'worker_dashboard_screen.dart';

class WorkerProfileSetupScreen extends StatefulWidget {
  const WorkerProfileSetupScreen({super.key});

  @override
  State<WorkerProfileSetupScreen> createState() =>
      _WorkerProfileSetupScreenState();
}

class _WorkerProfileSetupScreenState extends State<WorkerProfileSetupScreen>
    with AutomaticKeepAliveClientMixin<WorkerProfileSetupScreen> {

  @override
  bool get wantKeepAlive => true;

  final Color inDriveGreen = const Color(0xFFC6FF00);
  final Color primaryBlack = const Color(0xFF121212);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _skillsController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // PROFILE IMAGE
  File? _selectedProfilePic;
  Uint8List? _webProfilePicBytes;

  // CNIC FRONT
  File? _selectedCnicFront;
  Uint8List? _webCnicFrontBytes;

  // CNIC BACK
  File? _selectedCnicBack;
  Uint8List? _webCnicBackBytes;

  String? _frontFileName;
  String? _backFileName;

  bool _isLoading = false;

  // ================= CLOUDINARY UPLOAD LOGIC =================
  Future<String?> _uploadToCloudinary({
    required Uint8List? webBytes,
    required File? mobileFile,
    required String fileNamePrefix,
  }) async {
    final String cloudName = "dcxfysw0o";
    final String uploadPreset = "skilllink_preset";
    final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    try {
      var request = http.MultipartRequest("POST", uri);
      request.fields['upload_preset'] = uploadPreset;
      request.fields['folder'] = 'skilllink.docs';

      if (kIsWeb) {
        if (webBytes == null) return null;
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            webBytes,
            filename: '$fileNamePrefix.jpg',
          ),
        );
      } else {
        if (mobileFile == null) return null;
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            mobileFile.path,
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        var responseData = jsonDecode(response.body);
        return responseData['secure_url'] as String;
      } else {
        print("Cloudinary Error Log: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Cloudinary Connection Network Exception: $e");
      return null;
    }
  }

  // ================= UNIVERSAL IMAGE VALIDATION HELPER =================
  bool _isSupportedImage(FilePickerResult result) {
    String checkPath = kIsWeb
        ? result.files.single.name.toLowerCase()
        : result.files.single.path!.toLowerCase();

    return checkPath.endsWith('.jpg') ||
        checkPath.endsWith('.jpeg') ||
        checkPath.endsWith('.png') ||
        checkPath.endsWith('.webp') ||
        checkPath.endsWith('.heic');
  }

  // ================= PROFILE PICTURE PICKER =================
  Future<void> _pickProfilePicture() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        if (!_isSupportedImage(result)) {
          _showSnackBar("Please select a valid image file (JPG, PNG, WEBP, HEIC)", Colors.orange);
          return;
        }

        setState(() {
          if (kIsWeb) {
            _webProfilePicBytes = result.files.single.bytes;
          } else {
            _selectedProfilePic = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      _showSnackBar("Failed to pick profile picture", Colors.red);
    }
  }

  // ================= CNIC FRONT PICKER =================
  Future<void> _pickCnicFront() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        if (!_isSupportedImage(result)) {
          _showSnackBar("Please select a valid image file (JPG, PNG, WEBP, HEIC)", Colors.orange);
          return;
        }

        setState(() {
          _frontFileName = result.files.single.name;

          if (kIsWeb) {
            _webCnicFrontBytes = result.files.single.bytes;
          } else {
            _selectedCnicFront = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      _showSnackBar("Failed to pick CNIC front", Colors.red);
    }
  }

  // ================= CNIC BACK PICKER =================
  Future<void> _pickCnicBack() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null) {
        if (!_isSupportedImage(result)) {
          _showSnackBar("Please select a valid image file (JPG, PNG, WEBP, HEIC)", Colors.orange);
          return;
        }

        setState(() {
          _backFileName = result.files.single.name;

          if (kIsWeb) {
            _webCnicBackBytes = result.files.single.bytes;
          } else {
            _selectedCnicBack = File(result.files.single.path!);
          }
        });
      }
    } catch (e) {
      _showSnackBar("Failed to pick CNIC back", Colors.red);
    }
  }

  // ================= SUBMIT APPLICATION LOGIC =================
  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    bool hasProfile = kIsWeb ? _webProfilePicBytes != null : _selectedProfilePic != null;
    bool hasFront = kIsWeb ? _webCnicFrontBytes != null : _selectedCnicFront != null;
    bool hasBack = kIsWeb ? _webCnicBackBytes != null : _selectedCnicBack != null;

    if (!hasProfile || !hasFront || !hasBack) {
      _showSnackBar("Please upload all required photos and documents.", Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar("Authentication error. Please log in again.", Colors.red);
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 7),
        );
      } catch (geoError) {
        position = Position(
            latitude: 30.6777, longitude: 73.1068,
            timestamp: DateTime.now(), accuracy: 0, altitude: 0,
            heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0
        );
      }

      String? profileUrl = await _uploadToCloudinary(
        webBytes: _webProfilePicBytes,
        mobileFile: _selectedProfilePic,
        fileNamePrefix: "${user.uid}_profile",
      );

      String? cnicFrontUrl = await _uploadToCloudinary(
        webBytes: _webCnicFrontBytes,
        mobileFile: _selectedCnicFront,
        fileNamePrefix: "${user.uid}_front",
      );

      String? cnicBackUrl = await _uploadToCloudinary(
        webBytes: _webCnicBackBytes,
        mobileFile: _selectedCnicBack,
        fileNamePrefix: "${user.uid}_back",
      );

      if (profileUrl == null || cnicFrontUrl == null || cnicBackUrl == null) {
        throw Exception("Server media upload pipeline failed. Check your connection.");
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .update({
        "skills": _skillsController.text.trim(),
        "experience": _experienceController.text.trim(),
        "address": _addressController.text.trim(),
        "profileImage": profileUrl,
        "cnicFrontUrl": cnicFrontUrl,
        "cnicBackUrl": cnicBackUrl,
        "isVerified": false,
        "isBanned": false,
        "profileSetupCompleted": true,
        "role": "worker",
        "location": GeoPoint(position.latitude, position.longitude),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile submitted successfully for review!"),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const WorkerDashboardScreen(),
        ),
      );

    } catch (e) {
      _showSnackBar("Submission Error: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    // Dynamic ImageProvider setup to bypass conditional expression cast crashes
    ImageProvider? profileImageProvider;
    if (kIsWeb) {
      if (_webProfilePicBytes != null) {
        profileImageProvider = MemoryImage(_webProfilePicBytes!);
      }
    } else {
      if (_selectedProfilePic != null) {
        profileImageProvider = FileImage(_selectedProfilePic!);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Complete Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: primaryBlack,
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickProfilePicture,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundColor: inDriveGreen,
                    backgroundImage: profileImageProvider, // Safely handles null values perfectly!
                    child: (_selectedProfilePic == null && _webProfilePicBytes == null)
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.black)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _skillsController,
                decoration: InputDecoration(
                  labelText: "Skills (e.g., Electrician, Plumber)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? "Enter skills" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _experienceController,
                decoration: InputDecoration(
                  labelText: "Experience (e.g., 3 Years)",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? "Enter experience" : null,
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: "Physical Address",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => (value == null || value.isEmpty) ? "Enter address" : null,
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _pickCnicFront,
                icon: const Icon(Icons.credit_card),
                label: Text(_frontFileName ?? "Upload CNIC Front Side"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: inDriveGreen,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _pickCnicBack,
                icon: const Icon(Icons.credit_card),
                label: Text(_backFileName ?? "Upload CNIC Back Side"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: inDriveGreen,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: inDriveGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                    "SUBMIT PROFILE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}