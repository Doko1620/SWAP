

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui'; 
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img; 
import 'package:provider/provider.dart';
import 'package:swap/components/storage_service.dart'; 
import 'package:swap/components/toast.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:http/http.dart' as http; 
import 'package:http_parser/http_parser.dart'; 
import 'camera_page.dart'; 

class UploadImagePage extends StatefulWidget {
  final String email;
  const UploadImagePage({super.key, required this.email});

  @override
  State<UploadImagePage> createState() => _UploadImagePageState();
}

class _UploadImagePageState extends State<UploadImagePage> {
  final Color primaryColor = const Color(0xFF4A148C); 
  late Color labelColor; 

  File? _selectedImage;
  bool _isLoading = false;

  final String _apiUrl = "http://172.20.10.3:8000/predict";



  String? _predictedLabel; 
  double? _predictionConfidence;
  bool _userManuallyChangedType = false; 

  final TextEditingController _nameController = TextEditingController();
  String? _type;
  String? _subcategory;
  String? _material;
  String? _color;
  String? _shade;
  String? _formality;

  final int inputSize = 224; 
  final List<String> types = ["Shirts/Tops", "Pants", "Shoes", "Headwear"];
  final Map<String, List<String>> subcategories = {
    "Shirts/Tops": ["T-Shirt", "Shirt", "Hoodie", "Sweater", "Jacket"],
    "Pants": ["Jeans", "Chinos", "Shorts", "Trousers"],
    "Shoes": ["Sneakers", "Formal Shoes", "Boots", "Sandals"],
    "Headwear": ["Cap", "Beanie", "Hat", "Hijab"],
  };
  final List<String> materials = [
    "Cotton", "Polyester", "Wool", "Leather", "Denim/Jeans", "Linen", "Silk", "Synthetic"
  ];
  final List<String> colors = [
    "Black", "White", "Grey", "Navy", "Blue", "Red", "Green", "Yellow",
    "Brown", "Beige", "Purple", "Pink", "Orange", "Olive", "Teal", "Maroon"
  ];
  final List<String> shades = ["Light", "Dark"];
  final List<String> formalities = ["Formal", "Informal", "Both"];

  static const int sustainableScore = 25;
  static const int nonSustainableScore = 10;
  static const Set<String> sustainableMaterials = {
    "Cotton",
    "Wool",
    "Linen",
    "Silk",
  };


  @override
  void initState() {
    super.initState();
    labelColor = HSLColor.fromColor(primaryColor).withLightness(0.25).toColor();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ToastHelper.init(context);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> fetchImages() async {
    try {
        await Provider.of<StorageService>(context, listen: false).fetchImages();
    } catch(e) {
        debugPrint("Error fetching images: $e");
    }
  }

  
  Future<File> _cropToSquare(File imageFile) async {
      final bytes = await imageFile.readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return imageFile;
      int size = decoded.width < decoded.height ? decoded.width : decoded.height;
      final cropped = img.copyCrop(decoded, x: (decoded.width - size) ~/ 2, y: (decoded.height - size) ~/ 2, width: size, height: size);
      final croppedBytes = Uint8List.fromList(img.encodeJpg(cropped, quality: 90));
      final tempDir = Directory.systemTemp;
      final tempPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}_square.jpg';
      final newFile = await File(tempPath).writeAsBytes(croppedBytes);
      return newFile;
  }

  Future<void> _pickFromGallery() async {
      if (_isLoading) return;
      if (mounted) setState(() { _isLoading = true; _userManuallyChangedType = false; }); 
      final picker = ImagePicker();
      try {
        final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
        if (pickedFile != null) {
          File imageFile = File(pickedFile.path); 
          File squareFile = await _cropToSquare(imageFile); 
          if (mounted) { setState(() { _selectedImage = squareFile; _predictedLabel = null; _predictionConfidence = null; }); }
          
          await _runModelOnline(squareFile);
          // ---

        } else { if (mounted) setState(() => _isLoading = false); }
      } catch (e) { if (mounted) { ToastHelper.showToast(message: "Error selecting image: $e", backgroundColor: Colors.red); setState(() => _isLoading = false); } }
  }

  Future<void> _goToCameraPage() async {
      if (_isLoading) return;
      if (mounted) setState(() { _isLoading = true; _userManuallyChangedType = false; }); 
      try {
        final imagePath = await Navigator.push<String?>( context, MaterialPageRoute(builder: (context) => const CameraPage()), );
        if (imagePath != null && imagePath.isNotEmpty) {
          File imageFile = File(imagePath); 
          File squareFile = await _cropToSquare(imageFile); 
          if (mounted) { setState(() { _selectedImage = squareFile; _predictedLabel = null; _predictionConfidence = null; }); }
          
          await _runModelOnline(squareFile);
          // ---

        } else { if (mounted) setState(() => _isLoading = false); }
      } catch (e) { if (mounted) { ToastHelper.showToast(message: "Error using camera: $e", backgroundColor: Colors.red); setState(() => _isLoading = false); } }
  }


  Future<void> _runModelOnline(File imageFile) async {
    if (!_isLoading && mounted) setState(() => _isLoading = true);
    
    if (_apiUrl.contains("YOUR_COMPUTER_IP")) {
       if (mounted) {
         ToastHelper.showToast(
            message: "Error: API URL not configured. Please set your IP.",
            backgroundColor: Colors.red,
            icon: Icons.error);
         setState(() => _isLoading = false);
       }
       return;
    }

    try {
      var uri = Uri.parse(_apiUrl);
      
      var request = http.MultipartRequest("POST", uri);

      request.files.add(
        await http.MultipartFile.fromPath(
          'file', 
          imageFile.path,
          contentType: MediaType('image', 'jpeg'), 
        ),
      );

      debugPrint("🔹 Sending image to API...");
      final stopwatch = Stopwatch()..start();

      var response = await request.send();

      stopwatch.stop();
      debugPrint("✅ API Response received in ${stopwatch.elapsedMilliseconds}ms");

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        
        var json = jsonDecode(responseBody) as Map<String, dynamic>;
        
        debugPrint("API Response JSON: $json");
        
        final predictedLabel = json['label'] as String;
        final maxConfidence = (json['confidence'] as num).toDouble();

        if (mounted) {
          setState(() {
            _predictedLabel = predictedLabel;
            _predictionConfidence = maxConfidence;
            _type = _mapLabelToType(predictedLabel);
            _userManuallyChangedType = false;
          });
          ToastHelper.showToast(
            message:
                "Detected: $predictedLabel (${(maxConfidence * 100).toStringAsFixed(1)}%)",
            backgroundColor: primaryColor.withOpacity(0.8),
            icon: Icons.check_circle,
          );
        }

      } else {
        var errorBody = await response.stream.bytesToString();
        debugPrint("❌ API Error: ${response.statusCode}");
        debugPrint("Error Body: $errorBody");
        throw Exception("Server Error: ${response.statusCode}. $errorBody");
      }
    } catch (e, st) {
      debugPrint("❌ Prediction error: $e");
      debugPrint("$st");
      if (mounted) {
        ToastHelper.showToast(
          message: "Prediction failed. Check network or server logs.",
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  

  String _mapLabelToType(String label) {
     final l = label.toLowerCase();
     if (l.contains("top") || l.contains("shirt") || l.contains("hoodie") || l.contains("sweater") || l.contains("jacket")) return "Shirts/Tops";
     if (l.contains("pant") || l.contains("jeans") || l.contains("chinos") || l.contains("shorts") || l.contains("trousers")) return "Pants";
     if (l.contains("shoe") || l.contains("sneaker") || l.contains("boot") || l.contains("sandal")) return "Shoes";
     if (l.contains("head") || l.contains("cap") || l.contains("beanie") || l.contains("hat") || l.contains("hijab")) return "Headwear";
     if (types.contains(label)) return label;
     return "Shirts/Tops";
  }

  bool get _isFormComplete =>
      _selectedImage != null &&
      _nameController.text.trim().isNotEmpty &&
      _type != null &&
      _subcategory != null &&
      _material != null &&
      _color != null &&
      _shade != null &&
      _formality != null;

  int _calculateItemScore(String material) {
    if (sustainableMaterials.contains(material)) {
      return sustainableScore; 
    }
    return nonSustainableScore; 
  }

  Future<void> _updateUserEcoScore(String userDocId) async {
    try {
      final clothesSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userDocId)
          .collection("clothes")
          .get();

      if (clothesSnapshot.docs.isEmpty) {
        await FirebaseFirestore.instance.collection("users").doc(userDocId).update({'score': 0});
        return;
      }

      int totalScore = 0;
      int maxPossibleScore = 0;

      for (var doc in clothesSnapshot.docs) {
        final data = doc.data();
        int itemScore = (data['itemScore'] as num?)?.toInt() ?? 0; 
        totalScore += itemScore;
        maxPossibleScore += sustainableScore; 
      }

      double percentage = 0.0;
      if (maxPossibleScore > 0) {
        percentage = (totalScore / maxPossibleScore) * 100;
      }

      int finalScore = percentage.round(); 

      await FirebaseFirestore.instance.collection("users").doc(userDocId).update({
        'score': finalScore,
      });
      
      debugPrint("✅ User Eco Score updated to: $finalScore");

    } catch (e) {
      debugPrint("❌ Error updating user eco score: $e");
    }
  }


  Future<void> _saveClothDetails() async {
    if (!_isFormComplete || _isLoading) return;
    setState(() => _isLoading = true);
    final storageService = Provider.of<StorageService>(context, listen: false);

    try {
      final imageUrl = await storageService.uploadImage(_selectedImage!);
      if (imageUrl == null) throw Exception("Upload failed");

      final int itemScore = _calculateItemScore(_material!);

      final query = await FirebaseFirestore.instance.collection("users").where("Email", isEqualTo: widget.email).limit(1).get();
      
      if (query.docs.isNotEmpty) {
        final userDocId = query.docs.first.id;
        
        await FirebaseFirestore.instance.collection("users").doc(userDocId).collection("clothes").add({
          "name": _nameController.text.trim(),
          "type": _type,
          "subcategory": _subcategory,
          "material": _material,
          "color": _color,
          "shade": _shade,
          "formality": _formality,
          "imageUrl": imageUrl,
          "itemScore": itemScore,
          "createdAt": FieldValue.serverTimestamp(),
        });

        await _updateUserEcoScore(userDocId);

      } else { 
        throw Exception("User not found for email: ${widget.email}"); 
      }
      
      if(mounted) {
        ToastHelper.showToast(message: "Cloth Saved Successfully!", backgroundColor: primaryColor.withOpacity(0.5), icon: Icons.check_circle);
        setState(() {
          _selectedImage = null; _predictedLabel = null; _predictionConfidence = null;
          _nameController.clear(); _type = null; _subcategory = null; _material = null;
          _color = null; _shade = null; _formality = null;
          _userManuallyChangedType = false;
        });
      }
    } catch (e) {
      debugPrint("Error saving cloth: $e");
      if (mounted) ToastHelper.showToast(message: "Error saving cloth: $e", backgroundColor: Colors.red, icon: Icons.error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showConfidence = _predictionConfidence != null && !_userManuallyChangedType;
    return Stack(
      children: [
        Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration( gradient: LinearGradient( colors: [ Color.fromARGB(255, 218, 202, 242), Color.fromARGB(255, 230, 220, 245) ], begin: Alignment.topCenter, end: Alignment.bottomCenter, ), ),
            child: SafeArea( child: Column( children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildImagePickerRow(),
                  const SizedBox(height: 20),
                  if (_selectedImage != null) Expanded(child: _buildForm(showConfidence: showConfidence))
                  else const Expanded( child: Center( child: Text( "Please select an image to begin", style: TextStyle(fontSize: 16, color: Colors.black54), ), ), ),
                ], ), ),
          ),
        ),
        if (_isLoading) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildHeader() {
      return Padding( padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20), child: Row( children: [ CircleAvatar( radius: 22, backgroundColor: primaryColor.withOpacity(0.1), child: Icon(Icons.add_a_photo, color: primaryColor, size: 28), ), const SizedBox(width: 12), Column( crossAxisAlignment: CrossAxisAlignment.start, children: [ Text("Upload Photo", style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: primaryColor)), Text(widget.email, style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey[700])), ], ), const Spacer(), ], ), );
  }

  Widget _buildImagePickerRow() {
      return Row(mainAxisAlignment: MainAxisAlignment.center, children: [ ElevatedButton.icon( style: ElevatedButton.styleFrom(backgroundColor: primaryColor.withOpacity(0.9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _isLoading ? null : _goToCameraPage, icon: const Icon(Icons.camera_alt, color: Colors.white), label: const Text("Camera", style: TextStyle(color: Colors.white))), const SizedBox(width: 16), ElevatedButton.icon( style: ElevatedButton.styleFrom(backgroundColor: primaryColor.withOpacity(0.9), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: _isLoading ? null : _pickFromGallery, icon: const Icon(Icons.photo_library, color: Colors.white), label: const Text("Gallery", style: TextStyle(color: Colors.white))), ]);
  }

  Widget _buildForm({required bool showConfidence}) {
      Color scoreColor = Colors.grey.shade800;
      Color scoreBorderColor = Colors.transparent;
      if (_material != null) {
        final isSustainable = _calculateItemScore(_material!) == sustainableScore;
        scoreColor = isSustainable ? Colors.green.shade900 : Colors.orange.shade900;
        scoreBorderColor = isSustainable ? Colors.green.shade700 : Colors.orange.shade800;
      }

      return SingleChildScrollView( child: _GlassContainer( child: Column( children: [
            AspectRatio( aspectRatio: 1.0, child: ClipRRect( borderRadius: BorderRadius.circular(15), child: Image.file(_selectedImage!, fit: BoxFit.cover))),
            const SizedBox(height: 10),
            AnimatedOpacity( opacity: showConfidence ? 1.0 : 0.0, duration: const Duration(milliseconds: 300), child: showConfidence ? Padding( padding: const EdgeInsets.symmetric(vertical: 8.0), child: Text( "${(_predictionConfidence! * 100).toStringAsFixed(1)}% Confidence", style: GoogleFonts.poppins( fontSize: 17, fontWeight: FontWeight.w600, color: primaryColor.withOpacity(0.95)), textAlign: TextAlign.center, ), ) : const SizedBox(height: 10 + 16 + 8.0*2), ),
            const SizedBox(height: 15),
            _buildTextField("Cloth Name", _nameController),
            _buildDropdown("Type", types, _type, (val) { final predictedType = _mapLabelToType(_predictedLabel ?? ''); setState(() { _type = val; _subcategory = null; _userManuallyChangedType = (val != null && _predictedLabel != null && val != predictedType); }); }),
            if (_type != null) _buildDropdown("Subcategory", subcategories[_type] ?? [], _subcategory, (val) => setState(() => _subcategory = val)),
            _buildDropdown("Material", materials, _material, (val) => setState(() => _material = val)),
            Row( children: [ Expanded(child: _buildDropdown("Color", colors, _color, (val) => setState(() => _color = val))), const SizedBox(width: 10), Expanded(child: _buildDropdown("Shade", shades, _shade, (val) => setState(() => _shade = val))), ], ),
            _buildDropdown("Formality", formalities, _formality, (val) => setState(() => _formality = val)),
            
            const SizedBox(height: 20),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              opacity: _material != null ? 1.0 : 0.0, 
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8), 
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreBorderColor, width: 2), 
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Item Score:",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: labelColor,
                      ),
                    ),
                    Text(
                      _material != null 
                          ? "${_calculateItemScore(_material!)} / $sustainableScore"
                          : "", 
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreColor, 
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),
            ElevatedButton( style: ElevatedButton.styleFrom(backgroundColor: _isFormComplete ? primaryColor : Colors.grey, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 40)), onPressed: (_isFormComplete && !_isLoading) ? _saveClothDetails : null, child: Text("Save Cloth Details", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)), ),
            const SizedBox(height: 10),
          ], ), ), );
  }

  Widget _buildTextField(String label, TextEditingController controller) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 7), child: TextField( controller: controller, onChanged: (_) => setState(() {}), style: GoogleFonts.poppins(color: Colors.black.withOpacity(0.85), fontSize: 15), decoration: InputDecoration( labelText: label, labelStyle: GoogleFonts.poppins(color: labelColor, fontWeight: FontWeight.w500), floatingLabelStyle: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w500), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white.withOpacity(0.85), contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16), ), ), );

  Widget _buildDropdown( String label, List<String> items, String? selectedValue, ValueChanged<String?> onChanged) {
      return Padding( padding: const EdgeInsets.symmetric(vertical: 7), child: DropdownButtonFormField<String>( value: selectedValue, decoration: InputDecoration( labelText: label, labelStyle: GoogleFonts.poppins(color: labelColor, fontWeight: FontWeight.w500), floatingLabelStyle: GoogleFonts.poppins(color: primaryColor, fontWeight: FontWeight.w500), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), filled: true, fillColor: Colors.white.withOpacity(0.85), contentPadding: const EdgeInsets.fromLTRB(16, 14, 12, 14), ), items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: GoogleFonts.poppins(color: Colors.black.withOpacity(0.85), fontSize: 15)))).toList(), onChanged: (newValue) { onChanged(newValue); /* setState is handled elsewhere */ }, icon: Icon(Icons.arrow_drop_down_rounded, color: primaryColor.withOpacity(0.9), size: 28), dropdownColor: Colors.grey.shade50.withOpacity(0.98), style: GoogleFonts.poppins(color: Colors.black.withOpacity(0.85), fontSize: 15), ), ); }

  Widget _buildLoadingOverlay() {
      return Positioned.fill( child: Container( color: Colors.black.withOpacity(0.5), child: Center( child: Column( mainAxisSize: MainAxisSize.min, children: [ SpinKitDoubleBounce(color: Colors.white, size: 60.0), const SizedBox(height: 20), Text( _selectedImage != null && _nameController.text.isNotEmpty && _isLoading ? "Saving details..." : "Processing image...", style: GoogleFonts.poppins(color: Colors.white, fontSize: 16), ), ], ), ), ), );
  }
}


class _GlassContainer extends StatelessWidget {
  final Widget child;
  const _GlassContainer({required this.child});
  @override
  Widget build(BuildContext context) { return ClipRRect( borderRadius: BorderRadius.circular(20), child: BackdropFilter( filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), child: Container( padding: const EdgeInsets.all(16), margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration( borderRadius: BorderRadius.circular(20), color: Colors.white.withOpacity(0.25), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1), ), child: child, ), ), ); }
}