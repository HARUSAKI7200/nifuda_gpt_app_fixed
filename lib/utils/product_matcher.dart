import 'package:flutter/foundation.dart';
// custom_snackbar.dartはここでは直接使用しないためインポートなし

class ProductMatcher {
  Map<String, dynamic> match(
    List<Map<String, String>> nifudaMapList,
    List<Map<String, String>> productMapList, {
    String company = 'T社', // 将来的な分岐のため
  }) {
    debugPrint('=== [ProductMatcher] 照合開始 (対象: $company) ===');
    debugPrint('荷札: ${nifudaMapList.length}件, 製品リスト: ${productMapList.length}件');
    
    // 会社ごとのロジック分岐（現在はT社のみ）
    if (company == 'T社') {
      return _matchForTCompany(nifudaMapList, productMapList);
    } else {
      // 汎用ロジック（T社と同じものをフォールバックとして使用）
      return _matchForTCompany(nifudaMapList, productMapList);
    }
  }

  Map<String, dynamic> _matchForTCompany(
    List<Map<String, String>> nifudaMapList,
    List<Map<String, String>> productMapList,
  ) {
    final matched = <Map<String, dynamic>>[];
    final unmatched = <Map<String, dynamic>>[];
    final Set<String> matchedProductKeys = {};

    for (final nifudaItem in nifudaMapList) {
      final nifudaItemNumber = _normalize(nifudaItem['項目番号']);
      
      // 項目番号が同じ製品リストのアイテムを検索
      final potentialMatch = productMapList.firstWhere(
        (p) => _normalize(p['ITEM OF SPARE']) == nifudaItemNumber,
        orElse: () => <String, String>{},
      );

      if (potentialMatch.isEmpty) {
        // 対応する製品が見つからない荷札
        unmatched.add({
          ...nifudaItem,
          '照合ステータス': '製品未検出',
          '詳細': '対応するITEM OF SPAAREが製品リストにありません',
          '不一致項目リスト': [],
        });
        continue;
      }
      
      // 項目番号が一致した場合、詳細なフィールド比較
      final nifudaQuantity = _tryParseInt(nifudaItem['個数']);
      final productQuantity = _tryParseInt(potentialMatch['注文数']);
      final List<String> mismatchFields = [];
      
      // 比較ロジック
      if (_normalize(nifudaItem['製番']) != _normalize(potentialMatch['ORDER No.'])) mismatchFields.add('製番/ORDER No.');
      if (_normalize(nifudaItem['品名']) != _normalize(potentialMatch['品名記号'])) mismatchFields.add('品名/品名記号');
      if (_normalize(nifudaItem['形式']) != _normalize(potentialMatch['形格'])) mismatchFields.add('形式/形格');
      if (nifudaQuantity != productQuantity) mismatchFields.add('個数/注文数');
      if (_normalize(nifudaItem['手配コード']) != _normalize(potentialMatch['製品コード番号'])) mismatchFields.add('手配コード/製品コード番号');

      final String productKey = _normalize(potentialMatch['ORDER No.']) + '-' + _normalize(potentialMatch['ITEM OF SPARE']);
      matchedProductKeys.add(productKey);

      if (mismatchFields.isEmpty) {
        // 完全一致
        matched.add({
          ...nifudaItem,
          ...potentialMatch.map((k, v) => MapEntry('$k(製品)', v)), // 製品リスト側のデータを別名で追加
          '照合ステータス': '一致',
          '詳細': '全ての項目が一致しました',
          '不一致項目リスト': [],
        });
      } else {
        // 部分不一致
        unmatched.add({
          ...nifudaItem,
          ...potentialMatch.map((k, v) => MapEntry('$k(製品)', v)),
          '照合ステータス': '不一致',
          '詳細': '${mismatchFields.join("、")}が不一致です',
          '不一致項目リスト': mismatchFields,
        });
      }
    }

    // どの荷札とも紐付かなかった製品リストのアイテム
    final missingProducts = productMapList.where((product) {
        final key = _normalize(product['ORDER No.']) + '-' + _normalize(product['ITEM OF SPARE']);
        return !matchedProductKeys.contains(key);
    }).map((p) => { ...p, '照合ステータス': '荷札未検出', '詳細': '対応する荷札が見つかりませんでした' }).toList();

    unmatched.addAll(missingProducts.cast<Map<String, dynamic>>());

    debugPrint('照合完了: 一致 ${matched.length}, 不一致/未検出 ${unmatched.length}');
    return {
      'matched': matched,
      'unmatched': unmatched,
      'missing': missingProducts, // missingはunmatchedに含めたが、個別にも返す
    };
  }

  String _normalize(String? input) {
    if (input == null) return '';
    return input.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  }

  int? _tryParseInt(String? input) {
    if (input == null) return null;
    final normalized = input.trim().replaceAllMapped(RegExp(r'[０-９]'), (m) {
      return String.fromCharCode(m.group(0)!.codeUnitAt(0) - '０'.codeUnitAt(0) + '0'.codeUnitAt(0));
    });
    return int.tryParse(normalized);
  }
}