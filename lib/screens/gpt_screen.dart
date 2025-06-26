import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_cropper/image_cropper.dart';
import '../utils/gpt_scan.dart'; // or ocr logic depending on the screen

class GptScreen extends StatefulWidget {
  final CameraDescription camera;

  const GptScreen({super.key, required this.camera});

  @override
  State<GptScreen> createState() => _GptScreenState();
}

class _GptScreenState extends State<GptScreen> {
  late CameraController _controller;
  bool _isInitialized = false;
  bool _isProcessing = false;
  String storeName = '', paymentAmount = '', paymentDate = '', storeLocation = '', rawText = '';

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    _controller.initialize().then((_) {
      if (!mounted) return;
      setState(() => _isInitialized = true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndRecognizeText() async {
    if (!_controller.value.isInitialized) return;

    try {
      final image = await _controller.takePicture();

      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(toolbarTitle: 'Crop Image'),
          IOSUiSettings(title: 'Crop Image'),
        ],
      );

      if (cropped == null) return;

      setState(() => _isProcessing = true);

      final result = await processReceiptWithGPT(cropped.path); // your GPT logic here
      setState(() {
        storeName = result.storeName;
        paymentAmount = result.paymentAmount;
        paymentDate = result.paymentDate;
        storeLocation = result.storeLocation;
        rawText = result.rawText;
      });
    } catch (e) {
      setState(() {
        storeName = paymentAmount = paymentDate = storeLocation = 'N/A';
        rawText = 'Error: $e';
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || !_controller.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('GPT OCR')),
      body: Column(
        children: [
          Expanded(child: CameraPreview(_controller)),
          ElevatedButton(
            onPressed: (_isProcessing || !_isInitialized) ? null : _takePictureAndRecognizeText,
            child: const Text('Capture and Scan'),
          ),
          if (_isProcessing)
            const CircularProgressIndicator()
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(8),
                children: [
                  Text('Store: $storeName'),
                  Text('Amount: $paymentAmount'),
                  Text('Date: $paymentDate'),
                  Text('Location: $storeLocation'),
                  const Divider(),
                  Text('Raw OCR Text:\n$rawText'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}