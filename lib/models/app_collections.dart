// lib/models/app_collections.dart

part of '../database/app_database.dart';

@DataClassName('Project') 
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectCode => text().unique()();
  TextColumn get projectTitle => text()();
  TextColumn get inspectionStatus => text()(); 
  TextColumn get projectFolderPath => text()();
}

@DataClassName('NifudaRow')
@TableIndex(name: 'nifuda_project_id_idx', columns: {#projectId})
class NifudaRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().named('project_id')(); 
  TextColumn get seiban => text().named('seiban')(); 
  TextColumn get itemNumber => text().named('item_number')(); 
  TextColumn get productName => text().named('product_name')(); 
  TextColumn get form => text().named('form')(); 
  TextColumn get quantity => text().named('quantity')(); 
  TextColumn get documentNumber => text().named('document_number')(); 
  TextColumn get remarks => text().named('remarks')(); 
  TextColumn get arrangementCode => text().named('arrangement_code')();
  TextColumn get caseNumber => text().named('case_number')(); 
}

@DataClassName('ProductListRow')
@TableIndex(name: 'product_list_project_id_idx', columns: {#projectId})
class ProductListRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().named('project_id')();
  
  TextColumn get orderNo => text().named('order_no')(); 
  TextColumn get itemOfSpare => text().named('item_of_spare')(); 
  TextColumn get productSymbol => text().named('product_symbol')(); 
  TextColumn get orderQuantity => text().named('order_quantity')(); 
  TextColumn get matchedCase => text().nullable()();

  TextColumn get formSpec => text().named('form_spec')(); 
  TextColumn get productCode => text().named('product_code')(); 
  TextColumn get article => text().named('article')(); 
  TextColumn get note => text().named('note')(); 

  TextColumn get contentJson => text().nullable()();
}

// ★ 拡張: マスク設定改め「作業プロファイル」
@DataClassName('MaskProfile')
class MaskProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get profileName => text().unique()(); // 会社名・生産課名
  TextColumn get rectsJson => text()(); // 黒塗り座標JSON
  
  TextColumn get promptId => text().nullable()(); // 互換性のため残す

  TextColumn get productListFieldsJson => text().nullable()(); // 製品リストの項目定義 (List<String>)
  // ★ 新規追加: 荷札の項目定義 (List<String>)
  TextColumn get nifudaFieldsJson => text().nullable()(); 
  
  TextColumn get matchingPairsJson => text().nullable()(); // 照合ペア設定 (Map<String, String>)
  TextColumn get extractionMode => text().nullable()(); // 抽出モード (standard, tmeic, etc.)
}

@DataClassName('User')
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get username => text().unique()(); 
  TextColumn get password => text().nullable()(); 
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}