// lib/utils/excel_export.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smb_connect/smb_connect.dart'; // ★ 公開APIのみを使用

/// データをExcel（.xlsx）形式でローカル及びSMB共有フォルダに保存する
/// 戻り値: {'local': 'ローカル保存結果メッセージ', 'smb': 'SMB保存結果メッセージ'}
Future<Map<String, String>> exportToExcelStorage({
  required String fileName,
  required String sheetName,
  required List<String> headers,
  required List<List<String>> rows,
  required String projectFolderPath,
  String? subfolder,
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
    print('Project Folder Path: $projectFolderPath');
    print('Subfolder: $subfolder');
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

  // ★ 権限チェック
  var status = await Permission.storage.request();
  if (!status.isGranted) {
    if (!await Permission.manageExternalStorage.request().isGranted) {
       throw Exception('ストレージへのアクセス権限が拒否されました。');
    }
  }

  // ★ 1. ローカル保存
  String directoryPathForMessage = "";
  Directory directory;
  String localFilePath = "";
  final fileBytes = excel.save(fileName: fileName); // ★ Excelデータをバイトとして取得

  if (fileBytes == null) {
    throw Exception('Excelファイルのエンコードに失敗しました。');
  }

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

    localFilePath = p.join(directory.path, fileName);

    final file = File(localFilePath);
    await file.writeAsBytes(fileBytes);
    if (kDebugMode) print('Excel file saved to: $localFilePath');

  } catch (e) {
      debugPrint('ローカル保存エラー: $e');
      throw Exception('ローカル保存に失敗しました: $localFilePath, エラー: $e');
  }

  // ★ 2. SMB共有フォルダへのアップロード
  String smbMessage = "SMB設定が無効";
  try {
    final prefs = await SharedPreferences.getInstance();

    // 有効なプロファイルを検索
    List<Map<String, dynamic>> profiles = [];
    if (prefs.getBool('smb_use_1') ?? false) {
      profiles.add({
        'name': 'プロファイル1',
        'host': prefs.getString('smb_host_1') ?? '',
        'share': prefs.getString('smb_share_1') ?? '',
        'path': prefs.getString('smb_path_1') ?? '',
        'domain': prefs.getString('smb_domain_1') ?? '',
        'user': prefs.getString('smb_user_1') ?? '',
        'pass': prefs.getString('smb_pass_1') ?? '',
      });
    }
    if (prefs.getBool('smb_use_2') ?? false) {
       profiles.add({
        'name': 'プロファイル2',
        'host': prefs.getString('smb_host_2') ?? '',
        'share': prefs.getString('smb_share_2') ?? '',
        'path': prefs.getString('smb_path_2') ?? '',
        'domain': prefs.getString('smb_domain_2') ?? '',
        'user': prefs.getString('smb_user_2') ?? '',
        'pass': prefs.getString('smb_pass_2') ?? '',
      });
    }

    if (profiles.isEmpty) {
      // smbMessageは初期値("SMB設定が無効")のまま
    } else {
      List<String> successMessages = [];
      List<String> errorMessages = [];

      for (var profile in profiles) {
        if (profile['host'].isEmpty || profile['share'].isEmpty || profile['user'].isEmpty || profile['pass'].isEmpty) {
           errorMessages.add("${profile['name']}: 設定不備");
           continue;
        }

        // ★★★ ここから v0.0.9 公式API準拠への修正 ★★★
        SmbConnect? smbConnection; // SmbConnect.connectAuthの戻り値を受け取る変数
        try {
          // ★ 修正: SmbConnect.connectAuth 静的メソッドで接続・認証
          // ★ 注意: v0.0.9 では connectAuth に share を渡せません
          if (kDebugMode) print("Connecting to SMB: ${profile['host']} with user ${profile['user']}");
          smbConnection = await SmbConnect.connectAuth(
            host: profile['host'],
            username: profile['user'],
            password: profile['pass'],
            domain: profile['domain'].isNotEmpty ? profile['domain'] : null,
            // share: profile['share'], // v0.0.9 にはこの引数はない
          );
          if (kDebugMode) print("SMB Connected.");

          // ★ 修正: 共有名をパスの先頭に含める
          String basePath = "/${profile['share']}"; // パスは /share_name/ から始める
          String relativePath = profile['path'];
          if (subfolder != null) {
            relativePath = p.posix.join(relativePath, subfolder);
          }
          String fullSmbDirectoryPath = p.posix.join(basePath, relativePath);

          if (kDebugMode) print("SMB target directory (full path): $fullSmbDirectoryPath");

          // ★ 修正: ディレクトリ作成は createFolder を試行し、エラーを無視する方式
          List<String> pathSegments = fullSmbDirectoryPath.split('/').where((s) => s.isNotEmpty).toList();
          String currentPathToCreate = "";
          for (String segment in pathSegments) {
            // ★ 重要: パスの先頭に / を付ける必要がある
            currentPathToCreate = "/$segment"; // v0.0.9のcreateFolderはルートからの絶対パスに見える
            if (pathSegments.indexOf(segment) > 0) {
               currentPathToCreate = p.posix.join(
                 "/${pathSegments.sublist(0, pathSegments.indexOf(segment)).join('/')}",
                 segment
               );
            }
             // 絶対パス形式にする (/share/folder1, /share/folder1/folder2 ...)
            currentPathToCreate = "/${currentPathToCreate.split('/').where((s)=> s.isNotEmpty).join('/')}";

            try {
              if (kDebugMode) print("Attempting to create SMB directory: $currentPathToCreate");
              await smbConnection.createFolder(currentPathToCreate);
              if (kDebugMode) print("SMB directory created or already exists: $currentPathToCreate");
            } catch (e) {
              // フォルダが既に存在する場合などのエラーは無視する
              // 厳密にはエラーの種類を判定すべきだが、ここでは簡略化
              if (kDebugMode) print("Ignoring error during createFolder for $currentPathToCreate: $e");
            }
          }

          // ファイル書き込みパス (共有名を含むフルパス)
          final smbFilePath = p.posix.join(fullSmbDirectoryPath, fileName);
           // パスを整形 (例: //share/folder//file -> /share/folder/file)
          final normalizedSmbFilePath = "/${smbFilePath.split('/').where((s)=> s.isNotEmpty).join('/')}";

          if (kDebugMode) print("Attempting to create SMB file: $normalizedSmbFilePath");
          // ★ 修正: createFile はパス文字列を受け取る
          final smbFile = await smbConnection.createFile(normalizedSmbFilePath);

          if (kDebugMode) print("Attempting to open SMB file for write: $normalizedSmbFilePath");
          // ★ 修正: openWrite は SmbFile を受け取る
          var sink = await smbConnection.openWrite(smbFile);
          sink.add(fileBytes);
          await sink.flush();
          await sink.close();

          if (kDebugMode) print("SMB file written: $normalizedSmbFilePath");
          successMessages.add(profile['name']);

        } catch (e) {
          if (kDebugMode) print("SMB Error (${profile['name']}): $e");
          // エラーメッセージに詳細を含める
          errorMessages.add("${profile['name']}失敗: ${e.toString().split('\n').first}"); // エラーメッセージの1行目のみ表示
        } finally {
          // ★ 修正: close() は connectAuth の戻り値 (SmbConnectインスタンス) に対して呼ぶ
          await smbConnection?.close();
           if (kDebugMode) print("SMB Connection closed for ${profile['name']}.");
        }
        // ★★★ エラー修正ここまで ★★★
      }

      // メッセージの組み立て
      if (successMessages.isNotEmpty) {
        smbMessage = "${successMessages.join(', ')} へ保存成功。";
      }
      if (errorMessages.isNotEmpty) {
        if (successMessages.isNotEmpty) smbMessage += " "; // 成功メッセージがある場合、スペースを追加
        smbMessage += "(${errorMessages.join('; ')})";
      }
      // 両方空の場合は初期値("SMB設定が無効")のまま or エラーが発生した場合
      if (successMessages.isEmpty && errorMessages.isEmpty && profiles.isNotEmpty) {
         smbMessage = "SMB保存試行失敗。"; // 設定はあるが何らかの理由で試行できなかった場合
      } else if (successMessages.isEmpty && errorMessages.isNotEmpty) {
         smbMessage = "SMB保存失敗。(${errorMessages.join('; ')})"; // エラーのみの場合
      }

    }

  } catch (e) {
    if (kDebugMode) print("SMB Upload General Error: $e");
    smbMessage = "SMBアップロード処理エラー";
  }

  // ★ 戻り値をMapに変更
  return {
    'local': '$directoryPathForMessage 内の $fileName',
    'smb': smbMessage,
  };
}