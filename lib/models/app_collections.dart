// lib/models/app_collections.dart

// このファイルが 'app_database.dart' の一部であることを宣言
part of '../database/app_database.dart';

// ★ 1. プロジェクト
@DataClassName('Project') 
class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectCode => text().unique()();
  TextColumn get projectTitle => text()();
  TextColumn get inspectionStatus => text()(); 
  TextColumn get projectFolderPath => text()();
}

// ★ 2. 荷札
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
  
  // ★★★ 修正: ここに caseNumber を追加 ★★★
  TextColumn get caseNumber => text().named('case_number')(); 
}

// ★ 3. 製品リスト
@DataClassName('ProductListRow')
@TableIndex(name: 'product_list_project_id_idx', columns: {#projectId})
class ProductListRows extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get projectId => integer().named('project_id')();
  TextColumn get orderNo => text().named('order_no')(); 
  TextColumn get itemOfSpare => text().named('item_of_spare')(); 
  TextColumn get productSymbol => text().named('product_symbol')(); 
  TextColumn get formSpec => text().named('form_spec')(); 
  TextColumn get productCode => text().named('product_code')(); 
  TextColumn get orderQuantity => text().named('order_quantity')(); 
  TextColumn get article => text().named('article')(); 
  TextColumn get note => text().named('note')(); 
  TextColumn get matchedCase => text().nullable()();
}

// ★ 4. マスク設定
@DataClassName('MaskProfile')
class MaskProfiles extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get profileName => text().unique()(); // 設定名（会社名）
  TextColumn get rectsJson => text()(); // 範囲データ(Rectのリスト)をJSON文字列で保存
}