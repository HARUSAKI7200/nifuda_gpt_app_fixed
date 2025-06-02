// lib/utils/excel_export.dart
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

/// データをExcel（.xlsx）形式でストレージに保存する
Future<String> exportToExcelStorage({
  required String fileName,
  required String sheetName,
  required List<String> headers,
  required List<List<String>> rows,
  required String projectFolderPath, // 追加
  String? subfolder, // 追加 (荷札リスト, 製番リスト, 抽出結果)
}) async {
  if (!Platform.isAndroid) {
    throw Exception('このファイル保存機能はAndroid専用です。');
  }

  if (kDebugMode) {
    print('--- exportToExcelStorage Debug ---');
    print('FileName: $fileName');
    print('Requested SheetName: $sheetName');
    print('Headers: $headers');
    print('Rows count: ${rows.length}');
    if (rows.isNotEmpty) {
      print('First row: ${rows.first}');
    }
    print('Project Folder Path: $projectFolderPath'); // 追加
    print('Subfolder: $subfolder'); // 追加
  }

  var excel = Excel.createExcel();
  
  final String initialSheetName = excel.sheets.keys.first;
  Sheet sheetObject = excel[initialSheetName];

  var headerStyle = CellStyle(bold: true, horizontalAlign: HorizontalAlign.Center);

  final headerCells = headers.map((h) => TextCellValue(h)).toList();
  sheetObject.appendRow(headerCells);

  for (var i = 0; i < headers.length; i++) {
    var cell = sheetObject.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
    cell.cellStyle = headerStyle;
  }
  
  for (var row in rows) {
    sheetObject.appendRow(row.map((cell) => TextCellValue(cell ?? '')).toList());
  }

  if (initialSheetName != sheetName) {
    excel.rename(initialSheetName, sheetName);
    if (kDebugMode) print('Renamed sheet from "$initialSheetName" to "$sheetName"');
  } else {
    if (kDebugMode) print('Sheet name is already "$sheetName", no rename needed.');
  }

  var status = await Permission.storage.request();
  if (!status.isGranted) {
    if (!await Permission.manageExternalStorage.request().isGranted) {
       throw Exception('ストレージへのアクセス権限が拒否されました。');
    }
  }

  // 保存先パスを projectFolderPath/subfolder に変更
  String directoryPathForMessage = "";
  Directory directory;
  try {
    String targetPath = projectFolderPath;
    if (subfolder != null) {
      targetPath = p.join(projectFolderPath, subfolder);
      directoryPathForMessage = p.join(p.basename(projectFolderPath), subfolder); // メッセージ用に短縮パスを生成
    } else {
      directoryPathForMessage = p.basename(projectFolderPath); // メッセージ用に短縮パスを生成
    }
    
    directory = Directory(targetPath);

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    if (kDebugMode) print('Target Directory: ${directory.path}');
  } catch (e) {
      debugPrint('ディレクトリ作成エラー: $e');
      throw Exception('保存先ディレクトリの作成に失敗しました: $e');
  }

  final filePath = p.join(directory.path, fileName);
  final fileBytes = excel.save(fileName: fileName);

  if (kDebugMode) {
    print('FileBytes generated: ${fileBytes != null ? fileBytes.length : 'null'} bytes');
  }

  if (fileBytes != null) {
    try {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
      if (kDebugMode) print('Excel file saved to: $filePath');
    } catch (e) {
      debugPrint('ファイル書き込みエラー: $e');
      throw Exception('ファイル書き込みに失敗しました: $filePath, エラー: $e');
    }
  } else {
    throw Exception('Excelファイルのエンコードに失敗しました。');
  }

  return '$directoryPathForMessage フォルダ内の $fileName';
}