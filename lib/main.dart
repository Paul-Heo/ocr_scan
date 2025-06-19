import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/ocr_screen.dart';

late List<CameraDescription> cameras;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CameraOCRScreen(cameras: cameras),
    );
  }
}