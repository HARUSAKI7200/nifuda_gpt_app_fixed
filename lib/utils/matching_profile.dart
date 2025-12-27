// lib/utils/matching_profile.dart
import 'dart:convert';
import '../database/app_database.dart'; // MaskProfileへのアクセス

/// プロファイルの処理タイプ（特殊な番号分割ロジックなどの判定用）
enum ProfileType {
  standard,    // 標準 (共通No + 備考REMARKS)
  tmeic,       // TMEIC (共通No + 備考NOTE)
  tmeic_ups_2, // TMEIC UPS産二 (スペース分割)
  fullRow,     // 行完結型
}

/// 抽出と照合の設定を一元管理するクラス
class MatchingProfile {
  final String id;            // ID
  final String label;         // 表示名
  final String systemPrompt;  // AIへの指示（抽出プロンプト）
  final ProfileType type;     // 処理タイプ
  
  /// 製品リストの結果画面に表示する項目のリスト
  final List<String> displayFields; 

  /// 照合に使用するキー項目の定義 (製品リスト側)
  final String productListKeyOrderNo; // 「製番」に当たる項目名
  final String productListKeyItemNo;  // 「項番」に当たる項目名

  /// 【照合マッピング設定】
  /// Key: 荷札の項目名（アプリ標準）, Value: 製品リストの項目名（このリスト固有）
  /// ここに定義されたペアのみ照合判定を行う
  final Map<String, String> comparisonPairs;

  const MatchingProfile({
    required this.id,
    required this.label,
    required this.systemPrompt,
    required this.type,
    required this.displayFields,
    required this.productListKeyOrderNo,
    required this.productListKeyItemNo,
    required this.comparisonPairs,
  });
}

/// プロファイルのレジストリ（台帳）
class MatchingProfileRegistry {
  
  // 荷札の標準項目名（定数として管理）
  static const String nifudaSeiban = '製番';
  static const String nifudaItemNo = '項目番号';
  static const String nifudaHinmei = '品名';
  static const String nifudaKeishiki = '形式';
  static const String nifudaKosu = '個数';
  static const String nifudaTosho = '図書番号';
  static const String nifudaTekiyo = '摘要';
  static const String nifudaTehai = '手配コード';

  // プリセットプロファイル
  static const List<MatchingProfile> availableProfiles = [
    // 1. 標準パターン
    MatchingProfile(
      id: 'standard',
      label: '標準 (汎用)',
      type: ProfileType.standard,
      displayFields: ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '数量', '備考(REMARKS)'],
      productListKeyOrderNo: 'ORDER No.',
      productListKeyItemNo: 'ITEM OF SPARE',
      comparisonPairs: {
        nifudaHinmei: '品名記号',
        nifudaKeishiki: '形格',
        nifudaTosho: '製品コード番号',
        nifudaKosu: '数量',
        // nifudaTekiyo: '備考(REMARKS)', 
      },
      systemPrompt: _promptStandard,
    ),

    // 2. TMEIC社 (DS産) パターン
    MatchingProfile(
      id: 'tmeic',
      label: 'TMEIC DS産(中国)',
      type: ProfileType.tmeic,
      displayFields: ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考(NOTE)'],
      productListKeyOrderNo: 'ORDER No.',
      productListKeyItemNo: 'ITEM OF SPARE',
      comparisonPairs: {
        nifudaHinmei: '品名記号', // 特例: 「記事」も参照するロジックあり
        nifudaKeishiki: '形格',
        nifudaTosho: '製品コード番号',
        nifudaKosu: '注文数',
      },
      systemPrompt: _promptTmeic,
    ),

    // 3. 東芝 鉄シブ
    MatchingProfile(
      id: 'toshiba_tessibu',
      label: '東芝 鉄シブ 鉄シ産',
      type: ProfileType.fullRow,
      displayFields: ['ORDER No.', 'ITEM OF SPARE', '品名記号', '注文数'],
      productListKeyOrderNo: 'ORDER No.',
      productListKeyItemNo: 'ITEM OF SPARE',
      comparisonPairs: {
        nifudaHinmei: '品名記号',
        nifudaKosu: '注文数',
      },
      systemPrompt: _promptToshibaTessibu,
    ),

    // 4. TMEIC UPS産二
    MatchingProfile(
      id: 'tmeic_ups_2',
      label: 'TMEIC UPS産二',
      type: ProfileType.tmeic_ups_2,
      displayFields: ['製番', '項番', 'P.', '品名1', '品名2', '型式', '数量', '備考', 'No.', '摘要(項番)'],
      productListKeyOrderNo: '製番',
      productListKeyItemNo: '項番',
      comparisonPairs: {
        nifudaHinmei: '品名1', // 特例: 「品名2」も参照するロジックあり
        nifudaKeishiki: '型式',
        nifudaKosu: '数量',
        nifudaTekiyo: '備考',
      },
      systemPrompt: _promptTmeicUps2,
    ),
  ];

  static MatchingProfile getById(String? id) {
    return availableProfiles.firstWhere(
      (p) => p.id == id,
      orElse: () => availableProfiles.first,
    );
  }

  // DBのMaskProfileからMatchingProfileへ変換するヘルパー
  static MatchingProfile fromDbProfile(MaskProfile dbProfile) {
    // 1. タイプ復元
    ProfileType type = ProfileType.standard;
    if (dbProfile.extractionMode != null) {
      type = ProfileType.values.firstWhere(
        (e) => e.toString() == dbProfile.extractionMode,
        orElse: () => ProfileType.standard,
      );
    }

    // 2. 項目リスト復元
    List<String> fields = [];
    if (dbProfile.productListFieldsJson != null) {
      try {
        fields = (jsonDecode(dbProfile.productListFieldsJson!) as List).cast<String>();
      } catch (_) {}
    }
    if (fields.isEmpty) {
      // デフォルトフォールバック
      fields = ['ORDER No.', 'ITEM OF SPARE', '品名記号', '数量']; 
    }

    // 3. 照合ペア復元
    Map<String, String> pairs = {};
    if (dbProfile.matchingPairsJson != null) {
      try {
        pairs = (jsonDecode(dbProfile.matchingPairsJson!) as Map).cast<String, String>();
      } catch (_) {}
    }

    // 4. キー項目設定
    String key1 = fields.firstWhere((f) => f.contains('ORDER') || f.contains('製番'), orElse: () => fields.isNotEmpty ? fields[0] : '');
    String key2 = fields.firstWhere((f) => f.contains('ITEM') || f.contains('項番'), orElse: () => fields.length > 1 ? fields[1] : '');

    return MatchingProfile(
      id: dbProfile.id.toString(), // DB IDを文字列化
      label: dbProfile.profileName,
      systemPrompt: _buildDynamicPrompt(type, fields), // 動的プロンプト生成
      type: type,
      displayFields: fields,
      productListKeyOrderNo: key1,
      productListKeyItemNo: key2,
      comparisonPairs: pairs,
    );
  }

  // 抽出モードと項目リストからプロンプトを動的に組み立てる
  static String _buildDynamicPrompt(ProfileType type, List<String> fields) {
    final fieldsStr = fields.map((f) => '"$f"').join(', ');
    
    // ベースとなる指示はタイプによって切り替え
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

  // --- プリセットプロンプト定義 ---
  
  static const String _promptStandard = '''
あなたは製品リストを完璧に文字起こしする、データ入力の超専門家です。あなたの使命は、一文字のミスもなく、全ての文字を正確にJSON形式で出力することです。以下の思考プロセスとルールを厳守してください。

### 思考プロセス
1.  **役割認識:** あなたは単なるOCRエンジンではありません。細部まで見逃さない、熟練のデジタルアーキビストです。
2.  **一文字ずつの検証:** 文字列を読み取る際は、決して単語や文脈で推測せず、一文字ずつ丁寧になぞり、形状を特定します。
3.  **類似文字の徹底的な判別:** (O/0, Q/0, 1/l, S/5, B/8, かっこ類...)

### 抽出項目
1.  **commonOrderNo**: 画像の**右上、テーブルの外**にある共通の注文番号プレフィックス（例: `T-12345-` や `S-98765-`）を一つだけ抽出します。枝番（例: -01）の**直前のハイフンまで**を含めてください。
2.  **products**: 製品リストの各行から以下の項目を抽出します。
    - 項目が存在しない場合は空文字列 `""` としてください。
    - **「備考(REMARKS)」** 列は、枝番（例: `01`）が記載されている場合、その枝番の数字を抽出してください。
    - 対象項目リスト（各行ごと）：
      ["品名記号", "形格", "製品コード番号", "数量", "備考(REMARKS)"]

### 出力形式 (JSON)
{
  "commonOrderNo": "T-12345-",
  "products": [
    {
      "品名記号": "...",
      "形格": "...",
      "製品コード番号": "...",
      "数量": "1",
      "備考(REMARKS)": "01"
    }
  ]
}
''';

  static const String _promptTmeic = '''
あなたは「TMEIC」の製品リスト（T社帳票）を完璧に文字起こしする、データ入力の超専門家です。

### 抽出項目
1.  **commonOrderNo**: 画像の**左上、テーブルの外**にある共通の番号（例: `QZ83941 FEV2385`）のうち、**スペースの左側だけ**（例: `QZ83941`）を一つだけ抽出します。
2.  **products**: 製品リストの各行から以下の項目を抽出します。
    - **「備考(NOTE)」** 列（例: `FEV2385`）の値を正確に抽出してください。
    - 対象項目リスト（各行ごと）：
      ["ITEM OF SPARE", "品名記号", "形格", "製品コード番号", "注文数", "記事", "備考(NOTE)"]

### 出力形式 (JSON)
{
  "commonOrderNo": "QZ83941",
  "products": [
    {
      "ITEM OF SPARE": "021",
      "品名記号": "...",
      "形格": "...",
      "製品コード番号": "...",
      "注文数": "...",
      "記事": "...",
      "備考(NOTE)": "FEV2385" 
    }
  ]
}
''';

  static const String _promptToshibaTessibu = '''
あなたは製品リストを完璧に文字起こしする、データ入力の超専門家です。

### 思考プロセス
1.  **O/#列の分解:** 「O/#」列には「製番」と「項番」がスペースで区切られて記載されています（例: "5605578 DJ0001B"）。これを必ず「製番」と「項番」に分割して抽出してください。
2.  **項目マッピング:**
    - `O/#` の左側 -> `"ORDER No."`
    - `O/#` の右側 -> `"ITEM OF SPARE"`
    - `品名/型名` -> `"品名記号"`
    - `数量` -> `"注文数"` (単位「台」などは除き、数値のみ)

### 出力形式 (JSON)
{
  "commonOrderNo": "",
  "products": [
    {
      "ORDER No.": "5605578",
      "ITEM OF SPARE": "DJ0001B",
      "品名記号": "...",
      "注文数": "2"
    }
  ]
}
''';

  static const String _promptTmeicUps2 = '''
あなたは「TMEIC」の製品リスト（出荷品リスト）を完璧に文字起こしする、データ入力の超専門家です。

### 抽出項目
1.  **commonOrderNo**: 画像の**左上**にある「製番:」の右側に記載された文字列を、そのまま抽出します。
    - 例: `7M16287 VPV0001/VPV0002` の場合、スペースやスラッシュを含めて全て抽出してください。
2.  **products**: 製品リストの表から各行の以下の項目を抽出します。
    - 対象項目リスト（各行ごと）：
      ["P.", "品名1", "品名2", "型式", "数量", "備考", "No.", "摘要(項番)"]

### 出力形式 (JSON)
{
  "commonOrderNo": "7M16287 VPV0001/VPV0002",
  "products": [
    {
      "P.": "1",
      "品名1": "...",
      "品名2": "...",
      "型式": "...",
      "数量": "1",
      "備考": "",
      "No.": "1",
      "摘要(項番)": ""
    }
  ]
}
''';
}