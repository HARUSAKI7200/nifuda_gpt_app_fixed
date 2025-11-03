// lib/utils/gpt_service.dart
//
// 修正方針：
// - ★★★ 修正: GPTモデルを「gpt-5-mini」に戻す ★★★
// - 荷札抽出時のフォールバックロジックを削除。
// - gpt-5(-mini) が "temperature: 0.0" に非対応なため、temperatureの指定自体を削除 (維持)
// - SDKのChatCompletionResponseFormatエラーをResponseFormat(type: ResponseFormatType.jsonObject)に修正。
// - ストリーミング応答のNull安全性を強化。
// - 欠落していた `package:flutter/foundation.dart` のインポートを追加。
// ★ TMEIC社のプロンプトを「commonOrderNoは左側のみ」「productsは備考(NOTE)」に修正。
// ★ T社以外のプロンプトを「備考(REMARKS)」を使用するよう修正。

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // ★ 修正: インポートを追加
import 'package:flutter_logs/flutter_logs.dart';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';

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
あなたは「TMEIC」の製品リスト（T社帳票）を完璧に文字起こしする、データ入力の超専門家です。あなたの使命は、一文字のミスもなく、全ての文字を正確にJSON形式で出力することです。以下の思考プロセスとルールを厳守してください。

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


/// OpenAI APIキーを --dart-define から取得
const openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');

/// OpenAI クライアント（singleton）
final OpenAIClient _openAIClient = OpenAIClient(apiKey: openAIApiKey);

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
      // ★ 修正: temperature: 0.0 を削除
      // ★ ログに基づき、gpt-5(-mini) は temperature: 1 (デフォルト) のみをサポート
      // temperature: 0.0,
      // ★ 正式：JSONモードを指定（factory）
      responseFormat: ResponseFormat.jsonObject(),
    ),
  );
}

/// Chat Completions (multimodal) へのストリーミング送信（private集約）
Stream<CreateChatCompletionStreamResponse> _openAICreateVisionChatStream({
  required ChatCompletionModel model,
  required String prompt,
  required String dataUrl, // data:<mime>;base64,.... の形式
}) {
  return _openAIClient.createChatCompletionStream(
    request: CreateChatCompletionRequest(
      model: model,
      messages: [
        ChatCompletionMessage.system(
          content:
              'あなたはデータ入力の超専門家です。応答は必ず純粋なJSON（プレーンテキストのJSONオブジェクトのみ、前後の説明文やコードフェンス禁止）で出力してください。',
        ),
        ChatCompletionMessage.user(
          content: ChatCompletionUserMessageContent.parts([
            ChatCompletionMessageContentPart.text(text: prompt),
            ChatCompletionMessageContentPart.image(
              imageUrl: ChatCompletionMessageImageUrl(
                url: dataUrl,
                detail: ChatCompletionMessageImageDetail.high,
              ),
            ),
          ]),
        ),
      ],
      // ★ 修正: temperature: 0.0 を削除
      // ★ ログに基づき、gpt-5(-mini) は temperature: 1 (デフォルト) のみをサポート
      // temperature: 0.0,
      // ★ 正式：JSONモードを指定（factory）
      responseFormat: ResponseFormat.jsonObject(),
    ),
  );
}


/// 荷札抽出用のメイン関数 (非ストリーミング)
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
          'OpenAI APIキーが設定されていません。',
      level: LogLevel.SEVERE,
    );
    throw Exception(
      'OpenAI APIキーが設定されていません。',
    );
  }

  // 製品リストの場合はストリーミング専用関数へ委譲 (ここでは非ストリーミング関数として実装を維持)
  if (isProductList) {
    if (kDebugMode) print('Warning: Product List extraction should use sendImageToGPTStream.');
  }


  final mime = _guessMimeType(imageBytes);
  final String base64Image = base64Encode(imageBytes);
  final String dataUrl = 'data:$mime;base64,$base64Image';

  // ★★★ 修正: モデルを gpt-5-mini に変更 ★★★
  ChatCompletionModel primaryModel = ChatCompletionModel.modelId('gpt-5-mini');
  
  // プロンプト（既存内容は変更しない）
  final String prompt = _buildNifudaPrompt();

  FlutterLogs.logInfo(
    'GPT_SERVICE',
    'REQUEST_SENT',
    'Sending image to GPT (gpt-5-mini) for Nifuda', // ★ 修正
  );

  try {
    CreateChatCompletionResponse response;

    // -------- gpt-5-mini で送信 (★ 修正: フォールバックなし) --------
    try {
      response = await _openAICreateVisionChat(
        model: primaryModel,
        prompt: prompt,
        dataUrl: dataUrl,
      );
    } on OpenAIClientException catch (e, s) {
      // ★ 修正: フォールバックロジックを削除し、エラーログと再スローに変更
      final String msg = e.message ?? e.toString();
      FlutterLogs.logThis(
        tag: 'GPT_SERVICE',
        subTag: 'PRIMARY_REQUEST_FAILED',
        logMessage: 'gpt-5-mini failed: $msg\n$s', // ★ 修正
        exception: Exception(msg),
        level: LogLevel.WARNING,
      );
      rethrow; // ★ 修正: 失敗したらそのままエラーを投げる
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
    // HTTP例外
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'API_REQUEST_FAILED',
      logMessage: 'OpenAI API request failed: ${e.message ?? e.toString()}\n$s',
      exception: Exception(e.message ?? e.toString()),
      level: LogLevel.ERROR,
    );
    if (kDebugMode) debugPrint('OpenAIへの画像送信エラー: ${e.message ?? e.toString()}');
    return null;
  } catch (e, s) {
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'UNEXPECTED_ERROR',
      logMessage: 'GPT image submission failed.\n$s',
      exception: (e is Exception) ? e : Exception(e.toString()),
      level: LogLevel.ERROR,
    );
    if (kDebugMode) debugPrint('OpenAIへの画像送信エラー: $e');
    return null;
  }
}

/// 製品リスト抽出用のストリーミング関数
Stream<String> sendImageToGPTStream(
  Uint8List imageBytes, {
  required String company,
}) async* {
  if (openAIApiKey.isEmpty) {
    FlutterLogs.logThis(tag: 'GPT_SERVICE', subTag: 'API_KEY_MISSING', logMessage: 'OpenAI APIキーが設定されていません。', level: LogLevel.SEVERE);
    throw Exception('OpenAI APIキーが設定されていません。');
  }

  final mime = _guessMimeType(imageBytes);
  final String base64Image = base64Encode(imageBytes);
  final String dataUrl = 'data:$mime;base64,$base64Image';
  
  // ★★★ 修正: モデルを gpt-5-mini に変更 ★★★
  final ChatCompletionModel visionModel = ChatCompletionModel.modelId('gpt-5-mini');
  // ★ 修正されたプロンプトを使用
  final String prompt = _buildProductListPrompt(company);

  FlutterLogs.logInfo(
    'GPT_SERVICE',
    'STREAM_REQUEST_SENT',
    'Sending image to GPT Stream (gpt-5-mini) for Product List', // ★ 修正
  );

  try {
    final responseStream = _openAICreateVisionChatStream(
      model: visionModel,
      prompt: prompt,
      dataUrl: dataUrl,
    );

    await for (final chunk in responseStream) {
      // ★ 修正: choicesとdeltaのNull安全チェックを追加
      final content = chunk.choices?.first.delta?.content;
      if (content != null) {
        yield content; // テキストチャンクをそのまま流す
      }
    }
  } on OpenAIClientException catch (e, s) {
    FlutterLogs.logThis(tag: 'GPT_SERVICE', subTag: 'STREAM_API_REQUEST_FAILED', logMessage: 'OpenAI API stream request failed: ${e.message ?? e.toString()}', exception: Exception(e.message ?? e.toString()), level: LogLevel.ERROR);
    throw e;
  } catch (e, s) {
    FlutterLogs.logThis(tag: 'GPT_SERVICE', subTag: 'STREAM_UNEXPECTED_ERROR', logMessage: 'GPT image stream submission failed.\n$s', exception: (e is Exception) ? e : Exception(e.toString()), level: LogLevel.ERROR);
    throw e;
  }
}