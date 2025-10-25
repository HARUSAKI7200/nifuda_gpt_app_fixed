// lib/state/project_state.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_logs/flutter_logs.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/app_collections.dart';

// 進捗ステータス
const String STATUS_PENDING = '検品前';
const String STATUS_IN_PROGRESS = '検品中';
const String STATUS_COMPLETED = '検品完了';

class ProjectState {
  final String projectTitle;
  final String inspectionStatus;
  final String? projectFolderPath;
  final List<List<String>> nifudaData;
  final List<List<String>> productListKariData;
  final bool isLoading;
  final String selectedCompany;
  final String selectedMatchingPattern;

  const ProjectState({
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
  ProjectNotifier()
      : super(const ProjectState(
          projectTitle: '',
          inspectionStatus: STATUS_PENDING,
          projectFolderPath: null,
          nifudaData: const [],
          productListKariData: const [],
          isLoading: false,
          selectedCompany: 'T社',
          selectedMatchingPattern: 'T社（製番・項目番号）',
        ));

  Isar? _isar;
  Completer<Isar>? _isarInitCompleter;

  Future<Isar> _openIsar() async {
    // ★ 修正点：isClosed は存在しないため isOpen を使用
    if (_isar != null && _isar!.isOpen) return _isar!;
    if (_isarInitCompleter != null && !_isarInitCompleter!.isCompleted) {
      return _isarInitCompleter!.future;
    }
    _isarInitCompleter = Completer<Isar>();

    try {
      final dir = await getApplicationSupportDirectory();
      final isar = await Isar.open(
        [ProjectSchema, NifudaRowSchema, ProductListRowSchema],
        directory: dir.path,
        name: 'default',
      );
      _isar = isar;
      _isarInitCompleter!.complete(isar);
      FlutterLogs.logInfo('ISAR_INIT', 'OPEN', 'Isar opened at ${dir.path}');
      return isar;
    } catch (e, s) {
      FlutterLogs.logThis(
        tag: 'ISAR_INIT',
        subTag: 'OPEN_FAILED',
        logMessage: 'Isar open failed\n$s',
        exception: (e is Exception) ? e : Exception(e.toString()),
        level: LogLevel.SEVERE,
      );
      _isarInitCompleter!.completeError(e, s);
      rethrow;
    }
  }

  /// 外部公開: Isar インスタンス（Future）
  Future<Isar> get isarInstance => _openIsar();

  // ====== 状態操作 ======
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void updateStatus(String status) {
    state = state.copyWith(inspectionStatus: status);
  }

  void updateCompany(String company) {
    state = state.copyWith(selectedCompany: company);
  }

  void updateMatchingPattern(String pattern) {
    state = state.copyWith(selectedMatchingPattern: pattern);
  }

  /// HomePage から呼ばれているユーティリティ
  void updateSelection({String? company, String? matchingPattern}) {
    state = state.copyWith(
      selectedCompany: company ?? state.selectedCompany,
      selectedMatchingPattern: matchingPattern ?? state.selectedMatchingPattern,
    );
  }

  /// プロジェクト基本情報やOCR結果の一括更新
  void updateProjectData({
    String? projectTitle,
    String? inspectionStatus,
    String? projectFolderPath,
    List<List<String>>? nifudaData,
    List<List<String>>? productListKariData,
  }) {
    state = state.copyWith(
      projectTitle: projectTitle,
      inspectionStatus: inspectionStatus,
      projectFolderPath: projectFolderPath,
      nifudaData: nifudaData,
      productListKariData: productListKariData,
    );
  }
}

// Riverpod Provider
final projectProvider = StateNotifierProvider<ProjectNotifier, ProjectState>((ref) {
  return ProjectNotifier();
});

// Isar を別所で使いたい場合の公開プロバイダ
final isarProvider = FutureProvider<Isar>((ref) async {
  return ref.watch(projectProvider.notifier).isarInstance;
});
