import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class StorageService with ChangeNotifier {
  final firebaseStorage = FirebaseStorage.instance;
  final String email;

  StorageService({required this.email});

  String get sanitizedEmail =>
      email.replaceAll(RegExp(r'[^\w\-]'), '_'); 
  List<String> _imageUrls = [];
  bool _isLoading = false;
  bool _isUpload = false;

  List<String> get imageUrls => _imageUrls;
  bool get isLoading => _isLoading;
  bool get isUpload => _isUpload;

  Future<void> fetchImages() async {
    _isLoading = true;

    final ListResult result =
        await firebaseStorage.ref('$sanitizedEmail/').listAll();
    final urls = await Future.wait(
      result.items.map((ref) => ref.getDownloadURL()),
    );

    _imageUrls = urls;
    _isLoading = false;

    notifyListeners();
  }

  Future<void> deleteImages(String imageUrl) async {
    try {
      _imageUrls.remove(imageUrl);

      final String path = extractPathFromUrl(imageUrl);
      await firebaseStorage.ref(path).delete();
    } catch (e) {
      print("error $e");
    }

    notifyListeners();
  }

  String extractPathFromUrl(String url) {
    Uri uri = Uri.parse(url);
    String fullPath = uri.path.split("/o/").last;
    String cleanPath = fullPath.split("?").first;
    return Uri.decodeComponent(cleanPath);
  }

  Future<void> ensureFolderExists() async {
    try {
      final ListResult result =
          await firebaseStorage.ref('$sanitizedEmail/').listAll();

      if (result.items.isEmpty) {
        final dummyData = Uint8List(0);
        await firebaseStorage.ref('$sanitizedEmail/.keep').putData(dummyData);
      }
    } catch (e) {
      print("Error ensuring folder exists: $e");
    }
  }

  Future<String?> uploadImage(File file) async {
    try {
      await ensureFolderExists();

      String filePath =
          '$sanitizedEmail/${DateTime.now().millisecondsSinceEpoch}.png';

      UploadTask uploadTask =
          firebaseStorage.ref().child(filePath).putFile(file);
      TaskSnapshot snapshot = await uploadTask;

      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Upload failed: $e");
      return null;
    }
  }
}
