// lib/pages/streaming_progress_dialog.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_logs/flutter_logs.dart';

/// AIからのストリーム応答を受信し、進行状況を表示するダイアログ
class StreamingProgressDialog extends StatefulWidget {
  final Stream<String> stream;
  final String title;

  const StreamingProgressDialog({
    super.key,
    required this.stream,
    required this.title,
  });

  /// ダイアログを表示し、ストリームから受信した生の文字列を返す
  static Future<String?> show({
    required BuildContext context,
    required Stream<String> stream,
    required String title,
    required String serviceTag,
  }) async {
    final String? result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StreamingProgressDialog(stream: stream, title: title),
    );
    
    return result;
  }

  @override
  State<StreamingProgressDialog> createState() => _StreamingProgressDialogState();
}

class _StreamingProgressDialogState extends State<StreamingProgressDialog> {
  final StringBuffer _receivedTextBuffer = StringBuffer();
  String _currentStatus = 'AIが応答を生成中です...';
  bool _isFinished = false;
  StreamSubscription<String>? _streamSubscription;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    _streamSubscription = widget.stream.listen(
      (chunk) {
        if (!_isFinished && !_hasError) {
          _receivedTextBuffer.write(chunk);
          if (mounted) {
            setState(() {
              _currentStatus = 'データ受信中 (${(_receivedTextBuffer.length / 1024).toStringAsFixed(1)} KB)...';
            });
          }
        }
      },
      onError: (error, stack) {
        FlutterLogs.logThis(
          tag: 'STREAMING_DIALOG',
          subTag: 'STREAM_ERROR',
          logMessage: 'Stream failed: $error\n$stack',
          level: LogLevel.ERROR,
        );
        if (mounted) {
          setState(() {
            _currentStatus = 'エラー: 応答の受信に失敗しました。';
            _isFinished = true;
            _hasError = true;
          });
          _streamSubscription?.cancel();
        }
      },
      onDone: () {
        if (mounted && !_hasError) {
          setState(() {
            _currentStatus = '受信完了。解析中...';
            _isFinished = true;
          });
          // 応答テキストを返す
          Navigator.of(context).pop(_receivedTextBuffer.toString());
        } else if (mounted && _hasError) {
          // エラーの場合はnullを返す
          Navigator.of(context).pop(null);
        }
      },
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 300,
        height: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isFinished && !_hasError)
              const LinearProgressIndicator(),
            if (_hasError)
              const Icon(Icons.error_outline, color: Colors.red, size: 30),
            const SizedBox(height: 16),
            Text(
              _currentStatus,
              style: TextStyle(
                color: _hasError ? Colors.red : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        if (_hasError)
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('閉じる'),
          ),
      ],
    );
  }
}