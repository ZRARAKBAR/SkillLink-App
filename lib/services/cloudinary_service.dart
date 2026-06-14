import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName = "dcxfysw0o";
  static const String uploadPreset = "skilllink_preset";

  // IMAGE (mobile)
  static Future<String?> uploadImage(File file) async {
    return _uploadFile(file.path, isBytes: false, isImage: true);
  }

  // DOCUMENT (mobile)
  static Future<String?> uploadDocument(File file) async {
    return _uploadFile(file.path, isBytes: false, isImage: false);
  }

  // IMAGE (web)
  static Future<String?> uploadImageFromBytes(Uint8List bytes, {required String fileName}) async {
    return _uploadBytes(bytes, fileName, isImage: true);
  }

  // DOCUMENT (web)
  static Future<String?> uploadDocumentFromBytes(Uint8List bytes, {required String fileName}) async {
    return _uploadBytes(bytes, fileName, isImage: false);
  }

  // MOBILE UPLOAD
  static Future<String?> _uploadFile(String path, {required bool isImage, required bool isBytes}) async {
    final endpoint = isImage ? "image" : "raw";

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/$endpoint/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields["upload_preset"] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath("file", path));

    final response = await request.send();
    final resStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(resStr);
      return data["secure_url"];
    }

    return null;
  }

  // WEB UPLOAD (BYTES)
  static Future<String?> _uploadBytes(Uint8List bytes, String fileName, {required bool isImage}) async {
    final endpoint = isImage ? "image" : "raw";

    final url = Uri.parse(
      "https://api.cloudinary.com/v1_1/$cloudName/$endpoint/upload",
    );

    final request = http.MultipartRequest("POST", url);

    request.fields["upload_preset"] = uploadPreset;
    request.fields["file"] = base64Encode(bytes);

    final response = await request.send();
    final resStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(resStr);
      return data["secure_url"];
    }

    return null;
  }
}