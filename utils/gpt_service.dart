import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
// custom_snackbar.dartはここでは直接使用しないためインポートなし

String _buildNifudaPrompt() {
  return '''
あなたは提供された荷札の画像を解析し、以下の項目を抽出してJSONオブジェクト形式で出力するAIです。
各項目名をキーとし、対応する値を文字列として格納してください。
画像中に項目が存在しない場合や読み取れない場合は、そのキーに対する値を空文字列""としてください。
「不明」や「(空欄)」といった文字列は使用しないでください。
個数の表記は、分数表記されていたら、そのまま表記してください。
Oと0がある場合は、二重チェックで表示抽出間違いしないでください。
抽出する値は、値に意味を見出さず、必ず検出された項目の箇所で抽出してください。
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
あなたは「$company」の製品リスト画像を解析するAIです。
まず、表全体の上部または表外に記載されている「ORDER No.」を一つだけ抽出してください。
次に、製品リストの各行から以下の項目を抽出してください。
リストの各行を1つのJSONオブジェクトとし、全ての行をJSON配列としてください。
項目が存在しない場合や読み取れない場合は、そのキーに対する値を空文字列""としてください。
製品リストの整形前OrderNoで、()表記の部分が検出された場合は、その()内の値は破棄してください。
対象項目リスト（各行ごと）：
$fieldsForPrompt

出力は必ず以下のJSON形式に従ってください。
"commonOrderNo" キーには表外から抽出した単一のORDER No.の値を、
"products" キーには製品リストの各行の情報を配列として格納してください。

例:
{
  "commonOrderNo": "QZ83941 FEV2385", // 整形前のORDER No.
  "products": [
    {
      "ITEM OF SPARE": "021",
      "品名記号": "PWB-PL",
      "形格": "ARND-4334A (X10)",
      "製品コード番号": "4KAF4334G001",
      "注文数": "2",
      "記事": "PRINTED WIRING BOARD (Soft No. PSS)",
      "備考": "FFV0001" // 備考は独立して抽出
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
  const modelName = String.fromEnvironment('OPENAI_MODEL', defaultValue: 'gpt-4o');

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
      {'role': 'user', 'content': [{'type': 'image_url', 'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}}]}
    ],
    'max_tokens': isProductList ? 4000 : 1000,
    'temperature': 0.0,
    'response_format': {'type': 'json_object'},
  });

  try {
    final response = await http.post(
      uri,
      headers: {'Authorization': 'Bearer $apiKey', 'Content-Type': 'application/json'},
      body: body,
    ).timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      if (jsonResponse['choices'] != null && jsonResponse['choices'].isNotEmpty) {
        final contentString = jsonResponse['choices'][0]['message']['content'];
        try {
          if (kDebugMode) {
            print('GPT Raw Content String: $contentString'); // デバッグログを維持
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