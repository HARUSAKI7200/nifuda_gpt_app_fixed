// lib/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

part '../models/app_collections.dart'; 
part 'app_database.g.dart';

// ★ データベースの接続 (変更なし)
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'app_database.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final cachebase = (await getTemporaryDirectory()).path;
    sqlite3.tempDirectory = cachebase;

    return NativeDatabase.createInBackground(file);
  });
}

// ★★★ ここからDAO (変更なし) ★★★

// 1. プロジェクト (Projects) テーブル用のDAO
@DriftAccessor(tables: [Projects])
class ProjectsDao extends DatabaseAccessor<AppDatabase> with _$ProjectsDaoMixin {
  ProjectsDao(AppDatabase db) : super(db);

  Stream<List<Project>> watchAllProjects() => select(projects).watch();
  
  Future<List<Project>> getAllProjectsSorted() {
    return (select(projects)..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])).get();
  }

  Future<Project> getProject(int id) => (select(projects)..where((t) => t.id.equals(id))).getSingle();

  Future<Project> upsertProject(ProjectsCompanion entry) async {
    return await into(projects).insertReturning(
      entry, 
      onConflict: DoUpdate(
        (old) => entry, 
        target: [projects.projectCode] 
      )
    );
  }
}

// 2. 荷札 (NifudaRows) テーブル用のDAO
@DriftAccessor(tables: [NifudaRows])
class NifudaRowsDao extends DatabaseAccessor<AppDatabase> with _$NifudaRowsDaoMixin {
  NifudaRowsDao(AppDatabase db) : super(db);

  Future<List<NifudaRow>> getAllNifudaRows(int projectId) {
    return (select(nifudaRows)..where((t) => t.projectId.equals(projectId))).get();
  }

  Future<void> batchInsertNifudaRows(List<NifudaRowsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(nifudaRows, entries);
    });
  }
}

// 3. 製品リスト (ProductListRows) テーブル用のDAO
@DriftAccessor(tables: [ProductListRows])
class ProductListRowsDao extends DatabaseAccessor<AppDatabase> with _$ProductListRowsDaoMixin {
  ProductListRowsDao(AppDatabase db) : super(db);

  Future<List<ProductListRow>> getAllProductListRows(int projectId) {
    return (select(productListRows)..where((t) => t.projectId.equals(projectId))).get();
  }

  Future<void> batchInsertProductListRows(List<ProductListRowsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(productListRows, entries);
    });
  }
}

// ★★★ データベース本体 (変更なし) ★★★
@DriftDatabase(
  tables: [Projects, NifudaRows, ProductListRows],
  daos: [ProjectsDao, NifudaRowsDao, ProductListRowsDao]
)
class AppDatabase extends _$AppDatabase {
  
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}