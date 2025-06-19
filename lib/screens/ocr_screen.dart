import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class CameraOCRScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraOCRScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  _CameraOCRScreenState createState() => _CameraOCRScreenState();
}

class _CameraOCRScreenState extends State<CameraOCRScreen> {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  String storeName = '';
  String paymentAmount = '';
  String paymentDate = '';
  String paymentLocation = '';
  String rawText = '';

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    _controller.initialize().then((_) {
      setState(() => _isCameraInitialized = true);
    });
  }

  Future<void> _takePictureAndRecognizeText() async {
    try {
      final image = await _controller.takePicture();

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '이미지 자르기',
            toolbarColor: Colors.deepOrange,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: '이미지 자르기'),
        ],
      );

      if (croppedFile == null) return;

      final inputImage = InputImage.fromFilePath(croppedFile.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      textRecognizer.close();

      final lines = recognizedText.text.split('\n');
      final mergedText = lines.join(' ').replaceAll('\n', ' ');
      rawText = recognizedText.text;
      String? tmpStore = lines.first.trim(), tmpAmount, tmpDate, tmpLocation;

      for (final line in lines) {
        final cleaned = line.trim();

        if (tmpStore == null && RegExp(r'(상호|가게명|대표자)').hasMatch(cleaned)) {
          tmpStore = cleaned.split(RegExp(r'[:：]')).last.trim();
        }

        final amountMatches = RegExp(r'(\d{1,3}([.,]\d{3})+)').allMatches(cleaned);
        for (final match in amountMatches) {
          final raw = match.group(0)!;
          final numStr = raw.replaceAll(RegExp(r'[.,]'), '');
          final num = int.tryParse(numStr);
          final currentStr = tmpAmount?.replaceAll(RegExp(r'[₩,]'), '') ?? '0';
          final current = int.tryParse(currentStr) ?? 0;
          if (num != null && num > current) {
            tmpAmount = '₩$raw';
          }
        }


        if (tmpDate == null) {
          final dateMatch = RegExp(
            r'(2025|25)[./-](\w{1,2})[./-](\w{1,2})|(\w{1,2})[./-](\w{1,2})[./-](2025|25)'
          ).firstMatch(mergedText);
          if (dateMatch != null) {
            tmpDate = dateMatch.group(0);
          }
        }

        if (tmpLocation == null && RegExp(r'(주소|위치|지점)').hasMatch(cleaned)) {
          tmpLocation = cleaned.split(RegExp(r'[:：]')).last.trim();
        }
      }

      setState(() {
        storeName = tmpStore ?? 'N/A';
        paymentAmount = tmpAmount ?? 'N/A';
        paymentDate = tmpDate ?? 'N/A';
        paymentLocation = tmpLocation ?? 'N/A';
      });
    } catch (e) {
      setState(() {
        rawText = 'Error: $e';
        storeName = paymentAmount = paymentDate = paymentLocation = 'N/A';
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('OCR 영수증 인식')),
      body: Column(
        children: [
          _isCameraInitialized
              ? Expanded(child: CameraPreview(_controller))
              : const Center(child: CircularProgressIndicator()),
          ElevatedButton(
            onPressed: _takePictureAndRecognizeText,
            child: const Text('촬영 및 텍스트 인식'),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('가게 이름: $storeName'),
                  Text('결제 금액: $paymentAmount'),
                  Text('결제 날짜: $paymentDate'),
                  Text('결제 장소: $paymentLocation'),
                  const SizedBox(height: 16),
                  Text('전체 텍스트:'),
                  Text(rawText, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}