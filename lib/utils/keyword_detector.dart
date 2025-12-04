// lib/utils/keyword_detector.dart
import 'dart:ui';
import 'dart:math';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class AnalysisResult {
  final Rect contentRect; // 文字全体が含まれる範囲（トリミング用）
  final List<Rect> redactionRects; // 黒塗り対象の範囲

  AnalysisResult(this.contentRect, this.redactionRects);
}

class KeywordDetector {
  /// 画像を解析し、
  /// 1. 全ての文字が含まれる矩形（自動トリミング用）
  /// 2. 黒塗り対象キーワードの矩形リスト
  /// の両方を返します。
  static Future<AnalysisResult> analyzeImageForAutoCropAndRedaction(
      String imagePath, List<String> targetKeywords) async {
    
    // 日本語対応のV2モデルを使用
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
    final inputImage = InputImage.fromFilePath(imagePath);

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    
    final List<Rect> detectedRedactionRects = [];
    bool hasText = false;

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

      for (TextBlock block in recognizedText.blocks) {
        // 全体の領域計算 (文字がある場所の外枠を広げていく)
        final Rect box = block.boundingBox;
        minX = min(minX, box.left);
        minY = min(minY, box.top);
        maxX = max(maxX, box.right);
        maxY = max(maxY, box.bottom);
        hasText = true;

        for (TextLine line in block.lines) {
          final String lineText = line.text;
          // 黒塗りキーワード判定
          for (String keyword in targetKeywords) {
            if (lineText.contains(keyword)) {
              detectedRedactionRects.add(line.boundingBox);
              break; 
            }
          }
        }
      }
    } catch (e) {
      // エラーログ等は必要に応じて出力
      print('KeywordDetector Analysis Error: $e');
    } finally {
      textRecognizer.close();
    }

    Rect contentRect;
    if (hasText) {
      // 少し余白(パディング)を持たせる
      const double padding = 20.0;
      contentRect = Rect.fromLTRB(
        max(0, minX - padding),
        max(0, minY - padding),
        maxX + padding, 
        maxY + padding,
      );
    } else {
      // 文字が見つからない場合はRect.zeroを返し、呼び出し元で「切り取りなし」として扱う
      contentRect = Rect.zero;
    }

    return AnalysisResult(contentRect, detectedRedactionRects);
  }

  // 互換性維持のための旧メソッド
  static Future<List<Rect>> detectKeywords(String imagePath, List<String> targetKeywords) async {
    final result = await analyzeImageForAutoCropAndRedaction(imagePath, targetKeywords);
    return result.redactionRects;
  }
}