
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui'; 
import 'dart:convert'; 
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart'; 
import 'package:http/http.dart' as http; 
import 'package:http_parser/http_parser.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  List<CameraDescription> cameras = [];
  CameraController? cameraController;


  final String _apiUrl = "http://172.20.10.3:8000/predict";

 
  String? _realtimeLabel;
  double? _realtimeConfidence;
  bool _runningInference = false;

  final int inputSize = 224;
  final int inferenceDelayMs = 500;

  final Map<String, Color> classColor = {
    'headwear': Colors.orange.shade700,
    'pants': Colors.blue.shade700,
    'shoes': Colors.green.shade700,
    'tops': Colors.purple.shade700,
    'default': Colors.white70,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCameraAndModel();
  }

  Future<void> _initializeCameraAndModel() async {
    // await _loadModelAndLabels(); // <-- REMOVED
    if (mounted) {
      await _setupCameraController();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    final controller = cameraController;
    cameraController = null;
    controller?.stopImageStream().catchError((e) {
      debugPrint("Error stopping image stream during dispose: $e");
    });
    controller?.dispose();
    // _interpreter?.close(); // <-- REMOVED
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final CameraController? currentCameraController = cameraController;

    if (currentCameraController == null || !currentCameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      final controllerToDispose = cameraController;
      cameraController = null;
      controllerToDispose?.dispose();
      if (mounted) setState(() { _realtimeLabel = null; _realtimeConfidence = null; });

    } else if (state == AppLifecycleState.resumed) {
      if (cameraController == null) {
        _initializeCameraAndModel();
      }
    }
  }


  Future<void> _setupCameraController() async {
      if (cameraController?.value.isInitialized ?? false) {
          if (!cameraController!.value.isStreamingImages) {
              try { await cameraController!.startImageStream(_processCameraImage); }
              catch (e) { debugPrint("Error restarting image stream: $e"); }
          }
          return;
      }

    try {
      final available = await availableCameras();
      if (available.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No cameras found on this device.'))
        );
        return;
      }
      cameras = available;
      final CameraDescription selectedCamera = cameras.first;

      cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isIOS ? ImageFormatGroup.bgra8888 : ImageFormatGroup.yuv420,
      );

      await cameraController!.initialize();

      if (mounted) {
        await cameraController!.startImageStream(_processCameraImage);
        setState(() {});
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera initialization failed: $e'))
      );
    }
  }

  int _lastInferenceMs = 0;
  Future<void> _processCameraImage(CameraImage image) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastInferenceMs < inferenceDelayMs) return;
    _lastInferenceMs = now;

    if (_runningInference || !mounted) return;
    
    if (_apiUrl.contains("YOUR_COMPUTER_IP")) {
       debugPrint("❌ Error: API URL not configured. Please set your IP in _apiUrl.");
       return;
    }
    
    _runningInference = true;

    try {
        img.Image? rgbImage;
        if (Platform.isAndroid && image.format.group == ImageFormatGroup.yuv420) {
            rgbImage = await compute(_convertYUV420ToImage, {
              'planes': image.planes.map((p) => p.bytes).toList(),
              'width': image.width, 'height': image.height,
              'yRowStride': image.planes[0].bytesPerRow,
              'uvRowStride': image.planes[1].bytesPerRow, 'uvPixelStride': image.planes[1].bytesPerPixel ?? 1,
              'vRowStride': image.planes[2].bytesPerRow, 'vPixelStride': image.planes[2].bytesPerPixel ?? 1,
            });
        } else if (Platform.isIOS && image.format.group == ImageFormatGroup.bgra8888) {
            rgbImage = await compute(_convertBGRA8888ToImage, {
              'plane': image.planes[0].bytes,
              'width': image.width, 'height': image.height, 'bytesPerRow': image.planes[0].bytesPerRow,
            });
        } else {
            _runningInference = false; return;
        }
        if (rgbImage == null) throw Exception("Image conversion failed in isolate.");


      img.Image square = _centerCropToSquare(rgbImage);
      img.Image resized = img.copyResize(square, width: inputSize, height: inputSize, 
          interpolation: img.Interpolation.cubic);
      
      final jpgBytes = img.encodeJpg(resized, quality: 90);

      var uri = Uri.parse(_apiUrl);
      var request = http.MultipartRequest("POST", uri);
      var multipartFile = http.MultipartFile.fromBytes(
          'file', 
          jpgBytes,
          filename: 'frame.jpg', 
          contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var json = jsonDecode(responseBody) as Map<String, dynamic>;
        
        final predictedLabel = json['label'] as String;
        final maxConfidence = (json['confidence'] as num).toDouble();

        if (mounted) {
          setState(() {
            _realtimeLabel = predictedLabel;
            _realtimeConfidence = maxConfidence;
          });
        }
      } else {
        debugPrint('API Error: ${response.statusCode}');
      }

    } catch (e) {
      debugPrint('Inference error: $e');
    } finally {
      _runningInference = false;
    }
  }

  static img.Image? _convertYUV420ToImage(Map<String, dynamic> params) {
      try {
          final List<Uint8List> planes = params['planes'];
          final int width = params['width']; final int height = params['height'];
          final int yRowStride = params['yRowStride'];
          final int uvRowStride = params['uvRowStride']; final int uvPixelStride = params['uvPixelStride'];
          final int vRowStride = params['vRowStride']; final int vPixelStride = params['vPixelStride'];
          final y = planes[0]; final u = planes[1]; final v = planes[2];
          final imgData = Uint8List(width * height * 3); int p = 0;
          for (int row = 0; row < height; row++) {
              for (int col = 0; col < width; col++) {
                  final yIndex = row * yRowStride + col;
                  final uvRow = row ~/ 2; final uvCol = col ~/ 2;
                  final uIndex = uvRow * uvRowStride + uvCol * uvPixelStride;
                  final vIndex = uvRow * vRowStride + uvCol * vPixelStride;
                  if (yIndex >= y.length || uIndex >= u.length || vIndex >= v.length) { continue; }
                  final Y = y[yIndex] & 0xFF; final U = u[uIndex] & 0xFF; final V = v[vIndex] & 0xFF;
                  int r = (Y + 1.13983 * (V - 128)).round(); int g = (Y - 0.39465 * (U - 128) - 0.58060 * (V - 128)).round(); int b = (Y + 2.03211 * (U - 128)).round();
                  imgData[p++] = r.clamp(0, 255); imgData[p++] = g.clamp(0, 255); imgData[p++] = b.clamp(0, 255);
              }
          }
          return img.Image.fromBytes(width: width, height: height, bytes: imgData.buffer, numChannels: 3);
      } catch (e) { return null; }
  }

  static img.Image? _convertBGRA8888ToImage(Map<String, dynamic> params) {
      try {
          final Uint8List plane = params['plane'];
          final int width = params['width']; final int height = params['height']; final int bytesPerRow = params['bytesPerRow'];
          final imgData = Uint8List(width * height * 3); int outIndex = 0;
          for (int y = 0; y < height; y++) {
              int rowStart = y * bytesPerRow;
              for (int x = 0; x < width; x++) {
                  int pixelIndex = rowStart + x * 4;
                  if (pixelIndex + 3 >= plane.length) { continue; }
                  final b = plane[pixelIndex]; final g = plane[pixelIndex + 1]; final r = plane[pixelIndex + 2];
                  imgData[outIndex++] = r; imgData[outIndex++] = g; imgData[outIndex++] = b;
              }
          }
          return img.Image.fromBytes(width: width, height: height, bytes: imgData.buffer, numChannels: 3);
      } catch (e) { return null; }
  }

  img.Image _centerCropToSquare(img.Image src) {
    final int size = min(src.width, src.height);
    final int x = ((src.width - size) / 2).round();
    final int y = ((src.height - size) / 2).round();
    return img.copyCrop(src, x: x, y: y, width: size, height: size);
  }

  Color _colorForLabel(String label) {
    final l = label.toLowerCase();
    if (l == 'headwear') return classColor['headwear']!;
    if (l == 'pants') return classColor['pants']!;
    if (l == 'shoes') return classColor['shoes']!;
    if (l == 'tops') return classColor['tops']!;
    return classColor['default']!;
  }

  Future<void> _onCapturePressed() async {
      final controller = cameraController;
      if (controller == null || !controller.value.isInitialized || controller.value.isTakingPicture) return;
      try {
        if (controller.value.isStreamingImages) { await controller.stopImageStream(); }
        XFile picture = await controller.takePicture();
        File file = File(picture.path);
        final bytes = await file.readAsBytes(); img.Image? captured = img.decodeImage(bytes);
        if (captured == null) throw Exception("Failed to decode captured image");
        int size = min(captured.width, captured.height); int x = (captured.width - size) ~/ 2; int y = (captured.height - size) ~/ 2;
        img.Image squareImage = img.copyCrop(captured, x: x, y: y, width: size, height: size);
        await file.writeAsBytes(img.encodeJpg(squareImage, quality: 90));
        if (mounted) { Navigator.pop(context, file.path); }
      } catch (e) {
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar( SnackBar(content: Text('Error capturing image: $e')) ); }
      } finally {
        if (cameraController?.value.isInitialized == true && cameraController?.value.isStreamingImages == false) {
          try { await cameraController!.startImageStream(_processCameraImage); }
          catch (_) {}
        }
      }
  }

  @override
  Widget build(BuildContext context) {
    final CameraController? currentCameraController = cameraController;
    if (currentCameraController == null || !currentCameraController.value.isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.deepPurpleAccent)),
      );
    }
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: currentCameraController.value.previewSize!.height,
                        height: currentCameraController.value.previewSize!.width,
                        child: CameraPreview(currentCameraController),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            LayoutBuilder(builder: (context, constraints) {
              final double side = min(constraints.maxWidth, constraints.maxHeight);
              final Color borderColor = (_realtimeLabel != null)
                  ? _colorForLabel(_realtimeLabel!)
                  : classColor['default']!;
              return Align(
                alignment: Alignment.center,
                child: Container(
                  width: side * 0.9,
                  height: side * 0.9,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: borderColor.withOpacity(0.9), width: 6),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 1)
                      ]),
                ),
              );
            }),
            Positioned(
              top: 20,
              left: 20,
              child: Container(
                decoration: BoxDecoration( color: Colors.black.withOpacity(0.4), shape: BoxShape.circle, ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                  onPressed: () => Navigator.pop(context),
                  tooltip: "Go back",
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      opacity: (_realtimeLabel != null && _realtimeConfidence != null) ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.65),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          _realtimeLabel != null && _realtimeConfidence != null
                              ? "${_realtimeLabel!}   ${(100 * _realtimeConfidence!).toStringAsFixed(1)}%"
                              : "",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.2),
                        border: Border.all(color: Colors.white.withOpacity(0.7), width: 4),
                      ),
                      child: IconButton(
                        iconSize: 40,
                        padding: EdgeInsets.zero,
                        onPressed: _onCapturePressed,
                        icon: const Icon(Icons.camera, color: Colors.white),
                        tooltip: "Capture Image",
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}