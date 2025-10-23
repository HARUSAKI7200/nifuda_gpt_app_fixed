// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ★ 追加
import 'pages/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // ★ 縦向き（ポートレート）に固定する処理を追加
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp, // 縦向き（上）
    DeviceOrientation.portraitDown, // 縦向き（下）
  ]).then((_) {
    runApp(const MyApp());
  });
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