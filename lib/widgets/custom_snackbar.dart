// lib/widgets/custom_snackbar.dart
import 'package:flutter/material.dart';

// ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
// ★ 変更点：関数名をshowCustomSnackBarに変更し、showAtTopパラメータを追加
// ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
void showCustomSnackBar(BuildContext context, String message, {bool isError = false, int durationSeconds = 3, bool showAtTop = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      // ★ 変更点：showAtTopの値に応じてmarginとdismissDirectionを切り替え
      // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
      margin: showAtTop
          ? const EdgeInsets.only( // 画面上部に表示する場合
              top: 15,
              left: 15,
              right: 15,
            )
          : const EdgeInsets.only( // 画面下部に表示する場合（デフォルト）
              bottom: 15,
              left: 15,
              right: 15,
            ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      duration: Duration(seconds: durationSeconds),
      dismissDirection: showAtTop ? DismissDirection.up : DismissDirection.down, // 位置に合わせてスワイプ方向も変更
    ),
  );
}

