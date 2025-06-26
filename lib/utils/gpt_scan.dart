import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReceiptData {
  final String storeName;
  final String paymentAmount;
  final String paymentDate;
  final String storeLocation;
  final String rawText;

  ReceiptData({
    required this.storeName,
    required this.paymentAmount,
    required this.paymentDate,
    required this.storeLocation,
    required this.rawText,
  });
}

Future<ReceiptData> processReceiptWithGPT(String imagePath) async {

  final bytes = await File(imagePath).readAsBytes();
  final base64Image = base64Encode(bytes);

  final payload = jsonEncode({
    "model": "gpt-4o",
    "messages": [
      {
        "role": "system",
        "content": "You are an expert at reading Korean receipts. Given a base64-encoded image, extract the store name, payment amount, payment date, and store location. Respond in JSON with keys: storeName, paymentAmount, paymentDate, storeLocation, rawText."
      },
      {
        "role": "user",
        "content": [
          {
            "type": "image_url",
            "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
          }
        ]
      }
    ]
  });
  final apiKey = dotenv.env['OPENAI_API_KEY'];
  final resp = await http.post(
    Uri.parse("https://api.openai.com/v1/chat/completions"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
    },
    body: payload,
  );

  if (resp.statusCode != 200) {
    throw Exception("GPT OCR failed: ${resp.statusCode} / ${resp.body}");
  }

  final contentRaw = jsonDecode(resp.body)["choices"][0]["message"]["content"];
  final cleaned = contentRaw
      .replaceAll("```json", "")
      .replaceAll("```", "")
      .trim();

  final jsonResp = jsonDecode(cleaned);

  return ReceiptData(
    storeName: jsonResp["storeName"] ?? "N/A",
    paymentAmount: jsonResp["paymentAmount"] ?? "N/A",
    paymentDate: jsonResp["paymentDate"] ?? "N/A",
    storeLocation: jsonResp["storeLocation"] ?? "N/A",
    rawText: jsonResp["rawText"] ?? "",
  );
}