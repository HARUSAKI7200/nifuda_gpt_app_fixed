// lib/state/project_state.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_logs/flutter_logs.dart';
import '../models/app_collections.dart';
// ★ 追加: 生成されたスキーマ
import '../models/app_collections.g.dart'; // ★ 修正: Isarスキーマをインポート


// ★★★ 定数定義: 進捗ステータス (home_page.dartから移動) ★★★
const String STATUS_PENDING = '検品前';
const String STATUS_IN_PROGRESS = '検品中';
const String STATUS_COMPLETED = '検品完了';


// 状態クラス
class ProjectState {
  final String projectTitle;
  final String inspectionStatus;
  final String? projectFolderPath;
  final List<List<String>> nifudaData;
  final List<List<String>> productListKariData;
  final bool isLoading;
  final String selectedCompany;
  final String selectedMatchingPattern;

  ProjectState({
    this.projectTitle = '(新規プロジェクト)',
    this.inspectionStatus = STATUS_PENDING,
    this.projectFolderPath,
    required this.nifudaData,
    required this.productListKariData,
    this.isLoading = false,
    this.selectedCompany = 'T社',
    this.selectedMatchingPattern = 'T社（製番・項目番号）',
  });

  ProjectState copyWith({
    String? projectTitle,
    String? inspectionStatus,
    String? projectFolderPath,
    List<List<String>>? nifudaData,
    List<List<String>>? productListKariData,
    bool? isLoading,
    String? selectedCompany,
    String? selectedMatchingPattern,
  }) {
    return ProjectState(
      projectTitle: projectTitle ?? this.projectTitle,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      projectFolderPath: projectFolderPath, // nullが許可されているためそのまま代入
      nifudaData: nifudaData ?? this.nifudaData,
      productListKariData: productListKariData ?? this.productListKariData,
      isLoading: isLoading ?? this.isLoading,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      selectedMatchingPattern: selectedMatchingPattern ?? this.selectedMatchingPattern,
    );
  }
}

// State Notifier (状態を変更するロジック)
class ProjectNotifier extends StateNotifier<ProjectState> {
  // ★ Isarインスタンスを格納するフィールド
  late Future<Isar> isarInstance;

  ProjectNotifier()
      : super(ProjectState(
          nifudaData: [
            ['製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード']
          ],
          productListKariData: [
            ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考']
          ],
        )) {
      // NotifierのコンストラクタでIsarの初期化を開始
      isarInstance = _initializeIsar();
  }
  
  // ★ Isarの初期化を実装
  Future<Isar> _initializeIsar() async {
    final dir = await getApplicationSupportDirectory();
    final dbPath = dir.path;
    
    if (Isar.instanceNames.contains('default')) {
      // ★ 修正: message: -> logMessage:
      FlutterLogs.logThis(
        tag: 'ISAR_INIT', 
        subTag: 'REDUNDANT_CALL', 
        logMessage: 'Isar instance already open, closing...', // ★ 修正
        type: LogLevel.WARNING,
      );
      // 既に開いている場合は閉じてから開く（開発中のホットリロード対策）
      await Isar.getInstance('default')?.close();
    }
    
    FlutterLogs.logInfo('ISAR_INIT', 'DB_PATH', 'Attempting to open Isar DB at $dbPath');
    
    try {
        // Isarを正しいSchemaで開く
        final isar = await Isar.open(
          // ★ 修正: インポートしたスキーマを使用
          [ProjectSchema, NifudaRowSchema, ProductListRowSchema], 
          directory: dbPath,
          name: 'default', // インスタンス名
        );
        FlutterLogs.logInfo('ISAR_INIT', 'DB_SUCCESS', 'Isar DB initialized successfully.');
        return isar;
    } catch (e, s) {
        // ★ 修正: message: -> logMessage:, stacktrace: -> stackTrace:
        FlutterLogs.logThis(
          tag: 'ISAR_INIT', 
          subTag: 'DB_FAILED', 
          logMessage: 'Isar DB initialization failed: $e', // ★ 修正
          stackTrace: s, // ★ 修正
          type: LogLevel.SEVERE,
        );
        rethrow; // 失敗したらアプリの起動を停止する
    }
  }


  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void updateProjectData({
    String? projectTitle,
    String? projectFolderPath,
    List<List<String>>? nifudaData,
    List<List<String>>? productListKariData,
    String? inspectionStatus,
  }) {
    state = state.copyWith(
      projectTitle: projectTitle,
      // projectFolderPath: projectFolderPath, // ★ 修正: 重複しているため削除
      nifudaData: nifudaData,
      productListKariData: productListKariData,
      inspectionStatus: inspectionStatus,
      // projectFolderPath は null が許可されているため、明示的に指定
      projectFolderPath: projectFolderPath != null ? projectFolderPath : state.projectFolderPath, 
    );
  }
  
  void updateSelection({String? company, String? matchingPattern}) {
      state = state.copyWith(
          selectedCompany: company,
          selectedMatchingPattern: matchingPattern,
      );
  }
  
  void updateStatus(String status) {
      state = state.copyWith(inspectionStatus: status);
  }
}

// プロバイダーを公開
final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier();
});

// Isarのインスタンスプロバイダー（他でIsarDBにアクセスしたい場合に利用）
final isarProvider = FutureProvider<Isar>((ref) {
    // ProjectNotifierが初期化するIsarインスタンスを公開
    return ref.watch(projectProvider.notifier).isarInstance;
});