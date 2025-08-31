// lib/widgets/custom_snackbar.dart
import 'package:flutter/material.dart';

void showCustomSnackBar(BuildContext context, String message, {bool isError = false, int durationSeconds = 3, bool showAtTop = false}) {
  // 古いスナックバーが残っていれば消す
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      
      margin: showAtTop
          ? EdgeInsets.only(
              // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
              // ★ 変更点：値を120から140に変更し、表示位置を少し下げる
              // ★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
              bottom: MediaQuery.of(context).size.height - 200, 
              left: 15,
              right: 15,
            )
          : const EdgeInsets.only(
              bottom: 15,
              left: 15,
              right: 15,
            ),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      duration: Duration(seconds: durationSeconds),
      dismissDirection: DismissDirection.down,
    ),
  );
}