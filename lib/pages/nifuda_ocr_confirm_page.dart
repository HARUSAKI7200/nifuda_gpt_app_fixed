import 'package:flutter/material.dart';
// custom_snackbar.dartはここでは直接使用しないためインポートなし

class NifudaOcrConfirmPage extends StatelessWidget {
  final Map<String, dynamic> extractedData;
  final int imageIndex;
  final int totalImages;

  // ★ フィールドの順番をクラス内で静的に定義
  static const List<String> nifudaFields = [
    '製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード'
  ];

  const NifudaOcrConfirmPage({
    super.key,
    required this.extractedData,
    required this.imageIndex,
    required this.totalImages,
  });

  @override
  Widget build(BuildContext context) {
    // 表示用のデータを準備 (表記揺れ吸収)
    final Map<String, String> displayData = {};
    for (String field in nifudaFields) {
        String value = extractedData[field]?.toString() ?? '';
        if (field == '摘要' && value.isEmpty) {
            value = extractedData['適用']?.toString() ?? extractedData['備考']?.toString() ?? '';
        }
        if (field == '個数' && value.isEmpty) {
            value = extractedData['数量']?.toString() ?? '';
        }
        displayData[field] = value;
    }
    // 元データに吸収した値を反映させておく
    // 注意: extractedDataはfinalだが、Mapの内容は変更可能なのでこの操作はOK
    extractedData.addAll(displayData);


    // スナックバーのbottomマージン (custom_snackbar.dartで15px)
    // + スナックバーの高さ目安 (約60px、実際のコンテンツやpaddingで変動)
    // + スナックバーとボタンの間の隙間 (約10px)
    // + MediaQuery.of(context).padding.bottom (デバイスのシステムナビゲーションバーなどのインセット)
    final double buttonBottomPosition = 15.0 + 60.0 + 10.0 + MediaQuery.of(context).padding.bottom;


    return Scaffold(
      appBar: AppBar(
        title: Text('荷札OCR結果確認 ($imageIndex / $totalImages)'),
        automaticallyImplyLeading: false, // 戻るボタンを非表示
      ),
      body: Stack( // ボタンを独立して配置するためにStackを使用
        children: [
          // 既存のコンテンツ（OCR結果テーブル）をExpandedで埋める
          Positioned.fill(
            bottom: buttonBottomPosition + 20, // ボタンの高さとマージンを考慮して下部にパディング
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: DataTable(
                    columns: const [
                        DataColumn(label: Text('項目', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('抽出結果', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: nifudaFields.map((field) {
                        return DataRow(
                            cells: [
                                DataCell(Text(field)),
                                DataCell(Text(displayData[field] ?? '')),
                            ],
                        );
                    }).toList(),
                ),
              ),
            ),
          ),
          // ボタン群を画面下部にPositionedで配置
          Positioned(
            left: 0,
            right: 0,
            bottom: buttonBottomPosition, // スナックバーの少し上に配置
            child: Padding( // ボタン自体の左右のパディング
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: const Text('この荷札を破棄'),
                      onPressed: () => Navigator.pop(context, null), // nullを返して破棄
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12), // 垂直パディングのみ
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // ボタン間のスペース
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text('この内容で確定'),
                      onPressed: () => Navigator.pop(context, extractedData), // データを返す
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12), // 垂直パディングのみ
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}