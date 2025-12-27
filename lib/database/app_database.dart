// lib/database/app_database.dart
import 'dart:io';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part '../models/app_collections.dart';
part 'app_database.g.dart';

// --- データベースクラス ---

@DriftDatabase(
  tables: [Projects, NifudaRows, ProductListRows, MaskProfiles, Users],
  daos: [ProjectsDao, NifudaRowsDao, ProductListRowsDao, MaskProfilesDao, UsersDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // ★ バージョンを 8 に更新
  @override
  int get schemaVersion => 8;

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
          await m.createTable(maskProfiles);
        }
        if (from < 4) {
          await m.addColumn(maskProfiles, maskProfiles.promptId);
        }
        if (from < 5) {
          await m.createTable(users);
        }
        if (from < 6) {
          await m.addColumn(productListRows, productListRows.contentJson);
        }
        if (from < 7) {
          await m.addColumn(maskProfiles, maskProfiles.productListFieldsJson);
          await m.addColumn(maskProfiles, maskProfiles.matchingPairsJson);
          await m.addColumn(maskProfiles, maskProfiles.extractionMode);
        }
        // ★ バージョン8: 荷札の項目定義用カラム追加
        if (from < 8) {
          await m.addColumn(maskProfiles, maskProfiles.nifudaFieldsJson);
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

@DriftAccessor(tables: [MaskProfiles])
class MaskProfilesDao extends DatabaseAccessor<AppDatabase> with _$MaskProfilesDaoMixin {
  MaskProfilesDao(AppDatabase db) : super(db);

  Future<List<MaskProfile>> getAllProfiles() => select(maskProfiles).get();
  
  Future<MaskProfile?> getProfileByName(String name) {
    return (select(maskProfiles)..where((t) => t.profileName.equals(name))).getSingleOrNull();
  }

  Future<int> insertOrUpdateProfile(MaskProfilesCompanion companion) {
    return into(maskProfiles).insertOnConflictUpdate(companion);
  }
  
  // 互換性のため古いメソッドも残す（基本使わない）
  Future<int> insertProfile(String name, List<String> rectsData, {String? promptId}) {
    return into(maskProfiles).insert(MaskProfilesCompanion.insert(
      profileName: name,
      rectsJson: jsonEncode(rectsData),
      promptId: Value(promptId), 
    ));
  }

  Future<int> deleteProfile(int id) => (delete(maskProfiles)..where((t) => t.id.equals(id))).go();
}

@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(AppDatabase db) : super(db);

  Future<User?> findUserByName(String username) {
    return (select(users)..where((t) => t.username.equals(username))).getSingleOrNull();
  }

  Future<User?> getUserById(int id) {
    return (select(users)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<User>> getAllUsers() {
    return (select(users)..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])).get();
  }

  Future<int> createUser(String username, {String? password}) {
    return into(users).insert(UsersCompanion.insert(
      username: username,
      password: Value(password),
    ));
  }
}