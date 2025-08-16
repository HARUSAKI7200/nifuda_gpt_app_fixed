// lib/utils/ocr_masker.dart
import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;
import 'mask_profiles/masker_t.dart' as masker_t;

img.Image applyMaskToImage(
  img.Image originalImage, {
  String template = 'none',
  List<Rect>? dynamicMaskRects,
}) {
  switch (template) {
    case 'none':
      return originalImage;

    case 't':
      return masker_t.maskImage(originalImage);

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
      debugPrint('Warning: Unimplemented mask template [$template] was specified. No mask applied.');
      return originalImage;
  }
}