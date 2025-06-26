import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/ocr_screen.dart';
import 'screens/gpt_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

late List<CameraDescription> cameras;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();

  try {
    print('CWD: ${Directory.current.path}');
    await dotenv.load(fileName: "assets/.env");
    print("Env loaded: ${dotenv.env}");
  } catch (e) {
    print("Failed to load env: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MainMenu(),
    );
  }
}

class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cam = cameras.first;

    return Scaffold(
      appBar: AppBar(title: const Text('OCR Menu')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('Traditional OCR'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => OCRScreen(cameras: cameras)),
                );
              },
            ),
            ElevatedButton(
              child: const Text('GPT OCR'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => GptScreen(camera: cam)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}