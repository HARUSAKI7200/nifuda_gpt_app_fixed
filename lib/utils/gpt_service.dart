// lib/utils/gpt_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';

Future<Map<String, dynamic>> sendImageToGPT(
  Uint8List imageBytes, {
  required bool isProductList,
  required String company,
  http.Client? client,
}) async {
  const apiKey = String.fromEnvironment('OPENAI_API_KEY');
  const modelName = String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-5-mini');

  if (apiKey.isEmpty) {
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'API_KEY_MISSING',
      logMessage: 'OpenAI API key is not configured.',
      level: LogLevel.SEVERE,
    );
    throw Exception('OpenAI APIキーが設定されていません。');
  }

  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  final base64Image = base64Encode(imageBytes);
  final String mimeType = isProductList ? 'image/webp' : 'image/jpeg';
  final prompt = isProductList ? _buildProductListPrompt(company) : _buildNifudaPrompt();
  final body = jsonEncode({
    'model': modelName,
    'messages': [
      {'role': 'system', 'content': 'You are a world-class OCR + information extractor for Japanese industrial shipping documents.'},
      {
        'role': 'user',
        'content': [
          {'type': 'text', 'text': prompt},
          {'type': 'input_image', 'image_url': {'url': 'data:$mimeType;base64,$base64Image'}},
        ]
      }
    ],
    'max_completion_tokens': 4096,
    'response_format': {'type': 'json_object'},
  });

  FlutterLogs.logInfo('GPT_SERVICE', 'REQUEST_SENT', 'Sending image to GPT for ${isProductList ? "Product List" : "Nifuda"}');

  try {
    final postRequest = (client != null)
        ? client.post(uri, headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'}, body: body)
        : http.post(uri, headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'}, body: body);
    final response = await postRequest.timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body) as Map<String, dynamic>;
      if (kDebugMode) {
        FlutterLogs.logInfo('GPT_SERVICE', 'HTTP_OK', 'GPT response received.');
      }

      if (jsonResponse.containsKey('choices') && (jsonResponse['choices'] as List).isNotEmpty) {
        try {
          final first = (jsonResponse['choices'] as List).first as Map<String, dynamic>;
          final content = ((first['message'] ?? const {}) as Map<String, dynamic>)['content'] ?? '';
          final contentString = content is String ? content : jsonEncode(content);
          if (contentString.trim().isEmpty) {
            final finishReason = first['finish_reason'] ?? '(unknown reason)';
            FlutterLogs.logThis(
              tag: 'GPT_SERVICE',
              subTag: 'EMPTY_RESPONSE',
              logMessage: 'GPT returned empty content. finish_reason: $finishReason',
              level: LogLevel.WARNING,
            );
            throw Exception('GPTからの応答が空です。Finish Reason: $finishReason');
          }
          if (kDebugMode) print('GPT Parsed Content String: $contentString');
          FlutterLogs.logInfo('GPT_SERVICE', 'PARSE_SUCCESS', 'Successfully parsed GPT JSON response.');
          return jsonDecode(contentString) as Map<String, dynamic>;
        } catch (e, s) {
          FlutterLogs.logThis(
            tag: 'GPT_SERVICE',
            subTag: 'JSON_PARSE_FAILED',
            logMessage: 'Failed to parse GPT JSON response: $s',
            exception: (e is Exception) ? e : Exception(e.toString()),
            level: LogLevel.ERROR,
          );
          throw Exception('GPTの応答JSON解析に失敗: $s');
        }
      } else {
        FlutterLogs.logThis(
          tag: 'GPT_SERVICE',
          subTag: 'INVALID_STRUCTURE',
          logMessage: 'Response is missing valid data in "choices" field.',
          level: LogLevel.ERROR,
        );
        throw Exception('GPT応答に有効なデータがありません（choicesフィールド）。');
      }
    } else {
      final errorBody = response.body;
      FlutterLogs.logThis(
        tag: 'GPT_SERVICE',
        subTag: 'HTTP_${/* status */''}${response.statusCode}',
        logMessage: 'GPT API returned status ${response.statusCode}. Body: $errorBody',
        level: LogLevel.ERROR,
      );
      throw Exception('HTTP ${response.statusCode}: $errorBody');
    }
  } catch (e, s) {
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'HTTP_REQUEST_FAILED',
      logMessage: 'GPT image submission failed.\n$s',
      exception: (e is Exception) ? e : Exception(e.toString()),
      level: LogLevel.ERROR,
    );
    debugPrint('GPTへの画像送信エラー: $e');
    rethrow;
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
    - `Q` と `0`: **最重要項目です。`Q`には必ず右下に短い棒（セリフやテール）があります。この棒が少しでも視認できる場合は、絶対に`Q`と判断してください。逆に、完全に閉じた円または楕円の場合は`0`とします。例えば、「4FBFQ902P001」のような文字列で、この違いを絶対に見逃さないでください。**
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

### 出力形式
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
    - `Q` と `0`: **最重要項目です。`Q`には必ず右下に短い棒（セリフやテール）があります。この棒が少しでも視認できる場合は、絶対に`Q`と判断してください。逆に、完全に閉じた円または楕円の場合は`0`とします。例えば、「4FBFQ902P001」のような文字列で、この違いを絶対に見逃さないでください。**
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

### 出力形式
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