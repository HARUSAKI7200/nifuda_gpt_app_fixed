// lib/utils/document_scanner_util.dart
import 'dart:math';
import 'dart:typed_data';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class DocumentScannerUtil {
  /// UI描画用に正規化された座標(0.0~1.0)を返す
  static Future<List<Point<double>>?> detectContourNormalized(Uint8List bytes, int width, int height) async {
    final src = cv.imdecode(bytes, cv.IMREAD_COLOR);
    if (src.isEmpty) return null;

    try {
      // 1. 前処理
      final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final edges = cv.canny(blurred, 75, 200);

      // 2. 輪郭検出
      final (contours, _) = cv.findContours(
        edges,
        cv.RETR_LIST,
        cv.CHAIN_APPROX_SIMPLE,
      );

      // 3. 面積順ソート (VecVecPointをDartのListに変換してソート)
      final List<cv.VecPoint> contoursList = [];
      for (int i = 0; i < contours.length; i++) {
        contoursList.add(contours[i]);
      }
      contoursList.sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

      // 4. 四角形を探す
      for (final c in contoursList) {
        final peri = cv.arcLength(c, true);
        final approx = cv.approxPolyDP(c, 0.02 * peri, true);

        if (approx.length == 4 && cv.contourArea(approx) > 1000) {
          // 頂点を取得してソート
          final points = <cv.Point>[];
          for (var i = 0; i < approx.length; i++) {
             points.add(approx[i]);
          }
          final sorted = _sortPoints(points);
          
          // 画像サイズで割って 0.0~1.0 に正規化
          // (OpenCVのMatは cols=width, rows=height)
          return sorted.map((p) => Point<double>(p.x / src.cols, p.y / src.rows)).toList();
        }
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      src.dispose();
    }
  }

  /// バイトデータから輪郭（4点）を検出する (高画質画像用)
  static Future<List<cv.Point>?> detectContour(Uint8List bytes) async {
    final src = cv.imdecode(bytes, cv.IMREAD_COLOR);
    if (src.isEmpty) return null;

    try {
      final gray = cv.cvtColor(src, cv.COLOR_BGR2GRAY);
      final blurred = cv.gaussianBlur(gray, (5, 5), 0);
      final edges = cv.canny(blurred, 75, 200);

      final (contours, _) = cv.findContours(edges, cv.RETR_LIST, cv.CHAIN_APPROX_SIMPLE);

      final List<cv.VecPoint> contoursList = [];
      for (int i = 0; i < contours.length; i++) {
        contoursList.add(contours[i]);
      }
      contoursList.sort((a, b) => cv.contourArea(b).compareTo(cv.contourArea(a)));

      for (final c in contoursList) {
        final peri = cv.arcLength(c, true);
        final approx = cv.approxPolyDP(c, 0.02 * peri, true);

        if (approx.length == 4 && cv.contourArea(approx) > 5000) {
          final points = <cv.Point>[];
          for (var i = 0; i < approx.length; i++) {
             points.add(approx[i]);
          }
          return _sortPoints(points);
        }
      }
      return null;
    } catch (e) {
      print('Detect Contour Error: $e');
      return null;
    } finally {
      src.dispose();
    }
  }

  /// 透視変換（台形補正）
  static Future<Uint8List?> perspectiveTransform(Uint8List originalBytes, List<cv.Point> points) async {
    final src = cv.imdecode(originalBytes, cv.IMREAD_COLOR);
    if (src.isEmpty) return null;

    try {
      if (points.length != 4) return null;
      final sortedPoints = _sortPoints(points);

      final tl = sortedPoints[0];
      final tr = sortedPoints[1];
      final br = sortedPoints[2];
      final bl = sortedPoints[3];

      // 幅・高さ計算
      final widthA = sqrt(pow(br.x - bl.x, 2) + pow(br.y - bl.y, 2));
      final widthB = sqrt(pow(tr.x - tl.x, 2) + pow(tr.y - tl.y, 2));
      final maxWidth = max(widthA, widthB).toInt();

      final heightA = sqrt(pow(tr.x - br.x, 2) + pow(tr.y - br.y, 2));
      final heightB = sqrt(pow(tl.x - bl.x, 2) + pow(tl.y - bl.y, 2));
      final maxHeight = max(heightA, heightB).toInt();

      // 変換元 (VecPoint)
      final srcVec = cv.VecPoint.fromList([tl, tr, br, bl]);
      
      // 変換先 (VecPoint)
      final dstVec = cv.VecPoint.fromList([
        cv.Point(0, 0),
        cv.Point(maxWidth - 1, 0),
        cv.Point(maxWidth - 1, maxHeight - 1),
        cv.Point(0, maxHeight - 1),
      ]);

      final matrix = cv.getPerspectiveTransform(srcVec, dstVec);
      final warped = cv.warpPerspective(src, matrix, (maxWidth, maxHeight));

      final encoded = cv.imencode(".jpg", warped);
      // DartCV 1.4.5のimencodeは (bool, Uint8List) を返す
      if (encoded.$1) {
        return encoded.$2;
      }
      return null;

    } catch (e) {
      print('Perspective Transform Error: $e');
      return null;
    } finally {
      src.dispose();
    }
  }

  static List<cv.Point> _sortPoints(List<cv.Point> pts) {
    // Y座標でソート
    pts.sort((a, b) => a.y.compareTo(b.y));
    final top = pts.sublist(0, 2);
    final bottom = pts.sublist(2, 4);

    // 上部をX座標でソート (左上, 右上)
    top.sort((a, b) => a.x.compareTo(b.x));
    final tl = top[0];
    final tr = top[1];

    // 下部をX座標でソート (左下, 右下)
    bottom.sort((a, b) => a.x.compareTo(b.x));
    final bl = bottom[0];
    final br = bottom[1];

    // 順序: 左上, 右上, 右下, 左下 (OpenCVのgetPerspectiveTransformの期待順序に合わせる)
    return [tl, tr, br, bl];
  }
}