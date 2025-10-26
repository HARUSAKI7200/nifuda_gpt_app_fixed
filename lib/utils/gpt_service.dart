// lib/utils/gpt_service.dart
//
// SDK: openai_dart ^0.6.0+1
// モデル: gpt-5-mini（第一候補）→ 画像非対応時は gpt-4o-mini に自動フォールバック
// 画像(Base64 data URL) + 厳密プロンプトを Chat Completions (multimodal) へ送信し、純粋JSONを Map<String,dynamic> で返す。
// 既存UI/ログ/例外/フローは維持。新規関数追加禁止の要件に従い、private関数で集約。

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';

/// OpenAI APIキーを --dart-define から取得
const openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');

/// OpenAI クライアント（singleton）
final OpenAIClient _openAIClient = OpenAIClient(apiKey: openAIApiKey);

/// 画像をOpenAI (Chat Completions, multimodal) に送ってJSONを返す
///
/// - [isProductList]: true のとき製品リスト抽出、false のとき荷札抽出
/// - [company]: 会社名（例: "TMEIC"）
/// - [client]: 互換性維持のためのダミー（未使用）
Future<Map<String, dynamic>?> sendImageToGPT(
  Uint8List imageBytes, {
  required bool isProductList,
  required String company,
  http.Client? client, // 未使用だが削除禁止（互換性維持）
}) async {
  // APIキーの検証
  if (openAIApiKey.isEmpty) {
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'API_KEY_MISSING',
      logMessage:
          'OpenAI APIキーが設定されていません。--dart-define=OPENAI_API_KEY=YOUR_KEY の形式で実行してください。',
      level: LogLevel.SEVERE,
    );
    throw Exception(
      'OpenAI APIキーが設定されていません。--dart-define=OPENAI_API_KEY=YOUR_KEY の形式で実行してください。',
    );
  }

  // MIME 推定（JPEG/PNG/WEBP/GIF/BMP）
  String mime = 'image/jpeg';
  if (imageBytes.lengthInBytes >= 12) {
    if (imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47) {
      mime = 'image/png';
    } else if (imageBytes[0] == 0xFF && imageBytes[1] == 0xD8) {
      mime = 'image/jpeg';
    } else if (imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46 &&
        imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50) {
      mime = 'image/webp';
    } else if (imageBytes[0] == 0x47 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x38) {
      mime = 'image/gif';
    } else if (imageBytes[0] == 0x42 && imageBytes[1] == 0x4D) {
      mime = 'image/bmp';
    }
  }

  // data URL 形式で渡す（この形が最も互換性が高い）
  final String base64Image = base64Encode(imageBytes);
  final String dataUrl = 'data:$mime;base64,$base64Image';

  // モデル：第一候補 gpt-5-mini（要求通り）
  ChatCompletionModel primaryModel = ChatCompletionModel.modelId('gpt-5-mini');
  // フォールバック：画像対応の gpt-4o-mini
  final ChatCompletionModel fallbackVisionModel =
      ChatCompletionModel.modelId('gpt-4o-mini');

  // プロンプト（既存内容は変更しない）
  final String prompt =
      isProductList ? _buildProductListPrompt(company) : _buildNifudaPrompt();

  FlutterLogs.logInfo(
    'GPT_SERVICE',
    'REQUEST_SENT',
    'Sending image to GPT (primary=gpt-5-mini) for ${isProductList ? "Product List" : "Nifuda"}',
  );

  try {
    CreateChatCompletionResponse response;

    // -------- 1回目: gpt-5-mini で送信 --------
    try {
      response = await _openAICreateVisionChat(
        model: primaryModel,
        prompt: prompt,
        dataUrl: dataUrl,
      );
    } on OpenAIClientException catch (e, s) {
      // statusCode はこの型に存在しないため、メッセージ文字列から推定
      final String msg = e.message ?? e.toString();

      FlutterLogs.logThis(
        tag: 'GPT_SERVICE',
        subTag: 'PRIMARY_REQUEST_FAILED',
        logMessage: 'Primary model (gpt-5-mini) failed: $msg\n$s',
        exception: Exception(msg),
        level: LogLevel.WARNING,
      );

      // 画像非対応・コンテンツ型不一致などを示唆する語を検出
      final String lmsg = msg.toLowerCase();
      final bool maybeVisionUnsupported =
          lmsg.contains('image') ||
          lmsg.contains('vision') ||
          lmsg.contains('content type') ||
          lmsg.contains('unsupported') ||
          lmsg.contains('unsuccessful') ||
          lmsg.contains('bad request');

      if (!maybeVisionUnsupported) {
        rethrow; // 通信断など別要因は上位で処理
      }

      // -------- 2回目: フォールバック(gpt-4o-mini)で再試行 --------
      FlutterLogs.logInfo(
        'GPT_SERVICE',
        'FALLBACK_TRY',
        'Retrying with fallback vision model (gpt-4o-mini).',
      );

      response = await _openAICreateVisionChat(
        model: fallbackVisionModel,
        prompt: prompt,
        dataUrl: dataUrl,
      );
    }

    // 応答本文の抽出（通常は String）
    final dynamic rawContent = response.choices.first.message.content;

    String? contentString;
    if (rawContent is String) {
      contentString = rawContent;
    } else {
      // 型付きの場合のフォールバック（基本はString想定）
      contentString = rawContent?.toString();
    }

    if (contentString == null || contentString.trim().isEmpty) {
      FlutterLogs.logThis(
        tag: 'GPT_SERVICE',
        subTag: 'EMPTY_RESPONSE',
        logMessage: 'GPT returned empty content.',
        level: LogLevel.WARNING,
      );
      return null;
    }

    // 念のためコードフェンス除去（```json ... ``` → 素のJSON）
    contentString = _stripCodeFences(contentString).trim();

    // JSONにパース
    try {
      if (kDebugMode) {
        // ignore: avoid_print
        print('GPT Parsed Content String: $contentString');
      }
      final decoded = jsonDecode(contentString);
      if (decoded is Map<String, dynamic>) {
        FlutterLogs.logInfo(
          'GPT_SERVICE',
          'PARSE_SUCCESS',
          'Successfully parsed GPT JSON response.',
        );
        return decoded;
      } else {
        FlutterLogs.logThis(
          tag: 'GPT_SERVICE',
          subTag: 'JSON_NOT_OBJECT',
          logMessage:
              'GPT JSON response is not an object. Type: ${decoded.runtimeType}',
          level: LogLevel.ERROR,
        );
        return null;
      }
    } catch (e, s) {
      FlutterLogs.logThis(
        tag: 'GPT_SERVICE',
        subTag: 'JSON_PARSE_FAILED',
        logMessage: 'Failed to parse GPT JSON response: $contentString\n$s',
        exception: (e is Exception) ? e : Exception(e.toString()),
        level: LogLevel.ERROR,
      );
      return null;
    }
  } on OpenAIClientException catch (e, s) {
    // HTTP例外（フォールバックも失敗）
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'API_REQUEST_FAILED',
      logMessage: 'OpenAI API request failed: ${e.message ?? e.toString()}\n$s',
      exception: Exception(e.message ?? e.toString()),
      level: LogLevel.ERROR,
    );
    debugPrint('OpenAIへの画像送信エラー: ${e.message ?? e.toString()}');
    return null;
  } catch (e, s) {
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'UNEXPECTED_ERROR',
      logMessage: 'GPT image submission failed.\n$s',
      exception: (e is Exception) ? e : Exception(e.toString()),
      level: LogLevel.ERROR,
    );
    debugPrint('OpenAIへの画像送信エラー: $e');
    return null;
  }
}

/// Chat Completions (multimodal) への送信（private集約）
Future<CreateChatCompletionResponse> _openAICreateVisionChat({
  required ChatCompletionModel model,
  required String prompt,
  required String dataUrl, // data:<mime>;base64,.... の形式
}) {
  return _openAIClient.createChatCompletion(
    request: CreateChatCompletionRequest(
      model: model,
      messages: [
        // system ロール：ここは String を直接渡せる
        ChatCompletionMessage.system(
          content:
              'あなたはデータ入力の超専門家です。応答は必ず純粋なJSON（プレーンテキストのJSONオブジェクトのみ、前後の説明文やコードフェンス禁止）で出力してください。',
        ),
        // user: テキスト + 画像（data URL）を parts で送信
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.parts([
            ChatCompletionMessageContentPart.text(text: prompt),
            ChatCompletionMessageContentPart.image(
              imageUrl: ChatCompletionMessageImageUrl(
                url: dataUrl, // ← data: スキームを渡す
                detail: ChatCompletionMessageImageDetail.high,
              ),
            ),
          ]),
        ),
      ],
      temperature: 0.0,
    ),
  );
}

/// 荷札（票）向けの抽出プロンプト（既存内容そのまま）
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

### 記法 (JSON)
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

/// 製品リスト向けの抽出プロンプト（既存内容そのまま）
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

/// コードフェンス除去（```json ... ``` → 素のJSON）
String _stripCodeFences(String s) {
  final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$', multiLine: true);
  final m = fence.firstMatch(s.trim());
  if (m != null && m.groupCount >= 1) {
    return m.group(1) ?? s;
  }
  return s;
}
