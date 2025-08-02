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
      final nifudaSeiban = _normalize(nifudaItem['製番']);
      final nifudaItemNumber = _normalize(nifudaItem['項目番号']);

      // 1. まず「製番」が一致する製品のグループを探す
      final productGroup = productMapList
          .where((p) => _normalize(p['ORDER No.']) == nifudaSeiban)
          .toList();

      Map<String, String> potentialMatch = {};

      if (productGroup.isNotEmpty) {
        // 2. そのグループの中から「項目番号」が一致する製品を探す
        potentialMatch = productGroup.firstWhere(
          (p) => _normalize(p['ITEM OF SPARE']) == nifudaItemNumber,
          orElse: () => {}, // 見つからなければ空のMapを返す
        );
      }

      if (potentialMatch.isEmpty) {
        // 対応する製品が見つからない荷札
        unmatched.add({
          ...nifudaItem,
          '照合ステータス': '製品未検出',
          '詳細': '製番と項目番号に一致する製品がリストにありません',
          '不一致項目リスト': [],
        });
        continue;
      }
      
      // 項目番号が一致した場合、詳細なフィールド比較
      final nifudaQuantity = _tryParseInt(nifudaItem['個数']);
      final productQuantity = _tryParseInt(potentialMatch['注文数']);
      final List<String> mismatchFields = [];
      
      // 品名の比較ロジック
      final nifudaHinmei = _normalize(nifudaItem['品名']);
      final productHinmeiKigou = _normalize(potentialMatch['品名記号']);
      final productKiji = _normalize(potentialMatch['記事']);

      if (nifudaHinmei != productHinmeiKigou && nifudaHinmei != productKiji) {
        mismatchFields.add('品名/品名記号/記事');
      }
      
      if (_normalize(nifudaItem['形式']) != _normalize(potentialMatch['形格'])) mismatchFields.add('形式/形格');
      if (nifudaQuantity != productQuantity) mismatchFields.add('個数/注文数');

      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      // ★ 修正箇所：手配コードの比較ロジックを変更
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      final nifudaTehaiCode = _normalize(nifudaItem['手配コード']);
      // 荷札に手配コードが存在する場合のみ、製品コード番号との比較を行う
      if (nifudaTehaiCode.isNotEmpty) {
        if (nifudaTehaiCode != _normalize(potentialMatch['製品コード番号'])) {
          mismatchFields.add('手配コード/製品コード番号');
        }
      }
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★

      final String productKey = _normalize(potentialMatch['ORDER No.']) + '-' + _normalize(potentialMatch['ITEM OF SPARE']);
      matchedProductKeys.add(productKey);

      if (mismatchFields.isEmpty) {
        // 完全一致
        matched.add({
          ...nifudaItem,
          ...potentialMatch.map((k, v) => MapEntry('$k(製品)', v)),
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
      'missing': missingProducts,
    };
  }

  String _normalize(String? input) {
    if (input == null) return '';
    // 記事(REMARKS)には括弧が含まれることがあるため、括弧も除去する
    return input.replaceAll(RegExp(r'[\s-()]'), '').toUpperCase();
  }

  int? _tryParseInt(String? input) {
    if (input == null) return null;
    final normalized = input.trim().replaceAllMapped(RegExp(r'[０-９]'), (m) {
      return String.fromCharCode(m.group(0)!.codeUnitAt(0) - '０'.codeUnitAt(0) + '0'.codeUnitAt(0));
    });
    return int.tryParse(normalized);
  }
}