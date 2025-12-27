import 'package:flutter/material.dart';

/// 撮影の仕方ガイドを表示するダイアログ
void showPhotoGuide(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('撮影の仕方'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8, // 画面幅の80%
        height: MediaQuery.of(context).size.height * 0.6, // 画面高さの60%
        child: Image.asset( // pubspec.yaml で assets/photo_guide_sample.png を定義しておくこと
          'assets/photo_guide_sample.png',
          fit: BoxFit.contain,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    ),
  );
}