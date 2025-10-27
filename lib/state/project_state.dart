// lib/state/project_state.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:drift/drift.dart'; // ★ 修正: drift全体をインポート

import '../database/app_database.dart'; 

// 進捗ステータス
const String STATUS_PENDING = '検品前';
const String STATUS_IN_PROGRESS = '検品中';
const String STATUS_COMPLETED = '検品完了';

// 状態 (State)
class ProjectState {
  final int? currentProjectId; 
  final String projectTitle;
  final String inspectionStatus;
  final String? projectFolderPath;
  final List<List<String>> nifudaData;
  final List<List<String>> productListKariData;
  final bool isLoading;
  final String selectedCompany;
  final String selectedMatchingPattern;

  const ProjectState({
    this.currentProjectId, 
    required this.projectTitle,
    required this.inspectionStatus,
    required this.projectFolderPath,
    required this.nifudaData,
    required this.productListKariData,
    required this.isLoading,
    required this.selectedCompany,
    required this.selectedMatchingPattern,
  });

  ProjectState copyWith({
    Value<int?>? currentProjectId, 
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
      currentProjectId: currentProjectId == null ? this.currentProjectId : currentProjectId.value,
      projectTitle: projectTitle ?? this.projectTitle,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      projectFolderPath: projectFolderPath ?? this.projectFolderPath,
      nifudaData: nifudaData ?? this.nifudaData,
      productListKariData: productListKariData ?? this.productListKariData,
      isLoading: isLoading ?? this.isLoading,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      selectedMatchingPattern: selectedMatchingPattern ?? this.selectedMatchingPattern,
    );
  }
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  final AppDatabase _db;

  ProjectNotifier(this._db)
      : super(const ProjectState(
          currentProjectId: null, 
          projectTitle: '',
          inspectionStatus: STATUS_PENDING,
          projectFolderPath: null,
          nifudaData: const [],
          productListKariData: const [],
          isLoading: false,
          selectedCompany: 'T社',
          selectedMatchingPattern: 'T社（製番・項目番号）',
        ));

  // ====== 状態操作 ======
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void updateCompany(String company) {
    state = state.copyWith(selectedCompany: company);
  }

  void updateMatchingPattern(String pattern) {
    state = state.copyWith(selectedMatchingPattern: pattern);
  }
  
  void updateSelection({String? company, String? matchingPattern}) {
    state = state.copyWith(
      selectedCompany: company ?? state.selectedCompany,
      selectedMatchingPattern: matchingPattern ?? state.selectedMatchingPattern,
    );
  }

  // ====== DB連携ロジック ======

  final List<String> _nifudaHeader = const ['製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード'];
  final List<String> _productListHeader = const ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考'];

  Future<void> createProject({
    required String projectCode,
    required String projectFolderPath,
  }) async {
    setLoading(true);
    try {
      final entry = ProjectsCompanion.insert(
        projectCode: projectCode,
        projectTitle: projectCode, 
        inspectionStatus: STATUS_IN_PROGRESS,
        projectFolderPath: projectFolderPath,
      );
      final newProject = await _db.projectsDao.upsertProject(entry);

      state = state.copyWith(
        currentProjectId: Value(newProject.id),
        projectTitle: newProject.projectTitle,
        inspectionStatus: newProject.inspectionStatus,
        projectFolderPath: newProject.projectFolderPath,
        nifudaData: [_nifudaHeader], 
        productListKariData: [_productListHeader], 
      );
      FlutterLogs.logInfo('DB_ACTION', 'CREATE_PROJECT', 'Project ${newProject.id} created/updated.');

    } catch (e, s) {
      FlutterLogs.logError('DB_ACTION', 'CREATE_PROJECT_FAIL', 'Failed to create project: $e\n$s');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadProject(Project project) async {
    setLoading(true);
    try {
      final projectId = project.id;
      
      final nifudaFuture = _db.nifudaRowsDao.getAllNifudaRows(projectId);
      final productListFuture = _db.productListRowsDao.getAllProductListRows(projectId);
      
      final results = await Future.wait([nifudaFuture, productListFuture]);
      final nifudaDbRows = results[0] as List<NifudaRow>;
      final productListDbRows = results[1] as List<ProductListRow>;

      final nifudaData = [_nifudaHeader]; 
      nifudaData.addAll(nifudaDbRows.map((row) => [
        row.seiban, row.itemNumber, row.productName, row.form, 
        row.quantity, row.documentNumber, row.remarks, row.arrangementCode
      ]));
      
      final productListData = [_productListHeader]; 
      productListData.addAll(productListDbRows.map((row) => [
        row.orderNo, row.itemOfSpare, row.productSymbol, row.formSpec,
        row.productCode, row.orderQuantity, row.article, row.note
      ]));

      state = state.copyWith(
        currentProjectId: Value(projectId),
        projectTitle: project.projectTitle,
        inspectionStatus: project.inspectionStatus,
        projectFolderPath: project.projectFolderPath,
        nifudaData: nifudaData,
        productListKariData: productListData,
      );
      FlutterLogs.logInfo('DB_ACTION', 'LOAD_PROJECT', 'Project $projectId loaded.');

    } catch (e, s) {
      FlutterLogs.logError('DB_ACTION', 'LOAD_PROJECT_FAIL', 'Failed to load project: $e\n$s');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> addNifudaRows(List<List<String>> newRows) async {
    if (state.currentProjectId == null) return; 
    if (newRows.isEmpty) return;

    final projectId = state.currentProjectId!;
    
    final List<NifudaRowsCompanion> entries = newRows.map((row) {
      return NifudaRowsCompanion.insert(
        projectId: projectId,
        seiban: row[0],
        itemNumber: row[1],
        productName: row[2],
        form: row[3],
        quantity: row[4],
        documentNumber: row[5],
        remarks: row[6],
        arrangementCode: row[7],
      );
    }).toList();

    await _db.nifudaRowsDao.batchInsertNifudaRows(entries);

    final updatedList = List<List<String>>.from(state.nifudaData)..addAll(newRows);
    state = state.copyWith(
      nifudaData: updatedList,
      inspectionStatus: STATUS_IN_PROGRESS, 
    );
    FlutterLogs.logInfo('DB_ACTION', 'ADD_NIFUDA', '${entries.length} nifuda rows added.');
  }

  Future<void> addProductListRows(List<List<String>> newRows) async {
    if (state.currentProjectId == null) return;
    if (newRows.isEmpty) return;
    
    final projectId = state.currentProjectId!;

    final List<ProductListRowsCompanion> entries = newRows.map((row) {
      return ProductListRowsCompanion.insert(
        projectId: projectId,
        orderNo: row[0],
        itemOfSpare: row[1],
        productSymbol: row[2],
        formSpec: row[3],
        productCode: row[4],
        orderQuantity: row[5],
        article: row[6],
        note: row[7],
      );
    }).toList();

    await _db.productListRowsDao.batchInsertProductListRows(entries);

    final updatedList = List<List<String>>.from(state.productListKariData)..addAll(newRows);
    state = state.copyWith(
      productListKariData: updatedList,
      inspectionStatus: STATUS_IN_PROGRESS, 
    );
    FlutterLogs.logInfo('DB_ACTION', 'ADD_PRODUCT_LIST', '${entries.length} product list rows added.');
  }
  
  Future<void> updateProjectStatus(String status) async {
    if (state.currentProjectId == null) {
      state = state.copyWith(inspectionStatus: status);
      return;
    }
    
    state = state.copyWith(inspectionStatus: status);
    
    await _db.projectsDao.upsertProject(
      ProjectsCompanion(
        id: Value(state.currentProjectId!),
        inspectionStatus: Value(status),
        projectCode: Value.absent(),
        projectTitle: Value.absent(),
        projectFolderPath: Value.absent(),
      )
    );
    FlutterLogs.logInfo('DB_ACTION', 'UPDATE_STATUS', 'Project ${state.currentProjectId} status updated to $status.');
  }
}

// Riverpod Provider
final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  final dbAsyncValue = ref.watch(databaseProvider);
  return ProjectNotifier(dbAsyncValue.requireValue);
});

// ★ 修正: Provider -> FutureProvider に変更
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  // AppDatabaseのインスタンスをシングルトンで返す
  // LazyDatabaseが使われているため、`AppDatabase()`の呼び出しは同期的でOK。
  // 実際の接続はDBが最初に使用されるとき (例: .watch() や .get()) に非同期で行われる。
  // ただし、Notifierが .requireValue を使うため、ここではインスタンスを
  // Futureでラップするだけでもよいが、
  // 他のエラーを避けるため、シングルトンインスタンスを ref.read で管理する。
  
  // 変更：シングルトンDBインスタンスを別途Providerで管理
  final db = ref.read(appDatabaseInstanceProvider);
  return db;
});

// ★ 追加: AppDatabaseのシングルトンインスタンス
final appDatabaseInstanceProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});


// プロジェクト一覧をストリーミング
final projectListStreamProvider = StreamProvider<List<Project>>((ref) {
  // ★ 修正: DBが準備できるまで待機
  final dbAsync = ref.watch(databaseProvider);
  
  // DBがロード中またはエラーの場合は、空のStreamを返す
  if (dbAsync.isLoading || dbAsync.hasError) {
    return Stream.value([]);
  }
  
  // DBが利用可能なら、Streamを返す
  final db = dbAsync.requireValue;
  return (db.projectsDao.select(db.projects)
         ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]))
         .watch();
});