import 'dart:typed_data';
import 'package:flutter/widgets.dart'; // Rectを使うために追加
import 'package:image/image.dart' as img;
import 'mask_profiles/masker_t.dart' as masker_t;

// ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
// ★ 変更点：動的マスクに対応させるため、引数とロジックを追加
// ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

/// 指定テンプレートまたは動的範囲に従って画像にマスク処理を適用して返す。
Future<Uint8List> applyMaskToImage(
  Uint8List originalBytes, {
  String template = 'default',
  List<Rect>? dynamicMaskRects, // 動的マスクの範囲を格納するリスト
}) async {
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) {
    throw Exception('画像のデコードに失敗しました');
  }

  switch (template) {
    case 't':
      return masker_t.maskImage(originalBytes);

    case 'none':
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));

    case 'dynamic': // 動的マスク処理用の新しいケース
      if (dynamicMaskRects == null || dynamicMaskRects.isEmpty) {
        // マスク範囲が指定されていない場合は何もしない
        return originalBytes;
      }

      final int imageWidth = decoded.width;
      final int imageHeight = decoded.height;
      final maskColor = img.ColorRgb8(0, 0, 0); // マスクの色（黒）

      // 渡された各Rect範囲を塗りつぶす
      for (final rect in dynamicMaskRects) {
        // FlutterのRect座標をimageライブラリの座標に変換
        final x1 = rect.left.toInt().clamp(0, imageWidth);
        final y1 = rect.top.toInt().clamp(0, imageHeight);
        final x2 = rect.right.toInt().clamp(0, imageWidth);
        final y2 = rect.bottom.toInt().clamp(0, imageHeight);
        
        // fillRectはx1, y1, x2, y2で矩形を指定する
        img.fillRect(
          decoded,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: maskColor,
        );
      }
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));

    default:
      throw UnimplementedError('マスクテンプレート [$template] は未対応です');
  }
}