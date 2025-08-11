import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'mask_profiles/masker_t.dart' as masker_t;

/// 指定テンプレートまたは動的範囲に従って画像にマスク処理を適用して返す。
/// ★ 修正点: 速度向上のため、画像のコピーを作成せず、渡されたオリジナル画像を直接変更する方式に戻す
img.Image applyMaskToImage(
  img.Image originalImage, {
  String template = 'default',
  List<Rect>? dynamicMaskRects,
}) {
  switch (template) {
    case 't':
      // masker_t.maskImageがoriginalImageを直接変更する
      return masker_t.maskImage(originalImage);

    case 'none':
      // マスク処理が不要な場合は、何もせずそのまま返す
      return originalImage;

    case 'dynamic':
      if (dynamicMaskRects == null || dynamicMaskRects.isEmpty) {
        return originalImage;
      }

      final int imageWidth = originalImage.width;
      final int imageHeight = originalImage.height;
      final maskColor = img.ColorRgb8(0, 0, 0);

      for (final rect in dynamicMaskRects) {
        final x1 = rect.left.toInt().clamp(0, imageWidth);
        final y1 = rect.top.toInt().clamp(0, imageHeight);
        final x2 = rect.right.toInt().clamp(0, imageWidth);
        final y2 = rect.bottom.toInt().clamp(0, imageHeight);
        
        // originalImageオブジェクトを直接変更する
        img.fillRect(
          originalImage,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: maskColor,
        );
      }
      // 変更が適用されたoriginalImageを返す
      return originalImage;

    default:
      throw UnimplementedError('予期せぬマスクテンプレート [$template] が指定されました。');
  }
}