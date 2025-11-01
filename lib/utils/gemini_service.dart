// lib/utils/gemini_service.dart
//
// 修正方針：
// - プロンプト/ユーティリティは、共通化が拒否されたためファイル内で定義を継続
// - ProductList抽出はストリーミング (generateContentStream) に変更
// ★ TMEIC社のプロンプトを「commonOrderNoは左側のみ」「productsは備考(NOTE)」に修正。
// ★ T社以外のプロンプトを「備考(REMARKS)」を使用するよう修正。
// ★ (Gemini) 荷札用の非ストリーミング関数 `sendImageToGemini` を追加。
// ★ (Gemini) 存在しないモデル 'gemini-2.5-flash' を 'gemini-1.5-flash' に修正。

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:http/http.dart' as http; 
import 'package:google_generative_ai/google_generative_ai.dart'; 

const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
// ★ 修正: gemini-2.5-flash は存在しないため gemini-1.5-flash に変更
const modelName = 'gemini-2.5-flash';

// --- Local Helper Functions (Duplicated for consistency) ---

// Uint8ListからMIMEタイプを推定する (重複)
String _guessMimeType(Uint8List imageBytes) {
  String mime = 'image/jpeg';
  if (imageBytes.lengthInBytes >= 12) {
    if (imageBytes[0] == 0x89 && imageBytes[1] == 0x50 && imageBytes[2] == 0x4E && imageBytes[3] == 0x47) {
      mime = 'image/png';
    } else if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
      mime = 'image/jpeg';
    } else if (imageBytes[0] == 0x52 && imageBytes[1] == 0x49 && imageBytes[2] == 0x46 && imageBytes[3] == 0x46 && imageBytes[8] == 0x57 && imageBytes[9] == 0x45 && imageBytes[10] == 0x42 && imageBytes[11] == 0x50) {
      mime = 'image/webp';
    } else if (imageBytes[0] == 0x47 && imageBytes[1] == 0x49 && imageBytes[2] == 0x46 && imageBytes[3] == 0x38) {
      mime = 'image/gif';
    } else if (imageBytes[0] == 0x42 && imageBytes[1] == 0x4D) {
      mime = 'image/bmp';
    }
  }
  return mime;
}

// コードフェンス除去（```json ... ``` → 素のJSON） (重複)
String _stripCodeFences(String s) {
  final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$', multiLine: true);
  final m = fence.firstMatch(s.trim());
  if (m != null && m.groupCount >= 1) {
    return m.group(1) ?? s;
  }
  return s;
}

// 荷札（Nifuda）抽出プロンプト (重複)
String _buildNifudaPrompt() {
  return '''
あなたは、かすれたり不鮮明な荷札の画像を完璧に文字起こしする、データ入力の超専門家です。あなたの使命は、一文字のミスもなく、全ての文字を正確にJSON形式で出力することです。以下の思考プロセスとルールを厳守してください。

### 思考プロセス
1.  **役割認識:** あなたは単なるOCRエンジンではありません。細部まで見逃さない、熟練のデジタルアーキビストです。
2.  **一文字ずつの検証:** 文字列を読み取る際は、決して単語や文脈で推測せず、一文字ずつ丁寧になぞり、形状を特定します。
3.  **類似文字の徹底的な判別:**
    - `O` (オー) と `0` (ゼロ): `0`は縦長で、`O`はより円形に近いことを意識します。
    - `Q` と `0`: 最重要項目です。`Q`には必ず右下に短い棒（セリフやテール）があります。この棒が少しでも視認できる場合は、絶対に`Q`と判断してください。逆に、完全に閉じた円または楕円の場合は`0`とします。例えば、「4FBFQ902P001」のような文字列で、この違いを絶対に見逃さないでください。
    - `1`と`l`、`S`と`5`、`B`と`8`なども同様に、字形のわずかな違いから判断します。
    - **かっこ類の判別:**
      - 始めかっこ『(』の直後に続く文字（I, l, 1など）を、終わりかっこ『)』と誤認識するケースが多く報告されています。
      - 始めかっこ『(』の直後にある文字が『I』または『1』である場合、その文字は**決して終わりかっこ『)』ではない**と断定してください。
      - 『(』と『)』はセットで出現することが一般的ですが、画像内に終わりかっこ『)』の文字形状がはっきりと確認できない限り、推測でかっこを閉じないでください。
4.  **最終確認:** 出力する前に、抽出した各文字列が、上記のプロセスを経て本当に正しいか再確認します。

### ルール
- 画像に表示されている文字だけを忠実に抽出してください。
- 項目が存在しない、または物理的に完全に読み取れない場合のみ、値を空文字列 `""` としてください。
- 出力は必ず指定されたJSON形式に従ってください。

### 対象項目リスト
- 製番
- 項目番号
- 品名
- 形式
- 個数 (もし「数量」という表記であればそれも「個数」として扱う)
- 摘要 (もし「適用」や「備考」という表記であればそれも「摘要」として扱う)
- 図書番号
- 手配コード

### 出力形式 (JSON)
{
  "製番": "抽出された製番",
  "項目番号": "抽出された項目番号",
  "品名": "抽出された品名",
  "形式": "抽出された形式",
  "個数": "抽出された個数",
  "摘要": "抽出された摘要",
  "図書番号": "抽出された図書番号",
  "手配コード": "抽出された手配コード"
}
''';
}

// 製品リスト（Product List）抽出プロンプト (重複)
// ★★★ 修正: ユーザー指示に基づきプロンプトを修正 ★★★
String _buildProductListPrompt(String company) {
  // ★ TMEIC (T社) の場合: 「備考(NOTE)」を要求
  final fieldsForPrompt = (company == 'TMEIC')
      ? '["ITEM OF SPARE", "品名記号", "形格", "製品コード番号", "注文数", "記事", "備考(NOTE)"]'
  // ★ T社以外の場合: 「備考(REMARKS)」を要求 (枝番のため)
      : '["品名記号", "形格", "製品コード番号", "数量", "備考(REMARKS)"]';

  // ★ TMEIC (T社) のプロンプト
  if (company == 'TMEIC') {
    return '''
あなたは「T社」の製品リスト（T社帳票）を完璧に文字起こしする、データ入力の超専門家です。あなたの使命は、一文字のミスもなく、全ての文字を正確にJSON形式で出力することです。以下の思考プロセスとルールを厳守してください。

### 思考プロセス
1.  **役割認識:** あなたは単なるOCRエンジンではありません。細部まで見逃さない、熟練のデジタルアーキビストです。
2.  **一文字ずつの検証:** 「製品コード番号」などの文字列を読み取る際は、決して単語や文脈で推測せず、一文字ずつ丁寧になぞり、形状を特定します。
3.  **類似文字の徹底的な判別:** (O/0, Q/0, 1/l, S/5, B/8, かっこ類...)
    - `Q` と `0`: 最重要項目です。`Q`には必ず右下に短い棒（セリフやテール）があります。この棒が少しでも視認できる場合は、絶対に`Q`と判断してください。

### 抽出項目
1.  **commonOrderNo**: 画像の**左上、テーブルの外**にある共通の番号（例: `QZ83941 FEV2385` や `7LJ5321 5605566`）のうち、**スペースの左側だけ**（例: `QZ83941` や `7LJ5321`）を一つだけ抽出します。
2.  **products**: 製品リストの各行から以下の項目を抽出します。
    - 項目が存在しない、または物理的に完全に読み取れない場合のみ、値を空文字列 `""` としてください。
    - **「備考(NOTE)」** 列（例: `FEV2385` や `5605566`）の値を正確に抽出してください。
    - 対象項目リスト（各行ごと）：
      $fieldsForPrompt

### 出力形式 (JSON)
出力は必ずJSON形式に従ってください。
"commonOrderNo"には抽出した **左上の共通番号（スペースの左側のみ）** を、"products"には各行の情報を配列として格納してください。

例:
{
  "commonOrderNo": "QZ83941",
  "products": [
    {
      "ITEM OF SPARE": "021",
      "品名記号": "PWB-PL",
      "形格": "ARND-4334A (X10)",
      "製品コード番号": "4KAF4334G001",
      "注文数": "2",
      "記事": "PRINTED WIRING BOARD (Soft No. PSS)",
      "備考(NOTE)": "FEV2385"
    }
  ]
}
''';
  }

  // ★ TMEIC社以外のプロンプト
  return '''
あなたは「$company」の製品リストを完璧に文字起こしする、データ入力の超専門家です。あなたの使命は、一文字のミスもなく、全ての文字を正確にJSON形式で出力することです。以下の思考プロセスとルールを厳守してください。

### 思考プロセス
1.  **役割認識:** あなたは単なるOCRエンジンではありません。細部まで見逃さない、熟練のデジタルアーキビストです。
2.  **一文字ずつの検証:** 「製品コード番号」などの文字列を読み取る際は、決して単語や文脈で推測せず、一文字ずつ丁寧になぞり、形状を特定します。
3.  **類似文字の徹底的な判別:** (O/0, Q/0, 1/l, S/5, B/8, かっこ類...)
    - `Q` と `0`: 最重要項目です。`Q`には必ず右下に短い棒（セリフやテール）があります。この棒が少しでも視認できる場合は、絶対に`Q`と判断してください。

### 抽出項目
1.  **commonOrderNo**: 画像の**右上、テーブルの外**にある共通の注文番号プレフィックス（例: `T-12345-` や `S-98765-`）を一つだけ抽出します。枝番（例: -01）の**直前のハイフンまで**を含めてください。
2.  **products**: 製品リストの各行から以下の項目を抽出します。
    - 項目が存在しない、または物理的に完全に読み取れない場合のみ、値を空文字列 `""` としてください。
    - **「備考(REMARKS)」** 列は、枝番（例: `01`）が記載されている場合、その枝番の数字を抽出してください。
    - 対象項目リスト（各行ごと）：
      $fieldsForPrompt

### 出力形式 (JSON)
出力は必ずJSON形式に従ってください。
"commonOrderNo"には抽出した **右上の共通プレフィックスのみ** を、"products"には各行の情報を配列として格納してください。
例:
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
}


// --- Main Functions ---

/// Gemini APIクライアントを返す
GenerativeModel _getGeminiClient() {
  if (geminiApiKey.isEmpty) {
    FlutterLogs.logThis(
      tag: 'GEMINI_SERVICE',
      subTag: 'API_KEY_MISSING',
      logMessage: 'Google AI APIキーが設定されていません。',
      level: LogLevel.SEVERE,
    );
    throw Exception('Google AI APIキーが設定されていません。');
  }
  return GenerativeModel(
    model: modelName, 
    apiKey: geminiApiKey,
  );
}

// ★★★
// ★ 修正: ご提示いただいた原文 に基づき、
// ★ `sendImageToGemini` 関数 (荷札用・非ストリーミング) を追加します。
// ★★★
Future<Map<String, dynamic>?> sendImageToGemini( 
  Uint8List imageBytes, {
  required bool isProductList, // (I/F互換性のために残す)
  required String company, // (I/F互換性のために残す)
  http.Client? client, // 互換性維持のため残す
}) async {
  // isProductList は home_actions_gemini.dart から常に false で呼ばれる想定
  final model = _getGeminiClient();
  final prompt = _buildNifudaPrompt();
  
  final mime = _guessMimeType(imageBytes);
  final imagePart = DataPart(mime, imageBytes);
  final textPart = TextPart(prompt);
  
  final contents = [
    Content('user', [
      textPart,
      imagePart,
    ]),
  ];

  final config = GenerationConfig(
    responseMimeType: 'application/json',
  );

  FlutterLogs.logInfo('GEMINI_SERVICE', 'REQUEST_SENT', 'Sending image to Gemini for Nifuda');

  try {
    final response = await model.generateContent(
      contents, 
      generationConfig: config, 
    );

    String? contentString = response.text;
    if (contentString == null || contentString.trim().isEmpty) {
      FlutterLogs.logThis(
        tag: 'GEMINI_SERVICE',
        subTag: 'EMPTY_RESPONSE',
        logMessage: 'Gemini returned empty content.',
        level: LogLevel.WARNING,
      );
      return null;
    }

    contentString = _stripCodeFences(contentString).trim();

    try {
      final decoded = jsonDecode(contentString) as Map<String, dynamic>;
      FlutterLogs.logInfo('GEMINI_SERVICE', 'PARSE_SUCCESS', 'Successfully parsed Gemini JSON response.');
      return decoded;
    } catch (e, s) {
      FlutterLogs.logThis(
        tag: 'GEMINI_SERVICE',
        subTag: 'JSON_PARSE_FAILED',
        logMessage: 'Failed to parse Gemini JSON response: $contentString\n$s',
        exception: (e is Exception) ? e : Exception(e.toString()),
        level: LogLevel.ERROR,
      );
      return null;
    }
  } on GenerativeAIException catch (e, s) {
    FlutterLogs.logThis(
      tag: 'GEMINI_SERVICE',
      subTag: 'API_REQUEST_FAILED',
      logMessage: 'Gemini API request failed: ${e.message}\n$s',
      exception: Exception(e.message),
      level: LogLevel.ERROR,
    );
    if (kDebugMode) debugPrint('Geminiへの画像送信エラー: ${e.message}');
    return null;
  } catch (e, s) {
    FlutterLogs.logThis(
      tag: 'GEMINI_SERVICE',
      subTag: 'UNEXPECTED_ERROR',
      logMessage: 'Gemini image submission failed.\n$s',
      exception: (e is Exception) ? e : Exception(e.toString()),
      level: LogLevel.ERROR,
    );
    if (kDebugMode) debugPrint('Geminiへの画像送信エラー: $e');
    return null;
  }
}

/// 製品リスト抽出用のストリーミング関数 (ストリーミング)
Stream<String> sendImageToGeminiStream(
  Uint8List imageBytes, {
  required String company,
}) async* {
  final model = _getGeminiClient();
  // ★ 修正されたプロンプトを使用
  final prompt = _buildProductListPrompt(company);
  
  final mime = _guessMimeType(imageBytes);
  final imagePart = DataPart(mime, imageBytes);
  final textPart = TextPart(prompt);
  
  final contents = [
    Content('user', [
      textPart,
      imagePart,
    ]),
  ];

  final config = GenerationConfig(
    responseMimeType: 'application/json',
  );

  FlutterLogs.logInfo('GEMINI_SERVICE', 'STREAM_REQUEST_SENT', 'Sending image to Gemini Stream for Product List');

  try {
    final responseStream = model.generateContentStream(
      contents, 
      generationConfig: config, 
    );

    await for (final chunk in responseStream) {
      if (chunk.text != null) {
        yield chunk.text!; // テキストチャンクをそのまま流す
      }
    }
  } on GenerativeAIException catch (e, s) {
    // ストリームの外部でキャッチされるように、エラーを再スロー
    FlutterLogs.logThis(
      tag: 'GEMINI_SERVICE',
      subTag: 'STREAM_API_REQUEST_FAILED',
      logMessage: 'Gemini API stream request failed: ${e.message}',
      exception: Exception(e.message),
      level: LogLevel.ERROR,
    );
    throw e;
  } catch (e, s) {
    FlutterLogs.logThis(
      tag: 'GEMINI_SERVICE',
      subTag: 'STREAM_UNEXPECTED_ERROR',
      logMessage: 'Gemini image stream submission failed.\n$s',
      exception: (e is Exception) ? e : Exception(e.toString()),
      level: LogLevel.ERROR,
    );
    throw e;
  }
}