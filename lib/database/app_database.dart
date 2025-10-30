// lib/database/app_database.dart
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// --- テーブル定義 ---

@DataClassName('Project')
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectCode => text().unique()();
  TextColumn get projectTitle => text()();
  TextColumn get inspectionStatus => text()();
  TextColumn get projectFolderPath => text()();
}

@DataClassName('NifudaRow')
class NifudaRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(Projects, #id)();
  TextColumn get seiban => text()();
  TextColumn get itemNumber => text()();
  TextColumn get productName => text()();
  TextColumn get form => text()();
  TextColumn get quantity => text()();
  TextColumn get documentNumber => text()();
  TextColumn get remarks => text()();
  TextColumn get arrangementCode => text()();
  // ★ 追加: Case No.
  TextColumn get caseNumber => text()();
}

@DataClassName('ProductListRow')
class ProductListRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().references(Projects, #id)();
  TextColumn get orderNo => text()();
  TextColumn get itemOfSpare => text()();
  TextColumn get productSymbol => text()();
  TextColumn get formSpec => text()();
  TextColumn get productCode => text()();
  TextColumn get orderQuantity => text()();
  TextColumn get article => text()();
  TextColumn get note => text()();
  // ★ 追加: 照合済Case (Null許容)
  TextColumn get matchedCase => text().nullable()();
}

// --- データベースクラス ---

@DriftDatabase(tables: [Projects, NifudaRows, ProductListRows], daos: [ProjectsDao, NifudaRowsDao, ProductListRowsDao])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2; // ★ スキーマバージョンを 2 に変更

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // ★ 修正: addColumnの引数を修正 (テーブルインスタンスとカラム定義)
          await m.addColumn(nifudaRows, nifudaRows.caseNumber);
          await m.addColumn(productListRows, productListRows.matchedCase);
        }
        // 今後のバージョンのマイグレーションはここに追加
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}


// --- DAO (Data Access Object) ---

@DriftAccessor(tables: [Projects])
class ProjectsDao extends DatabaseAccessor<AppDatabase> with _$ProjectsDaoMixin {
  ProjectsDao(AppDatabase db) : super(db);

  // ★ 修正: 戻り値を Future<Project> に変更し、挿入/更新後に取得
  Future<Project> upsertProject(ProjectsCompanion entry) async {
    final id = await into(projects).insertOnConflictUpdate(entry);
    // 挿入/更新された行を取得して返す
    return await (select(projects)..where((p) => p.id.equals(id))).getSingle();
  }

  Future<List<Project>> getAllProjects() {
    return select(projects).get();
  }
}

@DriftAccessor(tables: [NifudaRows])
class NifudaRowsDao extends DatabaseAccessor<AppDatabase> with _$NifudaRowsDaoMixin {
  NifudaRowsDao(AppDatabase db) : super(db);

  Future<void> batchInsertNifudaRows(List<NifudaRowsCompanion> entries) {
    return batch((b) {
      // ★ 修正: Replaced -> InsertMode
      b.insertAll(nifudaRows, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<NifudaRow>> getAllNifudaRows(int projectId) {
    return (select(nifudaRows)..where((t) => t.projectId.equals(projectId))).get();
  }

  // 特定のCase No.の荷札データを取得
  Future<List<NifudaRow>> getNifudaRowsByCase(int projectId, String caseNumber) {
    return (select(nifudaRows)
           ..where((t) => t.projectId.equals(projectId))
           ..where((t) => t.caseNumber.equals(caseNumber))).get();
  }

  // 特定のCase No.の荷札データを削除
  Future<int> deleteNifudaRowsByCase(int projectId, String caseNumber) {
    return (delete(nifudaRows)
           ..where((t) => t.projectId.equals(projectId))
           ..where((t) => t.caseNumber.equals(caseNumber))).go();
  }
}

@DriftAccessor(tables: [ProductListRows])
class ProductListRowsDao extends DatabaseAccessor<AppDatabase> with _$ProductListRowsDaoMixin {
  ProductListRowsDao(AppDatabase db) : super(db);

  Future<void> batchInsertProductListRows(List<ProductListRowsCompanion> entries) {
    return batch((b) {
      // ★ 修正: Replaced -> InsertMode
      b.insertAll(productListRows, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<ProductListRow>> getAllProductListRows(int projectId) {
    return (select(productListRows)..where((t) => t.projectId.equals(projectId))).get();
  }

  // 製品リストの照合済みCase No.を更新
  Future<int> updateMatchedCase(int rowId, String caseNumber) {
    return (update(productListRows)..where((t) => t.id.equals(rowId)))
           .write(ProductListRowsCompanion(matchedCase: Value(caseNumber)));
  }

  // 製品リストの照合済みCase No.をクリア
  Future<int> clearMatchedCase(int rowId) {
    return (update(productListRows)..where((t) => t.id.equals(rowId)))
           .write(const ProductListRowsCompanion(matchedCase: Value(null)));
  }
}