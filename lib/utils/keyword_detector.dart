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

    // ★ 追加機能: 特定キーワードより「上」を全て塗りつぶすためのトリガーワード
    const String topMaskTriggerKeyword = '注文主';

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
          
          // 1. 通常のキーワード判定
          for (String keyword in targetKeywords) {
            if (lineText.contains(keyword)) {
              detectedRedactionRects.add(line.boundingBox);
              break; 
            }
          }

          // 2. 「注文主」より上を塗りつぶす特別ルール
          // 「注文主」が含まれていたら、その行の上端(top)より上の領域全体をマスクに追加
          if (lineText.contains(topMaskTriggerKeyword)) {
            // 幅は十分に大きな値(100000)を指定しておけば、ocr_masker側で画像幅に合わせてカット(clamp)される
            final Rect topAreaRect = Rect.fromLTRB(
              0, 
              0, 
              100000, 
              line.boundingBox.top // この行の上端まで
            );
            detectedRedactionRects.add(topAreaRect);
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