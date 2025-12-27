// lib/state/project_state.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:drift/drift.dart';

import '../database/app_database.dart';
import '../utils/prompt_definitions.dart';

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
  final String currentCaseNumber;
  final String? jsonSavePath;

  final List<List<String>> nifudaData;
  final List<List<String>> productListKariData;
  final bool isLoading;
  final String selectedCompany;
  final String selectedMatchingPattern;
  
  final List<MaskProfile> maskProfiles;

  // ★ 追加: 現在の製品リストのヘッダー（動的に変わるため）
  final List<String> currentProductListHeader;

  const ProjectState({
    this.currentProjectId,
    required this.projectTitle,
    required this.inspectionStatus,
    required this.projectFolderPath,
    required this.currentCaseNumber,
    this.jsonSavePath,
    required this.nifudaData,
    required this.productListKariData,
    required this.isLoading,
    required this.selectedCompany,
    required this.selectedMatchingPattern,
    required this.maskProfiles,
    required this.currentProductListHeader, // ★ 追加
  });

  ProjectState copyWith({
    Value<int?>? currentProjectId,
    String? projectTitle,
    String? inspectionStatus,
    String? projectFolderPath,
    String? currentCaseNumber,
    Value<String?>? jsonSavePath,
    List<List<String>>? nifudaData,
    List<List<String>>? productListKariData,
    bool? isLoading,
    String? selectedCompany,
    String? selectedMatchingPattern,
    List<MaskProfile>? maskProfiles,
    List<String>? currentProductListHeader, // ★ 追加
  }) {
    return ProjectState(
      currentProjectId: currentProjectId == null ? this.currentProjectId : currentProjectId.value,
      projectTitle: projectTitle ?? this.projectTitle,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      projectFolderPath: projectFolderPath ?? this.projectFolderPath,
      currentCaseNumber: currentCaseNumber ?? this.currentCaseNumber,
      jsonSavePath: jsonSavePath == null ? this.jsonSavePath : jsonSavePath.value,
      nifudaData: nifudaData ?? this.nifudaData,
      productListKariData: productListKariData ?? this.productListKariData,
      isLoading: isLoading ?? this.isLoading,
      selectedCompany: selectedCompany ?? this.selectedCompany,
      selectedMatchingPattern: selectedMatchingPattern ?? this.selectedMatchingPattern,
      maskProfiles: maskProfiles ?? this.maskProfiles,
      currentProductListHeader: currentProductListHeader ?? this.currentProductListHeader,
    );
  }
}

class ProjectNotifier extends StateNotifier<ProjectState> {
  final AppDatabase _db;

  // デフォルトヘッダー（互換性のため）
  static const List<String> _defaultProductListHeader = ['ORDER No.', 'ITEM OF SPARE', '品名記号', '形格', '製品コード番号', '注文数', '記事', '備考', '照合済Case'];

  ProjectNotifier(this._db)
      : super(const ProjectState(
          currentProjectId: null,
          projectTitle: '',
          inspectionStatus: STATUS_PENDING,
          projectFolderPath: null,
          currentCaseNumber: '#1',
          jsonSavePath: null,
          nifudaData: [], 
          productListKariData: [], 
          isLoading: false,
          selectedCompany: 'マスク処理なし',
          selectedMatchingPattern: 'T社（製番・項目番号）',
          maskProfiles: [],
          currentProductListHeader: _defaultProductListHeader,
        )) {
    loadMaskProfiles();
  }

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

  void updateCaseNumber(String caseNumber) {
    state = state.copyWith(currentCaseNumber: caseNumber);
  }

  void updateJsonSavePath(String? path) {
      state = state.copyWith(jsonSavePath: Value(path));
  }
  
  Future<void> loadMaskProfiles() async {
    try {
      final profiles = await _db.maskProfilesDao.getAllProfiles();
      state = state.copyWith(maskProfiles: profiles);
    } catch (e) {
      FlutterLogs.logError('STATE_ACTION', 'LOAD_PROFILES_FAIL', 'Failed to load mask profiles: $e');
    }
  }

  // ====== DB連携ロジック ======

  List<String> get nifudaHeader => const ['製番', '項目番号', '品名', '形式', '個数', '図書番号', '摘要', '手配コード', 'Case No.'];

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
        currentCaseNumber: '#1',
        jsonSavePath: Value(null),
        nifudaData: [nifudaHeader],
        productListKariData: [_defaultProductListHeader],
        currentProductListHeader: _defaultProductListHeader,
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

      final nifudaData = [nifudaHeader];
      nifudaData.addAll(nifudaDbRows.map((row) => [
        row.seiban, row.itemNumber, row.productName, row.form,
        row.quantity, row.documentNumber, row.remarks, row.arrangementCode,
        row.caseNumber,
      ]));

      // ★ 製品リストデータ構築 (動的対応)
      List<List<String>> productListData = [];
      List<String> header = [];

      if (productListDbRows.isNotEmpty) {
        // 1行目を見てヘッダーを決定する
        // contentJsonがある場合はそれを優先、なければ固定カラムから生成
        final firstRow = productListDbRows.first;
        if (firstRow.contentJson != null && firstRow.contentJson!.isNotEmpty) {
          try {
            final Map<String, dynamic> firstMap = jsonDecode(firstRow.contentJson!);
            // JSONのキーをヘッダーとする (照合済Caseは別途追加)
            header = firstMap.keys.toList();
            // 照合用キーがなければ追加しておく（表示の都合）
            if (!header.contains('照合済Case')) header.add('照合済Case');
          } catch (e) {
            header = List.from(_defaultProductListHeader); // パース失敗時はデフォルト
          }
        } else {
          header = List.from(_defaultProductListHeader); // 古いデータの場合
        }

        productListData.add(header);

        // 全行をヘッダーに合わせてリスト化
        for (var row in productListDbRows) {
          if (row.contentJson != null && row.contentJson!.isNotEmpty) {
            try {
              final Map<String, dynamic> map = jsonDecode(row.contentJson!);
              List<String> rowValues = [];
              for (var key in header) {
                if (key == '照合済Case') {
                  rowValues.add(row.matchedCase ?? '');
                } else {
                  rowValues.add(map[key]?.toString() ?? '');
                }
              }
              productListData.add(rowValues);
            } catch (e) {
              // パースエラー時はスキップ
            }
          } else {
            // 古い固定カラムデータの場合
            productListData.add([
              row.orderNo, row.itemOfSpare, row.productSymbol, row.formSpec,
              row.productCode, row.orderQuantity, row.article, row.note, row.matchedCase ?? ''
            ]);
          }
        }
      } else {
        // データがない場合はデフォルトヘッダーのみ
        header = List.from(_defaultProductListHeader);
        productListData.add(header);
      }

      state = state.copyWith(
        currentProjectId: Value(projectId),
        projectTitle: project.projectTitle,
        inspectionStatus: project.inspectionStatus,
        projectFolderPath: project.projectFolderPath,
        currentCaseNumber: '#1',
        jsonSavePath: Value(null),
        nifudaData: nifudaData,
        productListKariData: productListData,
        currentProductListHeader: header, // ★ 現在のヘッダーを保存
      );
      FlutterLogs.logInfo('DB_ACTION', 'LOAD_PROJECT', 'Project $projectId loaded.');

    } catch (e, s) {
      FlutterLogs.logError('DB_ACTION', 'LOAD_PROJECT_FAIL', 'Failed to load project: $e\n$s');
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<void> loadProjectFromJsonData(Map<String, dynamic> jsonData) async {
      setLoading(true);
      try {
          List<List<String>> nifudaData = List<List<String>>.from((jsonData['nifudaData'] as List).map((e) => List<String>.from(e)));
          List<List<String>> productListData = List<List<String>>.from((jsonData['productListKariData'] as List).map((e) => List<String>.from(e)));

          if (nifudaData.isEmpty || (nifudaData.first.isNotEmpty && nifudaData.first[0] != nifudaHeader[0])) {
              nifudaData.insert(0, nifudaHeader);
          }
          // ヘッダーチェックロジックは動的になったため厳密には不要だが、互換性のため残す
          if (productListData.isEmpty) {
              productListData.insert(0, _defaultProductListHeader);
          }

          state = state.copyWith(
              projectTitle: jsonData['projectTitle'],
              projectFolderPath: jsonData['currentProjectFolderPath'],
              nifudaData: nifudaData,
              productListKariData: productListData,
              inspectionStatus: STATUS_IN_PROGRESS,
              currentProjectId: Value(null),
              currentCaseNumber: jsonData['currentCaseNumber'] ?? '#1',
              currentProductListHeader: productListData.isNotEmpty ? productListData[0] : _defaultProductListHeader,
          );
          FlutterLogs.logInfo('STATE_ACTION', 'LOAD_JSON', 'Project state loaded from JSON.');
      } catch (e, s) {
          FlutterLogs.logError('STATE_ACTION', 'LOAD_JSON_FAIL', 'Failed to load project state from JSON: $e\n$s');
          rethrow;
      } finally {
          setLoading(false);
      }
  }

  Future<void> addNifudaRows(List<List<String>> newRows) async {
    if (state.currentProjectId == null) return;
    if (newRows.isEmpty) return;

    final projectId = state.currentProjectId!;
    final currentCaseNumber = state.currentCaseNumber;

    final List<NifudaRowsCompanion> entries = newRows.map((row) {
      String safeGet(int index) => (index < row.length) ? row[index] : '';
      return NifudaRowsCompanion.insert(
        projectId: projectId,
        seiban: safeGet(0),
        itemNumber: safeGet(1),
        productName: safeGet(2),
        form: safeGet(3),
        quantity: safeGet(4),
        documentNumber: safeGet(5),
        remarks: safeGet(6),
        arrangementCode: safeGet(7),
        caseNumber: currentCaseNumber,
      );
    }).toList();

    await _db.nifudaRowsDao.batchInsertNifudaRows(entries);

    final newRowsWithCase = newRows.map((row) => [...row, currentCaseNumber]).toList();
    final currentData = state.nifudaData.isEmpty ? [nifudaHeader] : state.nifudaData;
    final updatedList = List<List<String>>.from(currentData)..addAll(newRowsWithCase);
    state = state.copyWith(
      nifudaData: updatedList,
      inspectionStatus: STATUS_IN_PROGRESS,
    );
    FlutterLogs.logInfo('DB_ACTION', 'ADD_NIFUDA', '${entries.length} nifuda rows added for Case $currentCaseNumber.');
  }

  // ★ 新設: Map形式のデータを追加 (動的スキーマ対応)
  Future<void> addProductListMapRows(List<Map<String, String>> newRows, List<String> headerKeys, PromptDefinition promptDef) async {
    if (state.currentProjectId == null) return;
    if (newRows.isEmpty) return;

    final projectId = state.currentProjectId!;

    final List<ProductListRowsCompanion> entries = newRows.map((rowMap) {
      // 照合用キーの値を取得 (PromptDefinitionのマッピング情報を使用)
      final orderNoVal = rowMap[promptDef.orderNoKey] ?? '';
      final itemNoVal = rowMap[promptDef.itemNoKey] ?? '';

      return ProductListRowsCompanion.insert(
        projectId: projectId,
        // 必須・照合用カラム
        orderNo: orderNoVal,
        itemOfSpare: itemNoVal,
        productSymbol: '', // 互換用ダミー
        orderQuantity: '', // 互換用ダミー
        // 自由データはJSONにして保存
        contentJson: Value(jsonEncode(rowMap)),
        
        // 以下の固定カラムは使わないので空文字
        formSpec: '', productCode: '', article: '', note: '',
        matchedCase: Value(null),
      );
    }).toList();

    await _db.productListRowsDao.batchInsertProductListRows(entries);

    // 画面表示用データの更新
    // ヘッダーが現在のものと異なる場合（初回など）、ヘッダーを更新する
    List<String> currentHeader = state.currentProductListHeader;
    // 「照合済Case」が含まれていない生ヘッダーを用意
    List<String> displayHeader = [...headerKeys, '照合済Case'];

    // もし現在のデータが空（ヘッダーのみ）なら、新しいヘッダーで上書きする
    // プロジェクト内でヘッダー形式は統一される前提
    if (state.productListKariData.length <= 1) {
      currentHeader = displayHeader;
    } 
    
    // 表示用データを再構築
    final newDisplayRows = newRows.map((map) {
      // 現在のヘッダー(currentHeader)の順番に従ってリスト化する
      // '照合済Case' は除外してループし、最後に追加
      final headerWithoutMatched = currentHeader.where((k) => k != '照合済Case').toList();
      return [...headerWithoutMatched.map((k) => map[k] ?? ''), '']; // 末尾は照合済Case (新規なので空)
    }).toList();

    final updatedList = List<List<String>>.from(state.productListKariData);
    if (updatedList.length <= 1 && state.productListKariData.length <= 1) {
       updatedList.clear();
       updatedList.add(currentHeader);
    }
    updatedList.addAll(newDisplayRows);

    state = state.copyWith(
      productListKariData: updatedList,
      currentProductListHeader: currentHeader,
      inspectionStatus: STATUS_IN_PROGRESS,
    );
    FlutterLogs.logInfo('DB_ACTION', 'ADD_PRODUCT_LIST_MAP', '${entries.length} product list rows added (Dynamic).');
  }

  // 旧メソッド (互換性のため残す)
  Future<void> addProductListRows(List<List<String>> newRows) async {
    if (state.currentProjectId == null) return;
    if (newRows.isEmpty) return;

    final projectId = state.currentProjectId!;

    final List<ProductListRowsCompanion> entries = newRows.map((row) {
      String safeGet(int index) => (index < row.length) ? row[index] : '';
      return ProductListRowsCompanion.insert(
        projectId: projectId,
        orderNo: safeGet(0),
        itemOfSpare: safeGet(1),
        productSymbol: safeGet(2),
        formSpec: safeGet(3),
        productCode: safeGet(4),
        orderQuantity: safeGet(5),
        article: safeGet(6),
        note: safeGet(7),
        matchedCase: Value(null),
      );
    }).toList();

    await _db.productListRowsDao.batchInsertProductListRows(entries);

    final newRowsWithMatchedCase = newRows.map((row) => [...row, '']).toList();
    final currentData = state.productListKariData.isEmpty ? [_defaultProductListHeader] : state.productListKariData;
    final updatedList = List<List<String>>.from(currentData)..addAll(newRowsWithMatchedCase);
    state = state.copyWith(
      productListKariData: updatedList,
      inspectionStatus: STATUS_IN_PROGRESS,
    );
    FlutterLogs.logInfo('DB_ACTION', 'ADD_PRODUCT_LIST', '${entries.length} product list rows added (Legacy).');
  }

  Future<void> updateProjectStatus(String status) async {
    state = state.copyWith(inspectionStatus: status);

    if (state.currentProjectId == null) {
      return;
    }

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

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final db = ref.read(appDatabaseInstanceProvider);
  return db;
});

final appDatabaseInstanceProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final projectListStreamProvider = StreamProvider<List<Project>>((ref) {
  final dbAsync = ref.watch(databaseProvider);

  if (dbAsync.isLoading || dbAsync.hasError) {
    return Stream.value([]);
  }

  final db = dbAsync.requireValue;
  return (db.projectsDao.select(db.projects)
         ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)]))
         .watch();
});