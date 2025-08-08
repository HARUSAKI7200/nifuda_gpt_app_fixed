import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

String _buildNifudaPrompt() {
  return '''
あなたは提供された荷札の画像を解析し、以下の項目を抽出してJSONオブジェクト形式で出力するAIです。
荷札の画像は、文字が小さかったり、かすれていたり、手書きであったりするため、OCRの際に誤字が生じやすいことに特に注意してください。
以下の指示に従い、各項目を正確に抽出してください。

抽出の際の注意点：
1. **正確な文字抽出を最優先します。** 意味を推測せず、画像に表示されている文字をそのまま抽出してください。
2. **文字の混同に特に注意してください。** 例: `O`（オー）と`0`（ゼロ）、`1`（イチ）と`l`（エル）、`2`（ニー）と`Z`（ゼット）、`S`と`5`、`B`と`8`、`Q`と`0`（ゼロ）と`O`（オー）**など。
3. **画像中に項目が存在しない場合や読み取れない場合は**、そのキーに対する値を空文字列""としてください。「不明」や「(空欄)」といった文字列は使用しないでください。
4. 個数の表記は、分数表記されていたら、そのまま表記してください。
5. 抽出する値は、値に意味を見出さず、必ず検出された項目の箇所で抽出してください。

対象項目リスト：
- 製番
- 項目番号
- 品名
- 形式
- 個数 (もし「数量」という表記であればそれも「個数」として扱う)
- 摘要 (もし「適用」や「備考」という表記であればそれも「摘要」として扱う)
- 図書番号
- 手配コード (この項目は荷札に存在する場合のみ)

出力は必ず以下のJSON形式に従ってください：
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
  // T社の項目リスト
  final List<String> targetProductFields = [
    "ITEM OF SPARE", "品名記号", "形格", "製品コード番号", "注文数", "記事", "備考"
  ];
  String fieldsForPrompt = targetProductFields.map((f) => "- $f").join("\n");

  return '''
あなたは「$company」の製品リスト画像のOCRを専門とするAIです。
画像内の文字は小さく、かすれている可能性があるため、特に以下の点に注意して各項目を正確に抽出してください。

- **`O`（オー）と`0`（ゼロ）**、**`1`（イチ）と`l`（エル）**、**`2`（ニー）と`Z`（ゼット）**、**`S`と`5`**、**`Q`と`0`（ゼロ）と`O`（オー）**などの、OCRで混同しやすい文字の区別に細心の注意を払う。
- 意味を推測せず、画像に表示されている文字をそのまま抽出する。

### 抽出項目
表外にある「ORDER No.」を一つだけ抽出し、次に製品リストの各行から以下の項目を抽出します。
項目が存在しない、または読み取れない場合は、空文字列`""`を使用します。

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

Future<Map<String, dynamic>> sendImageToGPT(
  Uint8List imageBytes, {
  required bool isProductList,
  required String company,
}) async {
  const apiKey = String.fromEnvironment('OPENAI_API_KEY');
  const modelName = String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-5-mini');

  if (apiKey.isEmpty) {
    throw Exception('OpenAI APIキーが設定されていません。');
  }

  final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
  final base64Image = base64Encode(imageBytes);
  final prompt = isProductList ? _buildProductListPrompt(company) : _buildNifudaPrompt();

  final body = jsonEncode({
    'model': modelName,
    'messages': [
      {'role': 'system', 'content': prompt},
      {
        'role': 'user',
        'content': [
          {
            'type': 'image_url',
            'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
          }
        ]
      }
    ],
    // ★★★ 根本原因の修正: 応答が途中で切れないよう、トークン上限を十分に確保 ★★★
    'max_completion_tokens': 4000,
    // JSONモードを有効にする
    'response_format': {'type': 'json_object'},
  });

  try {
    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 200) {
      if (kDebugMode) {
        print('GPT Raw Response Body: ${utf8.decode(response.bodyBytes)}');
      }

      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonResponse['choices'] != null && jsonResponse['choices'].isNotEmpty) {
        final contentString = jsonResponse['choices'][0]['message']['content'];
        // contentが空文字列の場合、解析エラーを防ぐ
        if (contentString == null || contentString.isEmpty) {
          final finishReason = jsonResponse['choices'][0]['finish_reason'];
          throw Exception('GPTからの応答が空です。Finish Reason: $finishReason');
        }
        
        try {
          if (kDebugMode) {
            print('GPT Parsed Content String: $contentString');
          }
          return jsonDecode(contentString);
        } catch (e) {
          throw Exception('GPTの応答JSON解析に失敗: $contentString');
        }
      } else {
        throw Exception('GPTからの応答に有効なデータがありません。');
      }
    } else {
      throw Exception('GPT APIエラー: ${response.statusCode}\n${utf8.decode(response.bodyBytes)}');
    }
  } catch (e) {
    debugPrint('GPTへの画像送信エラー: $e');
    rethrow;
  }
}