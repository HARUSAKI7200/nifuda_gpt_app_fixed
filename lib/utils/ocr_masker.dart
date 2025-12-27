// lib/utils/ocr_masker.dart
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
// mask_profiles/masker_t.dart のインポート削除

img.Image applyMaskToImage(
  img.Image originalImage, {
  String template = 'none',
  List<Rect>? dynamicMaskRects, 
  List<Rect>? relativeMaskRects, 
}) {
  
  final int w = originalImage.width;
  final int h = originalImage.height;
  final maskColor = img.ColorRgb8(0, 0, 0);

  // 相対座標リストが渡された場合の処理
  if (relativeMaskRects != null && relativeMaskRects.isNotEmpty) {
    for (final r in relativeMaskRects) {
      img.fillRect(
        originalImage,
        x1: (w * r.left).toInt().clamp(0, w),
        y1: (h * r.top).toInt().clamp(0, h),
        x2: (w * r.right).toInt().clamp(0, w),
        y2: (h * r.bottom).toInt().clamp(0, h),
        color: maskColor,
      );
    }
  }

  switch (template) {
    case 'none':
      return originalImage;

    // ★ 修正: 't' のケース削除

    case 'dynamic':
      if (dynamicMaskRects == null || dynamicMaskRects.isEmpty) {
        return originalImage;
      }

      for (final rect in dynamicMaskRects) {
        final x1 = rect.left.toInt().clamp(0, w);
        final y1 = rect.top.toInt().clamp(0, h);
        final x2 = rect.right.toInt().clamp(0, w);
        final y2 = rect.bottom.toInt().clamp(0, h);

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
      return originalImage;
  }
}