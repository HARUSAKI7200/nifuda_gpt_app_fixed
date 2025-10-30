// lib/utils/product_matcher.dart
import 'package:flutter/foundation.dart';
import '../database/app_database.dart'; // ★ DB操作のために追加
import 'package:drift/drift.dart'; // ★ Driftのために追加

class ProductMatcher {
  
  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  // ★ 変更点：match関数に currentCaseNumber を追加し、非同期化
  // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
  Future<Map<String, dynamic>> match( // ★ Future<Map> に変更
    List<Map<String, String>> nifudaMapList,
    List<Map<String, String>> productMapList, {
    String pattern = 'T社（製番・項目番号）',
    required String currentCaseNumber, // ★ 追加
  }) async { // ★ async に変更
    debugPrint('=== [ProductMatcher] 照合開始 (パターン: $pattern, Case: $currentCaseNumber) ===');
    debugPrint('荷札: ${nifudaMapList.length}件, 製品リスト: ${productMapList.length}件');
    
    // パターンに応じて呼び出すロジックを分岐
    switch (pattern) {
      case 'T社（製番・項目番号）':
        return await _matchForTCompany(nifudaMapList, productMapList, currentCaseNumber); // ★ await/Case No.追加
      case '汎用（図書番号優先）':
        return await _matchGeneralPurpose(nifudaMapList, productMapList, currentCaseNumber); // ★ await/Case No.追加
      default:
        return await _matchForTCompany(nifudaMapList, productMapList, currentCaseNumber); // ★ await/Case No.追加
    }
  }

  // 照合処理 T社（製番・項目番号）
  Future<Map<String, dynamic>> _matchForTCompany(
      List<Map<String, String>> nifudaMapList, 
      List<Map<String, String>> productMapList,
      String currentCaseNumber, // ★ 追加
      ) async {
    
    // 照合キーの準備
    final productMap = <String, Map<String, String>>{};
    final alreadyMatchedKeys = <String>{}; // 他のCaseで照合済みのキー

    for (final product in productMapList) {
      // 製品リストの照合キー
      final key = _normalize(product['ORDER No.']) + '-' + _normalize(product['ITEM OF SPARE']);
      productMap[key] = product;
      
      // 製品リストの最終列 ('照合済Case') を確認
      final matchedCase = product['照合済Case'];
      // 現在のCase No.以外のCase No.で照合済みの場合は、このCaseでの照合対象から除外 (3-3)
      if (matchedCase != null && matchedCase.isNotEmpty && matchedCase != currentCaseNumber) {
        alreadyMatchedKeys.add(key);
      }
    }

    final matched = <Map<String, dynamic>>[];
    final unmatched = <Map<String, dynamic>>[];
    final matchedProductKeys = <String>{}; // このCaseで照合成功したキー

    for (final nifudaItem in nifudaMapList) {
      // 荷札の照合キー
      final nifudaKey = _normalize(nifudaItem['製番']) + '-' + _normalize(nifudaItem['項目番号']);
      final potentialMatch = productMap[nifudaKey];

      if (potentialMatch != null) {
        final productKey = nifudaKey; // このパターンでは荷札キーと製品キーは一致
        
        // 既に他のケースで照合済みならスキップ (unmatchedに追加)
        if (alreadyMatchedKeys.contains(productKey)) {
          unmatched.add({
              'nifuda': nifudaItem,
              'product': potentialMatch,
              '照合ステータス': '重複照合スキップ',
              '詳細': 'この製品は既に${potentialMatch['照合済Case']}で照合済みです。',
              '不一致項目リスト': [],
          });
          continue;
        }

        // 照合済みマークが現在のCase No.なら、既に照合成功として処理済み
        if (potentialMatch['照合済Case'] == currentCaseNumber) {
             matched.add({
              'nifuda': nifudaItem,
              'product': potentialMatch,
              '照合ステータス': '照合成功 (再)',
              '詳細': 'このCaseで既に照合済みです。',
              '不一致項目リスト': [],
          });
             matchedProductKeys.add(productKey);
             continue;
        }

        // 未照合または現在のCase No.で照合試行
        final mismatchFields = <String>[];
        // 必須項目の比較
        if (!_compareString(nifudaItem['製番'], potentialMatch['ORDER No.'])) {
          mismatchFields.add('製番/ORDER No.');
        }
        if (!_compareString(nifudaItem['品名'], potentialMatch['品名記号'])) {
          mismatchFields.add('品名/品名記号');
        }
        if (!_compareString(nifudaItem['形式'], potentialMatch['形格'])) {
          mismatchFields.add('形式/形格');
        }
        // ... (他の比較ロジックを追加する場合はここに記述)

        if (mismatchFields.isEmpty) {
          // 照合成功
          matched.add({
            'nifuda': nifudaItem,
            'product': potentialMatch,
            '照合ステータス': '一致',
            '詳細': '全ての項目が一致しました',
            '不一致項目リスト': [],
          });
          matchedProductKeys.add(productKey); // 成功したキーをマーク
          
        } else {
          // 項目不一致
          unmatched.add({
            'nifuda': nifudaItem,
            'product': potentialMatch,
            '照合ステータス': '不一致',
            '詳細': '${mismatchFields.join("、")}が不一致です',
            '不一致項目リスト': mismatchFields,
          });
        }
      } else {
        // 製品リスト未検出
        unmatched.add({
          'nifuda': nifudaItem,
          'product': {},
          '照合ステータス': '製品リスト未検出',
          '詳細': '照合キー（製番・項目番号）に一致する製品リストが見つかりませんでした',
        });
      }
    }

    // 荷札未検出の製品リスト項目
    final missingProducts = productMapList.where((product) {
        final key = _normalize(product['ORDER No.']) + '-' + _normalize(product['ITEM OF SPARE']);
        // 照合成功したキーに含まれておらず、かつ他のCaseでも照合済みでないもの
        return !matchedProductKeys.contains(key) && product['照合済Case'] != currentCaseNumber; 
    }).map((p) => { 
        'nifuda': {},
        'product': p,
        '照合ステータス': '荷札未検出', 
        '詳細': '対応する荷札が見つかりませんでした (Case: ${p['照合済Case'] ?? '未照合'})' 
    }).toList();

    unmatched.addAll(missingProducts.cast<Map<String, dynamic>>());

    debugPrint('照合完了: 一致 ${matched.length}, 不一致/未検出 ${unmatched.length}');
    return {
      'matched': matched,
      'unmatched': unmatched,
      'missing': missingProducts,
      'currentCaseNumber': currentCaseNumber, // 照合に使用したCase No.を返す
    };
  }

  // 照合処理 汎用（図書番号優先）
  Future<Map<String, dynamic>> _matchGeneralPurpose(
      List<Map<String, String>> nifudaMapList, 
      List<Map<String, String>> productMapList,
      String currentCaseNumber, // ★ 追加
      ) async {
    // 汎用ロジックの実装（T社ロジックを流用）
    return _matchForTCompany(nifudaMapList, productMapList, currentCaseNumber);
  }


  // 共通のヘルパー関数（変更なし）
  String _normalize(String? s) {
    if (s == null) return '';
    return s.trim().toUpperCase().replaceAll(RegExp(r'[-_ ]'), '');
  }

  bool _compareString(String? s1, String? s2) {
    return _normalize(s1) == _normalize(s2);
  }
}