// lib/utils/keyword_detector.dart
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class KeywordDetector {
  /// 画像パスと検出したいキーワードのリストを受け取り、
  /// そのキーワードが含まれる行のバウンディングボックス(Rect)のリストを返します。
  static Future<List<Rect>> detectKeywords(String imagePath, List<String> targetKeywords) async {
    // 日本語対応のV2モデルを使用
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
    final inputImage = InputImage.fromFilePath(imagePath);

    final List<Rect> detectedRects = [];

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final String lineText = line.text;
          
          // 行のテキストにキーワードが含まれているかチェック
          for (String keyword in targetKeywords) {
            if (lineText.contains(keyword)) {
              // 見つかった場合、その行全体の座標を追加
              detectedRects.add(line.boundingBox);
              // 1つの行で複数のキーワードにヒットしてもRectは1つで良いためbreak
              break; 
            }
          }
        }
      }
    } catch (e) {
      // エラー時は空リストを返す（ログ等は呼び出し元で処理しても良い）
      print('Keyword Detection Error: $e');
    } finally {
      // リソース解放
      textRecognizer.close();
    }

    return detectedRects;
  }
}