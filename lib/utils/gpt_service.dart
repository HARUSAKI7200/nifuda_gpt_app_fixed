// lib/utils/gpt_service.dart

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:http/http.dart' as http;
import 'package:openai_dart/openai_dart.dart';

import 'prompt_definitions.dart'; 

// --- Local Helper Functions ---

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

String _stripCodeFences(String s) {
  final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$', multiLine: true);
  final m = fence.firstMatch(s.trim());
  if (m != null && m.groupCount >= 1) {
    return m.group(1) ?? s;
  }
  return s;
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


const openAIApiKey = String.fromEnvironment('OPENAI_API_KEY');

final OpenAIClient _openAIClient = OpenAIClient(apiKey: openAIApiKey);

Future<CreateChatCompletionResponse> _openAICreateVisionChat({
  required ChatCompletionModel model,
  required String prompt,
  required String dataUrl, 
}) {
  return _openAIClient.createChatCompletion(
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
      responseFormat: ResponseFormat.jsonObject(),
    ),
  );
}

Stream<CreateChatCompletionStreamResponse> _openAICreateVisionChatStream({
  required ChatCompletionModel model,
  required String prompt,
  required String dataUrl, 
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
      responseFormat: ResponseFormat.jsonObject(),
    ),
  );
}


Future<Map<String, dynamic>?> sendImageToGPT(
  Uint8List imageBytes, {
  required bool isProductList,
  String? promptId, 
  String company = '', 
  http.Client? client, 
}) async {
  if (openAIApiKey.isEmpty) {
    FlutterLogs.logThis(
      tag: 'GPT_SERVICE',
      subTag: 'API_KEY_MISSING',
      logMessage: 'OpenAI APIキーが設定されていません。',
      level: LogLevel.SEVERE,
    );
    throw Exception('OpenAI APIキーが設定されていません。');
  }

  if (isProductList) {
    if (kDebugMode) print('Warning: Product List extraction should use sendImageToGPTStream.');
  }

  final mime = _guessMimeType(imageBytes);
  final String base64Image = base64Encode(imageBytes);
  final String dataUrl = 'data:$mime;base64,$base64Image';

  ChatCompletionModel primaryModel = ChatCompletionModel.modelId('gpt-5.2');
  
  final String prompt = _buildNifudaPrompt();

  FlutterLogs.logInfo(
    'GPT_SERVICE',
    'REQUEST_SENT',
    'Sending image to GPT (gpt-5.2) for Nifuda',
  );

  try {
    CreateChatCompletionResponse response;

    try {
      response = await _openAICreateVisionChat(
        model: primaryModel,
        prompt: prompt,
        dataUrl: dataUrl,
      );
    } on OpenAIClientException catch (e, s) {
      final String msg = e.message ?? e.toString();
      FlutterLogs.logThis(
        tag: 'GPT_SERVICE',
        subTag: 'PRIMARY_REQUEST_FAILED',
        logMessage: 'gpt-5.2 failed: $msg\n$s',
        exception: Exception(msg),
        level: LogLevel.WARNING,
      );
      rethrow;
    }

    final dynamic rawContent = response.choices.first.message.content;

    String? contentString;
    if (rawContent is String) {
      contentString = rawContent;
    } else {
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

    // ★ 修正: 生のレスポンスをログ出力
    if (kDebugMode) {
      debugPrint('================= [GPT Nifuda Raw Response] =================');
      debugPrint(contentString);
      debugPrint('=============================================================');
    }

    contentString = _stripCodeFences(contentString).trim();

    try {
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

Stream<String> sendImageToGPTStream(
  Uint8List imageBytes, {
  String promptId = 'standard',
  String company = '', 
}) async* {
  if (openAIApiKey.isEmpty) {
    FlutterLogs.logThis(tag: 'GPT_SERVICE', subTag: 'API_KEY_MISSING', logMessage: 'OpenAI APIキーが設定されていません。', level: LogLevel.SEVERE);
    throw Exception('OpenAI APIキーが設定されていません。');
  }

  final mime = _guessMimeType(imageBytes);
  final String base64Image = base64Encode(imageBytes);
  final String dataUrl = 'data:$mime;base64,$base64Image';
  
  final ChatCompletionModel visionModel = ChatCompletionModel.modelId('gpt-5.2');
  
  final definition = PromptRegistry.getById(promptId);
  final String prompt = definition.systemPrompt;

  FlutterLogs.logInfo(
    'GPT_SERVICE',
    'STREAM_REQUEST_SENT',
    'Sending image to GPT Stream (gpt-5.2) for Product List using prompt: ${definition.label}',
  );

  try {
    final responseStream = _openAICreateVisionChatStream(
      model: visionModel,
      prompt: prompt,
      dataUrl: dataUrl,
    );

    await for (final chunk in responseStream) {
      final content = chunk.choices?.first.delta?.content;
      if (content != null) {
        yield content; 
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