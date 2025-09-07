// lib/utils/product_matcher.dart
import 'package:flutter/foundation.dart';
// custom_snackbar.dartはここでは直接使用しないためインポートなし

class ProductMatcher {
  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  // ★ 変更点：match関数をロジックのルーター（振り分け役）に変更
  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  Map<String, dynamic> match(
    List<Map<String, String>> nifudaMapList,
    List<Map<String, String>> productMapList, {
    String pattern = 'T社（製番・項目番号）', // 引数を company から pattern に変更
  }) {
    debugPrint('=== [ProductMatcher] 照合開始 (パターン: $pattern) ===');
    debugPrint('荷札: ${nifudaMapList.length}件, 製品リスト: ${productMapList.length}件');
    
    // パターンに応じて呼び出すロジックを分岐
    switch (pattern) {
      case 'T社（製番・項目番号）':
        return _matchForTCompany(nifudaMapList, productMapList);
      case '汎用（図書番号優先）':
        return _matchGeneralPurpose(nifudaMapList, productMapList);
      default:
        // 未知のパターンが来た場合は、デフォルトのロジック（T社）を実行
        return _matchForTCompany(nifudaMapList, productMapList);
    }
  }

  // T社向けの既存ロジック（変更なし）
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

      final productGroup = productMapList
          .where((p) => _normalize(p['ORDER No.']) == nifudaSeiban)
          .toList();

      Map<String, String> potentialMatch = {};

      if (productGroup.isNotEmpty) {
        potentialMatch = productGroup.firstWhere(
          (p) => _normalize(p['ITEM OF SPARE']) == nifudaItemNumber,
          orElse: () => {},
        );
      }

      if (potentialMatch.isEmpty) {
        unmatched.add({
          ...nifudaItem,
          '照合ステータス': '製品未検出',
          '詳細': '製番と項目番号に一致する製品がリストにありません',
          '不一致項目リスト': [],
        });
        continue;
      }
      
      final nifudaQuantity = _tryParseInt(nifudaItem['個数']);
      final productQuantity = _tryParseInt(potentialMatch['注文数']);
      final List<String> mismatchFields = [];
      
      final nifudaHinmei = _normalize(nifudaItem['品名']);
      final productHinmeiKigou = _normalize(potentialMatch['品名記号']);
      final productKiji = _normalize(potentialMatch['記事']);

      if (nifudaHinmei != productHinmeiKigou && nifudaHinmei != productKiji) {
        mismatchFields.add('品名/品名記号/記事');
      }
      
      if (_normalize(nifudaItem['形式']) != _normalize(potentialMatch['形格'])) mismatchFields.add('形式/形格');
      if (nifudaQuantity != productQuantity) mismatchFields.add('個数/注文数');
      
      final nifudaTehaiCode = _normalize(nifudaItem['手配コード']);
      if (nifudaTehaiCode.isNotEmpty) {
        if (nifudaTehaiCode != _normalize(potentialMatch['製品コード番号'])) {
          mismatchFields.add('手配コード/製品コード番号');
        }
      }

      final String productKey = _normalize(potentialMatch['ORDER No.']) + '-' + _normalize(potentialMatch['ITEM OF SPARE']);
      matchedProductKeys.add(productKey);

      if (mismatchFields.isEmpty) {
        matched.add({
          ...nifudaItem,
          ...potentialMatch.map((k, v) => MapEntry('$k(製品)', v)),
          '照合ステータス': '一致',
          '詳細': '全ての項目が一致しました',
          '不一致項目リスト': [],
        });
      } else {
        unmatched.add({
          ...nifudaItem,
          ...potentialMatch.map((k, v) => MapEntry('$k(製品)', v)),
          '照合ステータス': '不一致',
          '詳細': '${mismatchFields.join("、")}が不一致です',
          '不一致項目リスト': mismatchFields,
        });
      }
    }

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

  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  // ★ 機能追加：新しい照合ロジック「汎用（図書番号優先）」
  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  Map<String, dynamic> _matchGeneralPurpose(
    List<Map<String, String>> nifudaMapList,
    List<Map<String, String>> productMapList,
  ) {
    final matched = <Map<String, dynamic>>[];
    final unmatched = <Map<String, dynamic>>[];
    final Set<String> matchedProductKeys = {};

    for (final nifudaItem in nifudaMapList) {
      final nifudaZusho = _normalize(nifudaItem['図書番号']);

      Map<String, String> potentialMatch = {};

      if (nifudaZusho.isNotEmpty) {
        // 主要キーとして「図書番号」と「製品コード番号」を比較
        potentialMatch = productMapList.firstWhere(
          (p) => _normalize(p['製品コード番号']) == nifudaZusho,
          orElse: () => {},
        );
      }

      if (potentialMatch.isEmpty) {
        unmatched.add({
          ...nifudaItem,
          '照合ステータス': '製品未検出',
          '詳細': '図書番号に一致する製品がリストにありません',
          '不一致項目リスト': [],
        });
        continue;
      }

      // 詳細比較（こちらはT社ロジックを流用）
      final nifudaQuantity = _tryParseInt(nifudaItem['個数']);
      final productQuantity = _tryParseInt(potentialMatch['注文数']);
      final List<String> mismatchFields = [];

      if (_normalize(nifudaItem['形式']) != _normalize(potentialMatch['形格'])) mismatchFields.add('形式/形格');
      if (nifudaQuantity != productQuantity) mismatchFields.add('個数/注文数');
      
      // このロジックでは「製番/ORDER No.」も不一致項目としてチェック
      if (_normalize(nifudaItem['製番']) != _normalize(potentialMatch['ORDER No.'])) {
          mismatchFields.add('製番/ORDER No.');
      }

      final String productKey = _normalize(potentialMatch['ORDER No.']) + '-' + _normalize(potentialMatch['ITEM OF SPARE']);
      matchedProductKeys.add(productKey);

      if (mismatchFields.isEmpty) {
        matched.add({
          ...nifudaItem,
          ...potentialMatch.map((k, v) => MapEntry('$k(製品)', v)),
          '照合ステータス': '一致',
          '詳細': '全ての項目が一致しました',

          '不一致項目リスト': [],
        });
      } else {
        unmatched.add({
          ...nifudaItem,
          ...potentialMatch.map((k, v) => MapEntry('$k(製品)', v)),
          '照合ステータス': '不一致',
          '詳細': '${mismatchFields.join("、")}が不一致です',
          '不一致項目リスト': mismatchFields,
        });
      }
    }

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


  // 共通のヘルパー関数（変更なし）
  String _normalize(String? input) {
    if (input == null) return '';
    return input.replaceAll(RegExp(r'[\s()]'), '').toUpperCase();
  }

  int? _tryParseInt(String? input) {
    if (input == null) return null;
    final normalized = input.trim().replaceAllMapped(RegExp(r'[０-９]'), (m) {
      return String.fromCharCode(m.group(0)!.codeUnitAt(0) - '０'.codeUnitAt(0) + '0'.codeUnitAt(0));
    });
    return int.tryParse(normalized);
  }
}