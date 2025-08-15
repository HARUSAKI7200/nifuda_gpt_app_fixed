// lib/utils/image_processor.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'ocr_masker.dart';

/// Isolateで画像処理を実行するためのトップレベル関数
///
/// この関数はUIスレッドをブロックすることなく、以下の処理をバックグラウンドで実行します。
/// 1. ファイルパスから画像を読み込み、デコードする
/// 2. ★★★ 画像の向きをEXIF情報に基づいて補正する ★★★
/// 3. プレビューサイズとの比率から、マスクを適用する実際の座標を計算する
/// 4. マスク処理を適用する
/// 5. AI送信用にWebP形式に圧縮して返す
Future<Uint8List?> processImageForOcr(Map<String, dynamic> args) async {
  final String imagePath = args['imagePath'];
  final List<Rect> maskRects = (args['rects'] as List)
      .map((r) => Rect.fromLTRB(r['l'], r['t'], r['r'], r['b']))
      .toList();
  final String maskTemplate = args['template'];
  final Size previewSize = Size(args['previewW'], args['previewH']);

  try {
    final originalImageBytes = await File(imagePath).readAsBytes();
    img.Image? originalImage = img.decodeImage(originalImageBytes);
    if (originalImage == null) {
      debugPrint('Isolate: 画像のデコードに失敗しました。');
      return null;
    }

    // ★★★ 修正点：画像の向きを自動補正する処理を復活 ★★★
    originalImage = img.bakeOrientation(originalImage);

    final double scaleX = originalImage.width / previewSize.width;
    final double scaleY = originalImage.height / previewSize.height;

    final List<Rect> actualMaskRects = maskRects.map((rect) {
      return Rect.fromLTRB(
        rect.left * scaleX, rect.top * scaleY,
        rect.right * scaleX, rect.bottom * scaleY,
      );
    }).toList();

    final img.Image maskedImage = applyMaskToImage(
      originalImage,
      template: maskTemplate,
      dynamicMaskRects: actualMaskRects,
    );

    // AI送信用にWebP形式へ圧縮
    final Uint8List resultBytes = await FlutterImageCompress.compressWithList(
      Uint8List.fromList(img.encodeJpg(maskedImage)), // 一度JPGにエンコード
      minHeight: maskedImage.height,
      minWidth: maskedImage.width,
      quality: 85, // WebPの品質
      format: CompressFormat.webp,
    );
    
    return resultBytes;
  } catch (e) {
    debugPrint('Isolateでの画像処理中にエラーが発生しました: $e');
    return null;
  }
}