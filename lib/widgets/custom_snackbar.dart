// lib/widgets/custom_snackbar.dart
import 'package:flutter/material.dart';

void showTopSnackBar(BuildContext context, String message, {bool isError = false, int durationSeconds = 3}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only( // 下部に表示するためbottomを設定
        bottom: 15, // 画面下からの固定パディング
        left: 15,
        right: 15,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      duration: Duration(seconds: durationSeconds),
      dismissDirection: DismissDirection.down, // 下にスワイプで消える
    ),
  );
}