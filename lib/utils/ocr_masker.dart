import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'mask_profiles/masker_t.dart' as masker_t;

/// 指定テンプレートまたは動的範囲に従って画像にマスク処理を適用して返す。
// ★修正点: 引数をUint8Listからimg.Imageに変更
Future<img.Image> applyMaskToImage(
  img.Image originalImage, {
  String template = 'default',
  List<Rect>? dynamicMaskRects,
}) async {
  // ここではデコードは不要

  switch (template) {
    case 't':
      // masker_t.maskImageはバイト列を扱うため、一度エンコードして渡す
      final bytes = Uint8List.fromList(img.encodeJpg(originalImage, quality: 85));
      final maskedBytes = await masker_t.maskImage(bytes);
      final maskedImage = img.decodeImage(maskedBytes);
      return maskedImage!;

    case 'none':
      return originalImage;

    case 'dynamic':
      if (dynamicMaskRects == null || dynamicMaskRects.isEmpty) {
        return originalImage;
      }

      final int imageWidth = originalImage.width;
      final int imageHeight = originalImage.height;
      final maskColor = img.ColorRgb8(0, 0, 0);

      // 渡された各Rect範囲を塗りつぶす
      for (final rect in dynamicMaskRects) {
        final x1 = rect.left.toInt().clamp(0, imageWidth);
        final y1 = rect.top.toInt().clamp(0, imageHeight);
        final x2 = rect.right.toInt().clamp(0, imageWidth);
        final y2 = rect.bottom.toInt().clamp(0, imageHeight);
        
        img.fillRect(
          originalImage,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: maskColor,
        );
      }
      return originalImage;

    default:
      throw UnimplementedError('マスクテンプレート [$template] は未対応です');
  }
}