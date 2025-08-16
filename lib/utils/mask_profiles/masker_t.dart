import 'package:image/image.dart' as img;

/// Android向け：T社の製品リスト用画像マスク処理
/// ★ 修正点: 渡された画像を直接変更するため、このファイルの修正は不要。
///           可読性のために引数名を`image`に変更。
img.Image maskImage(img.Image image) {
  final width = image.width;
  final height = image.height;
  final maskColor = img.ColorRgb8(0, 0, 0);

  // 右上の表
  img.fillRect(
    image,
    x1: (width * 0.41).toInt(),
    y1: (height * 0.05).toInt(),
    x2: (width * 0.88).toInt(),
    y2: (height * 0.135).toInt(),
    color: maskColor,
  );

  // フッター帯
  img.fillRect(
    image,
    x1: (width * 0.04).toInt(),
    y1: (height * 0.82).toInt(),
    x2: (width * 0.96).toInt(),
    y2: (height * 0.93).toInt(),
    color: maskColor,
  );

  return image;
}