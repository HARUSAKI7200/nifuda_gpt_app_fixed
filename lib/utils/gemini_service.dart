// lib/utils/gemini_service.dart
//
// 修正方針：
// - プロンプト本文は一字一句変更せずそのまま使用（既存スキーマ厳守、項目追加なし）
// - google_generative_ai 0.4.x 系の仕様に合わせて Content('user', [...]) で構築
// - GenerationConfig(responseMimeType: 'application/json') で JSON 出力を固定
// - 画像MIMEはヘッダから推定（jpeg/png/webp/gif/bmp）
// - 応答が ```json で囲まれても JSON として正しくパース（その場で除去。新規関数は作らない）
// - 例外/ログは既存運用に合わせて FlutterLogs で記録

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:http/http.dart' as http; 
import 'package:google_generative_ai/google_generative_ai.dart'; 

Future<Map<String, dynamic>?> sendImageToGemini( 
  Uint8List imageBytes, {
  required bool isProductList,
  required String company,
  http.Client? client, // 互換性維持のため残す
}) async {
  const geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  const modelName = 'gemini-2.5-flash';

  if (geminiApiKey.isEmpty) {
    FlutterLogs.logThis(
      tag: 'GEMINI_SERVICE',
      subTag: 'API_KEY_MISSING',
      logMessage: 'Google AI APIキーが設定されていません。--dart-define=GEMINI_API_KEY=YOUR_KEY の形式で実行してください。',
      level: LogLevel.SEVERE,
    );
    throw Exception('Google AI APIキーが設定されていません。--dart-define=GEMINI_API_KEY=YOUR_KEY の形式で実行してください。');
  }

  // 1. モデルクライアントの初期化 (APIキーを使用)
  final model = GenerativeModel(
    model: modelName, 
    apiKey: geminiApiKey,
  );
  
  // 2. プロンプトの構築（本文は変更しない）
  final prompt = isProductList ? _buildProductListPrompt(company) : _buildNifudaPrompt();
  
  // 3. コンテンツの構築（画像MIMEはヘッダから推定して DataPart に設定）
  String mime = 'image/jpeg';
  if (imageBytes.lengthInBytes >= 12) {
    // PNG
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      mime = 'image/png';
    }
    // JPEG
    else if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
      mime = 'image/jpeg';
    }
    // WEBP (RIFF....WEBP)
    else if (imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      mime = 'image/webp';
    }
    // GIF
    else if (imageBytes[0] == 0x47 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x38) {
      mime = 'image/gif';
    }
    // BMP
    else if (imageBytes[0] == 0x42 && imageBytes[1] == 0x4D) {
      mime = 'image/bmp';
    }
  }

  final imagePart = DataPart(mime, imageBytes);
  final textPart = TextPart(prompt);
  
  // 修正: google_generative_ai 0.4.7 の Content コンストラクタは role (位置引数) が必要
  final contents = [
    Content('user', [ // role に 'user' を指定
      textPart,
      imagePart,
    ]),
  ];

  // 修正: GenerationConfig を使用（JSON出力を固定）
  final config = GenerationConfig(
    responseMimeType: 'application/json',
    // 必要に応じて下記を使う場合は追加（ここではプロンプト準拠優先のため未設定）
    // temperature: 0.0,
    // maxOutputTokens: 2048,
  );

  FlutterLogs.logInfo('GEMINI_SERVICE', 'REQUEST_SENT', 'Sending image to Gemini for ${isProductList ? "Product List" : "Nifuda"}');

  try {
    // 5. APIリクエストの実行
    final response = await model.generateContent(
      contents, 
      // 修正: config パラメータは generationConfig に修正 (google_generative_ai 0.4.7 の仕様)
      generationConfig: config, 
    );

    // 6. 応答の検証と解析
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

    // モデルが誤って ```json などで囲って返すケースへの耐性（プロンプトはJSONのみ要求だが念のため）
    final trimmed = contentString.trim();
    if (trimmed.startsWith('```')) {
      // 先頭の ```json / ``` を除去
      contentString = trimmed
          .replaceFirst(RegExp(r'^```(json)?', caseSensitive: false), '')
          .replaceFirst(RegExp(r'```$'), '')
          .trim();
    }

    try {
      if (kDebugMode) print('Gemini Parsed Content String: $contentString');
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
    debugPrint('Geminiへの画像送信エラー: ${e.message}');
    return null;
  } catch (e, s) {
    FlutterLogs.logThis(
      tag: 'GEMINI_SERVICE',
      subTag: 'UNEXPECTED_ERROR',
      logMessage: 'Gemini image submission failed.\n$s',
      exception: (e is Exception) ? e : Exception(e.toString()),
      level: LogLevel.ERROR,
    );
    debugPrint('Geminiへの画像送信エラー: $e');
    return null;
  }
}

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

String _buildProductListPrompt(String company) {
  final fieldsForPrompt = (company == 'TMEIC')
      ? '["ITEM OF SPARE", "品名記号", "形格", "製品コード番号", "注文数", "記事", "備考"]'
      : '["品名記号", "形格", "製品コード番号", "数量", "備考"]';
  return '''
あなたは「$company」の製品リストを完璧に文字起こしする、データ入力の超専門家です。あなたの使命は、一文字のミスもなく、全ての文字を正確にJSON形式で出力することです。以下の思考プロセスとルールを厳守してください。

### 思考プロセス
1.  **役割認識:** あなたは単なるOCRエンジンではありません。細部まで見逃さない、熟練のデジタルアーキビストです。
2.  **一文字ずつの検証:** 「製品コード番号」などの文字列を読み取る際は、決して単語や文脈で推測せず、一文字ずつ丁寧になぞり、形状を特定します。
3.  **類似文字の徹底的な判別:**
    - `O` (オー) と `0` (ゼロ): `0`は縦長で、`O`はより円形に近いことを意識します。
    - `Q` と `0`: 最重要項目です。`Q`には必ず右下に短い棒（セリフやテール）があります。この棒が少しでも視認できる場合は、絶対に`Q`と判断してください。逆に、完全に閉じた円または楕円の場合は`0`とします。例えば、「4FBFQ902P001」のような文字列で、この違いを絶対に見逃さないでください。
    - `1`と`l`、`S`と`5`、`B`と`8`なども同様に、字形のわずかな違いから判断します。
    - **かっこ類の判別:**
      - 始めかっこ『(』の直後に続く文字（I, l, 1など）を、終わりかっこ『)』と誤認識するケースが多く報告されています。
      - 始めかっこ『(』のみで、終わりかっこ『)』が無いパターンがあります。
      - 『(』と『)』はセットで出現することが一般的ですが、画像内に終わりかっこ『)』の文字形状がはっきりと確認できない限り、推測でかっこを閉じないでください。
4.  **最終確認:** 出力する前に、抽出した各文字列が、上記のプロセスを経て本当に正しいか再確認します。

### 抽出項目
表外にある「ORDER No.」を一つだけ抽出し、次に製品リストの各行から以下の項目を抽出します。
項目が存在しない、または物理的に完全に読み取れない場合のみ、値を空文字列 `""` としてください。

対象項目リスト（各行ごと）：
$fieldsForPrompt

### 出力形式 (JSON)
出力は必ずJSON形式に従ってください。
"commonOrderNo"には抽出したORDER No.の値を、"products"には各行の情報を配列として格納してください。
例:
{
  "commonOrderNo": "QZ83941 FEV2385",
  "products": [
    {
      "ITEM OF SPARE": "021",
      "品名記号": "PWB-PL",
      "形格": "ARND-4334A (X10)",
      "製品コード番号": "4KAF4334G001",
      "注文数": "2",
      "記事": "PRINTED WIRING BOARD (Soft No. PSS)",
      "備考": "FFV0001"
    }
  ]
}
''';
}
