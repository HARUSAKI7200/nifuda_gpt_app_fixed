// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ★ 追加: riverpod
import 'package:flutter_logs/flutter_logs.dart'; // ★ 追加: flutter_logs
import 'pages/home_page.dart';

// main関数をProviderScopeでラップし、ログハンドリングを設定
Future<void> main() async { // Future<void> async に変更
  WidgetsFlutterBinding.ensureInitialized();
  
  // ★ 縦向き（ポートレート）に固定する処理を追加
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 縦向き（上）
    DeviceOrientation.portraitDown, // 縦向き（下）
  ]);
  
  // ★★★ flutter_logs の初期化とエラーハンドリング設定 ★★★
  await FlutterLogs.initLogs(
    logLevelsEnabled: [
      LogLevel.INFO,
      LogLevel.WARNING,
      LogLevel.ERROR,
      LogLevel.SEVERE,
    ],
    directoryStructure: DirectoryStructure.FOR_DATE, // ★ 修正: String -> Enum
    logFileExtension: LogFileExtension.LOG, // ★ 修正: String -> Enum
    logfileName: "APP_LOGS", // ★ 修正: logFileName -> logfileName
    isAndroid: true, isIOS: false, // Androidのみを想定してiOSをfalseに
    isDebuggable: true,
  );
  
  // Flutterフレームワークのエラーハンドリング (キャッチされないエラーをログファイルに保存)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // ★ 修正: message: -> logMessage:, stacktrace: -> stackTrace:
    FlutterLogs.logThis(
      tag: 'APP_ERROR', 
      subTag: 'Unhandled_Flutter_Error', 
      logMessage: details.exceptionAsString(), // ★ 修正
      stackTrace: details.stack, // ★ 修正: (camelCase)
      type: LogLevel.SEVERE,
    );
  };
  
  // riverpodのProviderScopeでラップしてアプリケーションを起動
  runApp(const ProviderScope(child: MyApp())); 
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'シンコー府中輸出課 荷札照合アプリ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // ★ NotoSansJPフォントをアプリ全体に適用
        fontFamily: 'NotoSerifJP', // 👈 ここをNotoSerifJPに変更します
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'NotoSerifJP', // AppBarにも明示的に適用します
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(150, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              fontFamily: 'NotoSerifJP', // ボタンにも明示的に適用します
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo[600],
          foregroundColor: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}