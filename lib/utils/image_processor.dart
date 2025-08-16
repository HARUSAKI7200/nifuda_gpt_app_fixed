// lib/utils/image_processor.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
// ★★★ 修正点: flutter_image_compress のインポートを削除 ★★★
// import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'ocr_masker.dart';

/// Isolateで画像処理を実行するためのトップレベル関数
///
/// この関数はUIスレッドをブロックすることなく、以下の処理をバックグラウンドで実行します。
/// 1. ファイルパスから画像を読み込み、デコードする
/// 2. 画像の向きをEXIF情報に基づいて補正する
/// 3. プレビューサイズとの比率から、マスクを適用する実際の座標を計算する
/// 4. マスク処理を適用する
/// 5. AI送信用にJPEG形式にエンコードして返す (imageパッケージを使用)
Future<Uint8List?> processImageForOcr(Map<String, dynamic> args) async {
  final String imagePath = args['imagePath'];
  final List<Rect> maskRects = (args['rects'] as List)
      .map((r) => Rect.fromLTRB(r['l'], r['t'], r['r'], r['b']))
      .toList();
  final String maskTemplate = args['template'];
  final Size previewSize = Size(args['previewW'], args['previewH']);
  
  debugPrint('Isolate: 画像処理開始');
  debugPrint('Isolate: template: $maskTemplate, rects count: ${maskRects.length}');

  try {
    final originalImageBytes = await File(imagePath).readAsBytes();
    img.Image? originalImage = img.decodeImage(originalImageBytes);
    if (originalImage == null) {
      debugPrint('Isolate: 画像のデコードに失敗しました。');
      return null;
    }

    // 画像の向きを自動補正する処理
    originalImage = img.bakeOrientation(originalImage);

    // プレビューサイズと実画像のサイズ比を計算
    final double scaleX = originalImage.width / previewSize.width;
    final double scaleY = originalImage.height / previewSize.height;

    // マスク座標を実画像サイズに合わせる
    final List<Rect> actualMaskRects = maskRects.map((rect) {
      return Rect.fromLTRB(
        rect.left * scaleX, rect.top * scaleY,
        rect.right * scaleX, rect.bottom * scaleY,
      );
    }).toList();

    // マスク処理を適用
    final img.Image maskedImage = applyMaskToImage(
      originalImage,
      template: maskTemplate,
      dynamicMaskRects: actualMaskRects,
    );

    // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    // ★ 変更点：
    // ★ flutter_image_compress の呼び出しを削除し、
    // ★ imageパッケージのencodeJpgで品質を指定してエンコードする方式に変更。
    // ★ これにより、Isolate内でネイティブコードを呼び出す必要がなくなり、
    // ★ UnimplementedErrorが解消されます。
    // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
    final Uint8List jpegBytes = Uint8List.fromList(img.encodeJpg(maskedImage, quality: 85));
    
    debugPrint('Isolate: 画像処理完了、${jpegBytes.lengthInBytes} bytes');
    return jpegBytes;
    
  } catch (e) {
    debugPrint('Isolateでの画像処理中にエラーが発生しました: $e');
    return null;
  }
}