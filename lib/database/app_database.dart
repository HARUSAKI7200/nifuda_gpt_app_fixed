// lib/database/app_database.dart
import 'dart:io';
import 'dart:convert'; // JSON変換用
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
// ★ 修正: FlutterのRectを使うため dart:ui が必要だが、Driftファイル内では通常使わない。
// JSON変換はStringとして扱うのでここではインポート不要。

part '../models/app_collections.dart'; // ★ここを修正
part 'app_database.g.dart';

// --- データベースクラス ---

@DriftDatabase(
  tables: [Projects, NifudaRows, ProductListRows, MaskProfiles], // ★ MaskProfilesを追加
  daos: [ProjectsDao, NifudaRowsDao, ProductListRowsDao, MaskProfilesDao], // ★ MaskProfilesDaoを追加
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // ★ スキーマバージョンを 3 に変更

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) {
        return m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.addColumn(nifudaRows, nifudaRows.caseNumber);
          await m.addColumn(productListRows, productListRows.matchedCase);
        }
        if (from < 3) {
          // ★ バージョン3への更新: MaskProfilesテーブル作成
          await m.createTable(maskProfiles);
        }
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

// --- DAO ---

@DriftAccessor(tables: [Projects])
class ProjectsDao extends DatabaseAccessor<AppDatabase> with _$ProjectsDaoMixin {
  ProjectsDao(AppDatabase db) : super(db);

  Future<Project> upsertProject(ProjectsCompanion entry) async {
    final id = await into(projects).insertOnConflictUpdate(entry);
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
      b.insertAll(nifudaRows, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<NifudaRow>> getAllNifudaRows(int projectId) {
    return (select(nifudaRows)..where((t) => t.projectId.equals(projectId))).get();
  }

  Future<List<NifudaRow>> getNifudaRowsByCase(int projectId, String caseNumber) {
    return (select(nifudaRows)
           ..where((t) => t.projectId.equals(projectId))
           ..where((t) => t.caseNumber.equals(caseNumber))).get();
  }

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
      b.insertAll(productListRows, entries, mode: InsertMode.insertOrReplace);
    });
  }

  Future<List<ProductListRow>> getAllProductListRows(int projectId) {
    return (select(productListRows)..where((t) => t.projectId.equals(projectId))).get();
  }

  Future<int> updateMatchedCase(int rowId, String caseNumber) {
    return (update(productListRows)..where((t) => t.id.equals(rowId)))
           .write(ProductListRowsCompanion(matchedCase: Value(caseNumber)));
  }

  Future<int> clearMatchedCase(int rowId) {
    return (update(productListRows)..where((t) => t.id.equals(rowId)))
           .write(const ProductListRowsCompanion(matchedCase: Value(null)));
  }
}

// ★ 追加: MaskProfilesDao
@DriftAccessor(tables: [MaskProfiles])
class MaskProfilesDao extends DatabaseAccessor<AppDatabase> with _$MaskProfilesDaoMixin {
  MaskProfilesDao(AppDatabase db) : super(db);

  Future<List<MaskProfile>> getAllProfiles() => select(maskProfiles).get();
  
  Future<MaskProfile?> getProfileByName(String name) {
    return (select(maskProfiles)..where((t) => t.profileName.equals(name))).getSingleOrNull();
  }

  // RectのリストをJSON文字列として保存 ("left,top,width,height" のリスト)
  Future<int> insertProfile(String name, List<String> rectsData) {
    return into(maskProfiles).insert(MaskProfilesCompanion.insert(
      profileName: name,
      rectsJson: jsonEncode(rectsData),
    ));
  }
  
  Future<int> deleteProfile(int id) => (delete(maskProfiles)..where((t) => t.id.equals(id))).go();
}