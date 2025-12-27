// lib/utils/matching_profile.dart
import 'dart:convert';
import '../database/app_database.dart'; // MaskProfileへのアクセス

/// プロファイルの処理タイプ（特殊な番号分割ロジックなどの判定用）
enum ProfileType {
  standard,    // 標準 (汎用)
  tmeic,       // TMEIC DS産
  tmeic_ups_2, // TMEIC UPS産二
  fullRow,     // 東芝 鉄シブ・鉄シ産
}

/// 抽出と照合の設定を一元管理するクラス
class MatchingProfile {
  final String id;            // ID
  final String label;         // 表示名
  final String systemPrompt;  // AIへの指示（製品リスト用）
  final ProfileType type;     // 処理タイプ
  
  /// 製品リストの結果画面に表示する項目のリスト
  final List<String> displayFields; 

  /// ★ 追加: 荷札の項目リスト（OCR結果のキーにも使用）
  final List<String> nifudaFields;

  /// 照合に使用するキー項目の定義 (製品リスト側)
  final String productListKeyOrderNo; // 「製番」に当たる項目名
  final String productListKeyItemNo;  // 「項番」に当たる項目名

  /// 【照合マッピング設定】
  /// Key: 荷札の項目名, Value: 製品リストの項目名
  final Map<String, String> comparisonPairs;

  const MatchingProfile({
    required this.id,
    required this.label,
    required this.systemPrompt,
    required this.type,
    required this.displayFields,
    required this.nifudaFields,
    required this.productListKeyOrderNo,
    required this.productListKeyItemNo,
    required this.comparisonPairs,
  });
}

/// プロファイルのレジストリ（台帳）
class MatchingProfileRegistry {
  
  // デフォルトの荷札項目（変更可能）
  static const List<String> defaultNifudaFields = [
    '製番', '項目番号', '品名', '形式', '個数', '図書番号', '手配コード', '摘要'
  ];

  // プリセット
  static const List<MatchingProfile> availableProfiles = [
    // 1. 標準パターン
    MatchingProfile(
      id: 'standard',
      label: '標準 (汎用)',
      type: ProfileType.standard,
      displayFields: ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '数量', '備考(REMARKS)'],
      nifudaFields: defaultNifudaFields,
      productListKeyOrderNo: 'ORDER No.',
      productListKeyItemNo: 'ITEM OF SPARE',
      comparisonPairs: {
        '品名': '品名記号',
        '形式': '形格',
        '図書番号': '製品コード番号',
        '個数': '数量',
      },
      systemPrompt: _promptStandard,
    ),
  ];

  static MatchingProfile getById(String? id) {
    return availableProfiles.firstWhere(
      (p) => p.id == id,
      orElse: () => availableProfiles.first,
    );
  }

  // DBのMaskProfileからMatchingProfileへ変換
  static MatchingProfile fromDbProfile(MaskProfile dbProfile) {
    // 1. タイプ復元
    ProfileType type = ProfileType.standard;
    if (dbProfile.extractionMode != null) {
      type = ProfileType.values.firstWhere(
        (e) => e.toString() == dbProfile.extractionMode,
        orElse: () => ProfileType.standard,
      );
    }

    // 2. 製品リスト項目
    List<String> productFields = [];
    if (dbProfile.productListFieldsJson != null) {
      try {
        productFields = (jsonDecode(dbProfile.productListFieldsJson!) as List).cast<String>();
      } catch (_) {}
    }
    if (productFields.isEmpty) {
      productFields = ['ORDER No.', 'ITEM OF SPARE', '品名記号', '数量']; 
    }

    // ★ 3. 荷札項目 (新規追加)
    List<String> nifudaFields = [];
    if (dbProfile.nifudaFieldsJson != null) {
      try {
        nifudaFields = (jsonDecode(dbProfile.nifudaFieldsJson!) as List).cast<String>();
      } catch (_) {}
    }
    if (nifudaFields.isEmpty) {
      nifudaFields = List.from(defaultNifudaFields);
    }

    // 4. 照合ペア
    Map<String, String> pairs = {};
    if (dbProfile.matchingPairsJson != null) {
      try {
        pairs = (jsonDecode(dbProfile.matchingPairsJson!) as Map).cast<String, String>();
      } catch (_) {}
    }

    // 5. キー項目 (簡易ロジック)
    String key1 = productFields.firstWhere((f) => f.contains('ORDER') || f.contains('製番'), orElse: () => productFields.isNotEmpty ? productFields[0] : '');
    String key2 = productFields.firstWhere((f) => f.contains('ITEM') || f.contains('項番'), orElse: () => productFields.length > 1 ? productFields[1] : '');

    return MatchingProfile(
      id: dbProfile.id.toString(),
      label: dbProfile.profileName,
      systemPrompt: _buildDynamicPrompt(type, productFields), 
      type: type,
      displayFields: productFields,
      nifudaFields: nifudaFields, // ★ セット
      productListKeyOrderNo: key1,
      productListKeyItemNo: key2,
      comparisonPairs: pairs,
    );
  }

  // プロンプト生成 (製品リスト用)
  static String _buildDynamicPrompt(ProfileType type, List<String> fields) {
    final fieldsStr = fields.map((f) => '"$f"').join(', ');
    String baseInstructions = "";
    String extractionLogic = "";

    switch (type) {
      case ProfileType.tmeic:
        baseInstructions = "あなたはTMEICの製品リストを処理する専門家です。";
        extractionLogic = "左上の共通番号（スペース左側）を `commonOrderNo` とし、各行の情報を抽出してください。";
        break;
      case ProfileType.tmeic_ups_2:
        baseInstructions = "あなたはTMEICの出荷品リストを処理する専門家です。";
        extractionLogic = "左上の「製番:」右側の文字列（スペース含む）を `commonOrderNo` とし、各行の情報を抽出してください。";
        break;
      case ProfileType.fullRow:
        baseInstructions = "あなたは製品リストを処理する専門家です。";
        extractionLogic = "表の中に製番・項番が含まれています。各行から情報を抽出してください。 `commonOrderNo` は空文字で構いません。";
        break;
      case ProfileType.standard:
      default:
        baseInstructions = "あなたは製品リストを処理する専門家です。";
        extractionLogic = "右上の共通番号を `commonOrderNo` とし、各行の情報を抽出してください。";
        break;
    }

    return '''
$baseInstructions
以下の項目を抽出してJSON形式で出力してください。

### 対象項目リスト
$fieldsStr

### 抽出ルール
- $extractionLogic
- 項目が存在しない場合は空文字 `""` としてください。

### 出力形式 (JSON)
{
  "commonOrderNo": "...",
  "products": [
    {
      // ここに抽出した項目をキーとして値を入れてください
    }
  ]
}
''';
  }

  // プリセット用プロンプト (Standard)
  static const String _promptStandard = '''
あなたは製品リストを完璧に文字起こしする、データ入力の超専門家です。
### 抽出項目
1.  **commonOrderNo**: 画像の**右上、テーブルの外**にある共通の注文番号プレフィックス。
2.  **products**: 製品リストの各行から以下の項目を抽出します。
    - 対象項目リスト（各行ごと）：
      ["品名記号", "形格", "製品コード番号", "数量", "備考(REMARKS)"]
### 出力形式 (JSON)
{
  "commonOrderNo": "...",
  "products": [...]
}
''';
}