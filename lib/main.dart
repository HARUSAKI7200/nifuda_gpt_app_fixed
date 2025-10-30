// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'pages/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // flutter_logs 初期化（timeStampFormat を必ず指定）
  await FlutterLogs.initLogs(
    enabled: true,
    isDebuggable: true,
    logLevelsEnabled: const [
      LogLevel.INFO,
      LogLevel.WARNING,
      LogLevel.ERROR,
      LogLevel.SEVERE,
    ],
    logTypesEnabled: const ["APP_LOGS"],
    logsWriteDirectoryName: "AppLogs",
    logsExportDirectoryName: "AppLogs/Exported",
    directoryStructure: DirectoryStructure.FOR_DATE,
    logFileExtension: LogFileExtension.LOG,
    debugFileOperations: false,
    timeStampFormat: TimeStampFormat.TIME_FORMAT_READABLE, // ★ 必須
  );

  // 未捕捉Flutterエラーをファイル出力
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FlutterLogs.logThis(
      tag: 'APP_ERROR',
      subTag: 'Unhandled_Flutter_Error',
      logMessage: '${details.exceptionAsString()}\n${details.stack}',
      level: LogLevel.SEVERE,
    );
  };

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
        fontFamily: 'NotoSerifJP',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[700],
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.black87,
          contentTextStyle: const TextStyle(color: Colors.white),
          actionTextColor: Colors.amber[200],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.indigo[600],
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        // ★ 修正: CardTheme -> CardThemeData
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
      ),
      // ★ 修正: const HomePage() -> HomePage() に変更
      home: HomePage(),
    );
  }
}