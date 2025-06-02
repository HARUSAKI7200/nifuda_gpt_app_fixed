import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'mask_profiles/masker_t.dart' as masker_t;
// custom_snackbar.dartはここでは直接使用しないためインポートなし

/// 指定テンプレートに従って画像にマスク処理を適用して返す。
Future<Uint8List> applyMaskToImage(Uint8List originalBytes, {String template = 'default'}) async {
  switch (template) {
    case 't':
      return masker_t.maskImage(originalBytes);

    case 'none':
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        throw Exception('画像のデコードに失敗しました');
      }
      return Uint8List.fromList(img.encodeJpg(decoded, quality: 85));

    default:
      throw UnimplementedError('マスクテンプレート [$template] は未対応です');
  }
}