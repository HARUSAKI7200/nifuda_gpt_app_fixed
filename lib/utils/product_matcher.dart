// lib/utils/product_matcher.dart
import 'package:flutter/foundation.dart';
import 'matching_profile.dart'; // ★ プロファイルを使用

class ProductMatcher {
  
  // ★ メインメソッド: プロファイルを受け取るように変更
  Future<Map<String, dynamic>> matchByProfile(
    List<Map<String, String>> nifudaMapList,
    List<Map<String, String>> productMapList, {
    required MatchingProfile profile,
    required String currentCaseNumber,
  }) async {
    debugPrint('=== [ProductMatcher] 照合開始 (Profile: ${profile.label}, Case: $currentCaseNumber) ===');
    debugPrint('荷札: ${nifudaMapList.length}件, 製品リスト: ${productMapList.length}件');
    
    // --- 1. 荷札データをMap化 (Key: 製番-項番) ---
    final nifudaMap = <String, Map<String, String>>{};
    for (final nifuda in nifudaMapList) {
      // 荷札側のキー項目名はアプリ標準(MatchingProfileRegistryで定義)
      final seiban = nifuda[MatchingProfileRegistry.nifudaSeiban];
      final itemNo = nifuda[MatchingProfileRegistry.nifudaItemNo];
      
      final key = _normalize(seiban) + '-' + _normalize(itemNo);
      nifudaMap[key] = nifuda;
    }
    
    // --- 2. 製品リストをループして照合 ---
    final matched = <Map<String, dynamic>>[];
    final unmatched = <Map<String, dynamic>>[];

    for (final productItem in productMapList) {
      // 製品リスト側のキー項目名はプロファイルで定義されている
      final pSeiban = productItem[profile.productListKeyOrderNo];
      final pItemNo = productItem[profile.productListKeyItemNo];

      final productKey = _normalize(pSeiban) + '-' + _normalize(pItemNo);
      
      // 対応する荷札を探す
      final Map<String, String>? potentialNifuda = nifudaMap[productKey];

      // --- 3a. 荷札なし ---
      if (potentialNifuda == null) {
        final matchedCase = productItem['照合済Case'];
        if (matchedCase == null || matchedCase.isEmpty) {
          unmatched.add({
            'nifuda': {},
            'product': productItem,
            '照合ステータス': '荷札未検出',
            '詳細': '対応する荷札 (Case: $currentCaseNumber) が見つかりませんでした。',
            '不一致項目リスト': [],
          });
        }
        continue; 
      }

      // --- 3b. 荷札あり ---
      nifudaMap.remove(productKey); // 処理済みとして削除

      // 他Caseで照合済みかチェック
      final matchedCase = productItem['照合済Case'];
      if (matchedCase != null && matchedCase.isNotEmpty) {
          if (matchedCase == currentCaseNumber) {
             matched.add({
                'nifuda': potentialNifuda,
                'product': productItem,
                '照合ステータス': '照合成功 (再)',
                '詳細': 'このCaseで既に照合済みです。',
                '不一致項目リスト': [],
             });
          } else {
             unmatched.add({
                'nifuda': potentialNifuda,
                'product': productItem,
                '照合ステータス': '重複照合スキップ',
                '詳細': 'この製品は既に「$matchedCase」で照合済みです。',
                '不一致項目リスト': [],
             });
          }
          continue;
      }

      // --- 4. 詳細比較 (プロファイルに基づく動的比較) ---
      final mismatchFields = <String>[];

      // キー項目の確認 (念のため)
      if (!_compareString(potentialNifuda[MatchingProfileRegistry.nifudaSeiban], pSeiban)) {
        mismatchFields.add('${MatchingProfileRegistry.nifudaSeiban}/${profile.productListKeyOrderNo}');
      }
      if (!_compareString(potentialNifuda[MatchingProfileRegistry.nifudaItemNo], pItemNo)) {
        mismatchFields.add('${MatchingProfileRegistry.nifudaItemNo}/${profile.productListKeyItemNo}');
      }

      // ★ プロファイルで定義されたペアを比較
      profile.comparisonPairs.forEach((nifudaKey, productKey) {
        final nVal = potentialNifuda[nifudaKey];
        final pVal = productItem[productKey];
        
        // 特殊ロジック: 品名が一致しなくても「記事」などを見る必要がある場合（T社標準など）
        bool isMatch = _compareString(nVal, pVal);
        
        // 特例: TMEICなどの場合、品名が「記事」に入っていることがある
        if (!isMatch && productKey == '品名記号' && productItem.containsKey('記事')) {
           if (_compareString(nVal, productItem['記事'])) {
             isMatch = true;
           }
        }
        // 特例: TMEIC UPSの場合、品名2も見る
        if (!isMatch && productKey == '品名1' && productItem.containsKey('品名2')) {
           if (_compareString(nVal, productItem['品名2'])) {
             isMatch = true;
           }
        }

        if (!isMatch) {
          mismatchFields.add('$nifudaKey/$productKey');
        }
      });

      if (mismatchFields.isEmpty) {
        matched.add({
          'nifuda': potentialNifuda,
          'product': productItem,
          '照合ステータス': '一致',
          '詳細': '全ての項目が一致しました',
          '不一致項目リスト': [],
        });
      } else {
        unmatched.add({
          'nifuda': potentialNifuda,
          'product': productItem,
          '照合ステータス': '不一致',
          '詳細': '${mismatchFields.join("、")}が不一致です',
          '不一致項目リスト': mismatchFields,
        });
      }
    } 

    // --- 5. 製品未検出の荷札 ---
    for (final remainingNifuda in nifudaMap.values) {
       unmatched.add({
          'nifuda': remainingNifuda,
          'product': {}, 
          '照合ステータス': '製品リスト未検出',
          '詳細': 'この荷札に対応する製品リスト項目が見つかりませんでした。',
          '不一致項目リスト': [],
       });
    }

    return {
      'matched': matched,
      'unmatched': unmatched,
      'missing': [], 
      'currentCaseNumber': currentCaseNumber,
    };
  }

  String _normalize(String? s) {
    if (s == null) return '';
    // アルファベット小文字は大文字に、記号は除去して比較
    return s.trim().toUpperCase().replaceAll(RegExp(r'[-_ /]'), '');
  }

  bool _compareString(String? s1, String? s2) {
    return _normalize(s1) == _normalize(s2);
  }
}