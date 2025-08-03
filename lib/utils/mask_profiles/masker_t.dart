import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Android向け：T社の製品リスト用画像マスク処理
Future<Uint8List> maskImage(Uint8List originalBytes) async {
  final decoded = img.decodeImage(originalBytes);
  if (decoded == null) {
    throw Exception('画像のデコードに失敗しました');
  }

  final width = decoded.width;
  final height = decoded.height;
  final maskColor = img.ColorRgb8(0, 0, 0);

  // 右上の表
  img.fillRect(
    decoded,
    x1: (width * 0.41).toInt(),
    y1: (height * 0.05).toInt(),
    x2: (width * 0.88).toInt(),
    y2: (height * 0.135).toInt(),
    color: maskColor,
  );

  // フッター帯
  img.fillRect(
    decoded,
    x1: (width * 0.04).toInt(),
    y1: (height * 0.82).toInt(),
    x2: (width * 0.96).toInt(),
    y2: (height * 0.93).toInt(),
    color: maskColor,
  );

  final maskedBytes = img.encodeJpg(decoded, quality: 85);
  return Uint8List.fromList(maskedBytes);
}