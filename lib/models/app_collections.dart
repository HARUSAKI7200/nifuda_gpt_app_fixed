// lib/models/app_collections.dart
import 'package:isar/isar.dart';

part 'app_collections.g.dart'; // ★★★ この行を追加 ★★★

// ★★★ 重要: このファイルを作成後、ビルドコマンドを実行すると 'app_collections.g.dart' が生成されます ★★★


// ★ 1. プロジェクト全体を管理するコレクション
@collection
class Project {
  // Isarの自動インクリメントID
  Id id = Isar.autoIncrement;

  // 製番をユニークなインデックスとする
  @Index(unique: true)
  late String projectCode; 
  
  late String projectTitle;
  late String inspectionStatus; // 検品ステータス (例: STATUS_PENDING, IN_PROGRESS)
  
  // ファイルシステムへのパス (参照用)
  late String projectFolderPath; 
}

// ★ 2. 荷札の1行データ
@collection
class NifudaRow {
  Id id = Isar.autoIncrement;

  // どのプロジェクトに属するかを示すID (リレーション)
  @Index()
  late int projectId; 

  // 荷札データ (home_page.dartのヘッダーに基づく)
  late String seiban; // 製番
  late String itemNumber; // 項目番号
  late String productName; // 品名
  late String form; // 形式
  late String quantity; // 個数
  late String documentNumber; // 図書番号
  late String remarks; // 摘要
  late String arrangementCode; // 手配コード
}

// ★ 3. 製品リストの1行データ
@collection
class ProductListRow {
  Id id = Isar.autoIncrement;
  
  // どのプロジェクトに属するかを示すID (リレーション)
  @Index()
  late int projectId;

  // 製品リストデータ (home_page.dartのヘッダーに基づく)
  late String orderNo; // ORDER No.
  late String itemOfSpare; // ITEM OF SPARE
  late String productSymbol; // 品名記号
  late String formSpec; // 形格
  late String productCode; // 製品コード番号
  late String orderQuantity; // 注文数
  late String article; // 記事
  late String note; // 備考
}