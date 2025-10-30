// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $ProjectsTable extends Projects with TableInfo<$ProjectsTable, Project> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectCodeMeta =
      const VerificationMeta('projectCode');
  @override
  late final GeneratedColumn<String> projectCode = GeneratedColumn<String>(
      'project_code', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _projectTitleMeta =
      const VerificationMeta('projectTitle');
  @override
  late final GeneratedColumn<String> projectTitle = GeneratedColumn<String>(
      'project_title', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _inspectionStatusMeta =
      const VerificationMeta('inspectionStatus');
  @override
  late final GeneratedColumn<String> inspectionStatus = GeneratedColumn<String>(
      'inspection_status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _projectFolderPathMeta =
      const VerificationMeta('projectFolderPath');
  @override
  late final GeneratedColumn<String> projectFolderPath =
      GeneratedColumn<String>('project_folder_path', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, projectCode, projectTitle, inspectionStatus, projectFolderPath];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(Insertable<Project> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_code')) {
      context.handle(
          _projectCodeMeta,
          projectCode.isAcceptableOrUnknown(
              data['project_code']!, _projectCodeMeta));
    } else if (isInserting) {
      context.missing(_projectCodeMeta);
    }
    if (data.containsKey('project_title')) {
      context.handle(
          _projectTitleMeta,
          projectTitle.isAcceptableOrUnknown(
              data['project_title']!, _projectTitleMeta));
    } else if (isInserting) {
      context.missing(_projectTitleMeta);
    }
    if (data.containsKey('inspection_status')) {
      context.handle(
          _inspectionStatusMeta,
          inspectionStatus.isAcceptableOrUnknown(
              data['inspection_status']!, _inspectionStatusMeta));
    } else if (isInserting) {
      context.missing(_inspectionStatusMeta);
    }
    if (data.containsKey('project_folder_path')) {
      context.handle(
          _projectFolderPathMeta,
          projectFolderPath.isAcceptableOrUnknown(
              data['project_folder_path']!, _projectFolderPathMeta));
    } else if (isInserting) {
      context.missing(_projectFolderPathMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Project map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Project(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_code'])!,
      projectTitle: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}project_title'])!,
      inspectionStatus: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}inspection_status'])!,
      projectFolderPath: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}project_folder_path'])!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class Project extends DataClass implements Insertable<Project> {
  final int id;
  final String projectCode;
  final String projectTitle;
  final String inspectionStatus;
  final String projectFolderPath;
  const Project(
      {required this.id,
      required this.projectCode,
      required this.projectTitle,
      required this.inspectionStatus,
      required this.projectFolderPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_code'] = Variable<String>(projectCode);
    map['project_title'] = Variable<String>(projectTitle);
    map['inspection_status'] = Variable<String>(inspectionStatus);
    map['project_folder_path'] = Variable<String>(projectFolderPath);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      projectCode: Value(projectCode),
      projectTitle: Value(projectTitle),
      inspectionStatus: Value(inspectionStatus),
      projectFolderPath: Value(projectFolderPath),
    );
  }

  factory Project.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Project(
      id: serializer.fromJson<int>(json['id']),
      projectCode: serializer.fromJson<String>(json['projectCode']),
      projectTitle: serializer.fromJson<String>(json['projectTitle']),
      inspectionStatus: serializer.fromJson<String>(json['inspectionStatus']),
      projectFolderPath: serializer.fromJson<String>(json['projectFolderPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectCode': serializer.toJson<String>(projectCode),
      'projectTitle': serializer.toJson<String>(projectTitle),
      'inspectionStatus': serializer.toJson<String>(inspectionStatus),
      'projectFolderPath': serializer.toJson<String>(projectFolderPath),
    };
  }

  Project copyWith(
          {int? id,
          String? projectCode,
          String? projectTitle,
          String? inspectionStatus,
          String? projectFolderPath}) =>
      Project(
        id: id ?? this.id,
        projectCode: projectCode ?? this.projectCode,
        projectTitle: projectTitle ?? this.projectTitle,
        inspectionStatus: inspectionStatus ?? this.inspectionStatus,
        projectFolderPath: projectFolderPath ?? this.projectFolderPath,
      );
  Project copyWithCompanion(ProjectsCompanion data) {
    return Project(
      id: data.id.present ? data.id.value : this.id,
      projectCode:
          data.projectCode.present ? data.projectCode.value : this.projectCode,
      projectTitle: data.projectTitle.present
          ? data.projectTitle.value
          : this.projectTitle,
      inspectionStatus: data.inspectionStatus.present
          ? data.inspectionStatus.value
          : this.inspectionStatus,
      projectFolderPath: data.projectFolderPath.present
          ? data.projectFolderPath.value
          : this.projectFolderPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Project(')
          ..write('id: $id, ')
          ..write('projectCode: $projectCode, ')
          ..write('projectTitle: $projectTitle, ')
          ..write('inspectionStatus: $inspectionStatus, ')
          ..write('projectFolderPath: $projectFolderPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, projectCode, projectTitle, inspectionStatus, projectFolderPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Project &&
          other.id == this.id &&
          other.projectCode == this.projectCode &&
          other.projectTitle == this.projectTitle &&
          other.inspectionStatus == this.inspectionStatus &&
          other.projectFolderPath == this.projectFolderPath);
}

class ProjectsCompanion extends UpdateCompanion<Project> {
  final Value<int> id;
  final Value<String> projectCode;
  final Value<String> projectTitle;
  final Value<String> inspectionStatus;
  final Value<String> projectFolderPath;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.projectCode = const Value.absent(),
    this.projectTitle = const Value.absent(),
    this.inspectionStatus = const Value.absent(),
    this.projectFolderPath = const Value.absent(),
  });
  ProjectsCompanion.insert({
    this.id = const Value.absent(),
    required String projectCode,
    required String projectTitle,
    required String inspectionStatus,
    required String projectFolderPath,
  })  : projectCode = Value(projectCode),
        projectTitle = Value(projectTitle),
        inspectionStatus = Value(inspectionStatus),
        projectFolderPath = Value(projectFolderPath);
  static Insertable<Project> custom({
    Expression<int>? id,
    Expression<String>? projectCode,
    Expression<String>? projectTitle,
    Expression<String>? inspectionStatus,
    Expression<String>? projectFolderPath,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectCode != null) 'project_code': projectCode,
      if (projectTitle != null) 'project_title': projectTitle,
      if (inspectionStatus != null) 'inspection_status': inspectionStatus,
      if (projectFolderPath != null) 'project_folder_path': projectFolderPath,
    });
  }

  ProjectsCompanion copyWith(
      {Value<int>? id,
      Value<String>? projectCode,
      Value<String>? projectTitle,
      Value<String>? inspectionStatus,
      Value<String>? projectFolderPath}) {
    return ProjectsCompanion(
      id: id ?? this.id,
      projectCode: projectCode ?? this.projectCode,
      projectTitle: projectTitle ?? this.projectTitle,
      inspectionStatus: inspectionStatus ?? this.inspectionStatus,
      projectFolderPath: projectFolderPath ?? this.projectFolderPath,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectCode.present) {
      map['project_code'] = Variable<String>(projectCode.value);
    }
    if (projectTitle.present) {
      map['project_title'] = Variable<String>(projectTitle.value);
    }
    if (inspectionStatus.present) {
      map['inspection_status'] = Variable<String>(inspectionStatus.value);
    }
    if (projectFolderPath.present) {
      map['project_folder_path'] = Variable<String>(projectFolderPath.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('projectCode: $projectCode, ')
          ..write('projectTitle: $projectTitle, ')
          ..write('inspectionStatus: $inspectionStatus, ')
          ..write('projectFolderPath: $projectFolderPath')
          ..write(')'))
        .toString();
  }
}

class $NifudaRowsTable extends NifudaRows
    with TableInfo<$NifudaRowsTable, NifudaRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NifudaRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _seibanMeta = const VerificationMeta('seiban');
  @override
  late final GeneratedColumn<String> seiban = GeneratedColumn<String>(
      'seiban', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemNumberMeta =
      const VerificationMeta('itemNumber');
  @override
  late final GeneratedColumn<String> itemNumber = GeneratedColumn<String>(
      'item_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productNameMeta =
      const VerificationMeta('productName');
  @override
  late final GeneratedColumn<String> productName = GeneratedColumn<String>(
      'product_name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formMeta = const VerificationMeta('form');
  @override
  late final GeneratedColumn<String> form = GeneratedColumn<String>(
      'form', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _quantityMeta =
      const VerificationMeta('quantity');
  @override
  late final GeneratedColumn<String> quantity = GeneratedColumn<String>(
      'quantity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _documentNumberMeta =
      const VerificationMeta('documentNumber');
  @override
  late final GeneratedColumn<String> documentNumber = GeneratedColumn<String>(
      'document_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _remarksMeta =
      const VerificationMeta('remarks');
  @override
  late final GeneratedColumn<String> remarks = GeneratedColumn<String>(
      'remarks', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _arrangementCodeMeta =
      const VerificationMeta('arrangementCode');
  @override
  late final GeneratedColumn<String> arrangementCode = GeneratedColumn<String>(
      'arrangement_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _caseNumberMeta =
      const VerificationMeta('caseNumber');
  @override
  late final GeneratedColumn<String> caseNumber = GeneratedColumn<String>(
      'case_number', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        seiban,
        itemNumber,
        productName,
        form,
        quantity,
        documentNumber,
        remarks,
        arrangementCode,
        caseNumber
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nifuda_rows';
  @override
  VerificationContext validateIntegrity(Insertable<NifudaRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('seiban')) {
      context.handle(_seibanMeta,
          seiban.isAcceptableOrUnknown(data['seiban']!, _seibanMeta));
    } else if (isInserting) {
      context.missing(_seibanMeta);
    }
    if (data.containsKey('item_number')) {
      context.handle(
          _itemNumberMeta,
          itemNumber.isAcceptableOrUnknown(
              data['item_number']!, _itemNumberMeta));
    } else if (isInserting) {
      context.missing(_itemNumberMeta);
    }
    if (data.containsKey('product_name')) {
      context.handle(
          _productNameMeta,
          productName.isAcceptableOrUnknown(
              data['product_name']!, _productNameMeta));
    } else if (isInserting) {
      context.missing(_productNameMeta);
    }
    if (data.containsKey('form')) {
      context.handle(
          _formMeta, form.isAcceptableOrUnknown(data['form']!, _formMeta));
    } else if (isInserting) {
      context.missing(_formMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(_quantityMeta,
          quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta));
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('document_number')) {
      context.handle(
          _documentNumberMeta,
          documentNumber.isAcceptableOrUnknown(
              data['document_number']!, _documentNumberMeta));
    } else if (isInserting) {
      context.missing(_documentNumberMeta);
    }
    if (data.containsKey('remarks')) {
      context.handle(_remarksMeta,
          remarks.isAcceptableOrUnknown(data['remarks']!, _remarksMeta));
    } else if (isInserting) {
      context.missing(_remarksMeta);
    }
    if (data.containsKey('arrangement_code')) {
      context.handle(
          _arrangementCodeMeta,
          arrangementCode.isAcceptableOrUnknown(
              data['arrangement_code']!, _arrangementCodeMeta));
    } else if (isInserting) {
      context.missing(_arrangementCodeMeta);
    }
    if (data.containsKey('case_number')) {
      context.handle(
          _caseNumberMeta,
          caseNumber.isAcceptableOrUnknown(
              data['case_number']!, _caseNumberMeta));
    } else if (isInserting) {
      context.missing(_caseNumberMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NifudaRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NifudaRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      seiban: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}seiban'])!,
      itemNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_number'])!,
      productName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_name'])!,
      form: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form'])!,
      quantity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}quantity'])!,
      documentNumber: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}document_number'])!,
      remarks: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}remarks'])!,
      arrangementCode: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}arrangement_code'])!,
      caseNumber: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}case_number'])!,
    );
  }

  @override
  $NifudaRowsTable createAlias(String alias) {
    return $NifudaRowsTable(attachedDatabase, alias);
  }
}

class NifudaRow extends DataClass implements Insertable<NifudaRow> {
  final int id;
  final int projectId;
  final String seiban;
  final String itemNumber;
  final String productName;
  final String form;
  final String quantity;
  final String documentNumber;
  final String remarks;
  final String arrangementCode;
  final String caseNumber;
  const NifudaRow(
      {required this.id,
      required this.projectId,
      required this.seiban,
      required this.itemNumber,
      required this.productName,
      required this.form,
      required this.quantity,
      required this.documentNumber,
      required this.remarks,
      required this.arrangementCode,
      required this.caseNumber});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['seiban'] = Variable<String>(seiban);
    map['item_number'] = Variable<String>(itemNumber);
    map['product_name'] = Variable<String>(productName);
    map['form'] = Variable<String>(form);
    map['quantity'] = Variable<String>(quantity);
    map['document_number'] = Variable<String>(documentNumber);
    map['remarks'] = Variable<String>(remarks);
    map['arrangement_code'] = Variable<String>(arrangementCode);
    map['case_number'] = Variable<String>(caseNumber);
    return map;
  }

  NifudaRowsCompanion toCompanion(bool nullToAbsent) {
    return NifudaRowsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      seiban: Value(seiban),
      itemNumber: Value(itemNumber),
      productName: Value(productName),
      form: Value(form),
      quantity: Value(quantity),
      documentNumber: Value(documentNumber),
      remarks: Value(remarks),
      arrangementCode: Value(arrangementCode),
      caseNumber: Value(caseNumber),
    );
  }

  factory NifudaRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NifudaRow(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      seiban: serializer.fromJson<String>(json['seiban']),
      itemNumber: serializer.fromJson<String>(json['itemNumber']),
      productName: serializer.fromJson<String>(json['productName']),
      form: serializer.fromJson<String>(json['form']),
      quantity: serializer.fromJson<String>(json['quantity']),
      documentNumber: serializer.fromJson<String>(json['documentNumber']),
      remarks: serializer.fromJson<String>(json['remarks']),
      arrangementCode: serializer.fromJson<String>(json['arrangementCode']),
      caseNumber: serializer.fromJson<String>(json['caseNumber']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'seiban': serializer.toJson<String>(seiban),
      'itemNumber': serializer.toJson<String>(itemNumber),
      'productName': serializer.toJson<String>(productName),
      'form': serializer.toJson<String>(form),
      'quantity': serializer.toJson<String>(quantity),
      'documentNumber': serializer.toJson<String>(documentNumber),
      'remarks': serializer.toJson<String>(remarks),
      'arrangementCode': serializer.toJson<String>(arrangementCode),
      'caseNumber': serializer.toJson<String>(caseNumber),
    };
  }

  NifudaRow copyWith(
          {int? id,
          int? projectId,
          String? seiban,
          String? itemNumber,
          String? productName,
          String? form,
          String? quantity,
          String? documentNumber,
          String? remarks,
          String? arrangementCode,
          String? caseNumber}) =>
      NifudaRow(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        seiban: seiban ?? this.seiban,
        itemNumber: itemNumber ?? this.itemNumber,
        productName: productName ?? this.productName,
        form: form ?? this.form,
        quantity: quantity ?? this.quantity,
        documentNumber: documentNumber ?? this.documentNumber,
        remarks: remarks ?? this.remarks,
        arrangementCode: arrangementCode ?? this.arrangementCode,
        caseNumber: caseNumber ?? this.caseNumber,
      );
  NifudaRow copyWithCompanion(NifudaRowsCompanion data) {
    return NifudaRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      seiban: data.seiban.present ? data.seiban.value : this.seiban,
      itemNumber:
          data.itemNumber.present ? data.itemNumber.value : this.itemNumber,
      productName:
          data.productName.present ? data.productName.value : this.productName,
      form: data.form.present ? data.form.value : this.form,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      documentNumber: data.documentNumber.present
          ? data.documentNumber.value
          : this.documentNumber,
      remarks: data.remarks.present ? data.remarks.value : this.remarks,
      arrangementCode: data.arrangementCode.present
          ? data.arrangementCode.value
          : this.arrangementCode,
      caseNumber:
          data.caseNumber.present ? data.caseNumber.value : this.caseNumber,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NifudaRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('seiban: $seiban, ')
          ..write('itemNumber: $itemNumber, ')
          ..write('productName: $productName, ')
          ..write('form: $form, ')
          ..write('quantity: $quantity, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('remarks: $remarks, ')
          ..write('arrangementCode: $arrangementCode, ')
          ..write('caseNumber: $caseNumber')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      seiban,
      itemNumber,
      productName,
      form,
      quantity,
      documentNumber,
      remarks,
      arrangementCode,
      caseNumber);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NifudaRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.seiban == this.seiban &&
          other.itemNumber == this.itemNumber &&
          other.productName == this.productName &&
          other.form == this.form &&
          other.quantity == this.quantity &&
          other.documentNumber == this.documentNumber &&
          other.remarks == this.remarks &&
          other.arrangementCode == this.arrangementCode &&
          other.caseNumber == this.caseNumber);
}

class NifudaRowsCompanion extends UpdateCompanion<NifudaRow> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> seiban;
  final Value<String> itemNumber;
  final Value<String> productName;
  final Value<String> form;
  final Value<String> quantity;
  final Value<String> documentNumber;
  final Value<String> remarks;
  final Value<String> arrangementCode;
  final Value<String> caseNumber;
  const NifudaRowsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.seiban = const Value.absent(),
    this.itemNumber = const Value.absent(),
    this.productName = const Value.absent(),
    this.form = const Value.absent(),
    this.quantity = const Value.absent(),
    this.documentNumber = const Value.absent(),
    this.remarks = const Value.absent(),
    this.arrangementCode = const Value.absent(),
    this.caseNumber = const Value.absent(),
  });
  NifudaRowsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String seiban,
    required String itemNumber,
    required String productName,
    required String form,
    required String quantity,
    required String documentNumber,
    required String remarks,
    required String arrangementCode,
    required String caseNumber,
  })  : projectId = Value(projectId),
        seiban = Value(seiban),
        itemNumber = Value(itemNumber),
        productName = Value(productName),
        form = Value(form),
        quantity = Value(quantity),
        documentNumber = Value(documentNumber),
        remarks = Value(remarks),
        arrangementCode = Value(arrangementCode),
        caseNumber = Value(caseNumber);
  static Insertable<NifudaRow> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? seiban,
    Expression<String>? itemNumber,
    Expression<String>? productName,
    Expression<String>? form,
    Expression<String>? quantity,
    Expression<String>? documentNumber,
    Expression<String>? remarks,
    Expression<String>? arrangementCode,
    Expression<String>? caseNumber,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (seiban != null) 'seiban': seiban,
      if (itemNumber != null) 'item_number': itemNumber,
      if (productName != null) 'product_name': productName,
      if (form != null) 'form': form,
      if (quantity != null) 'quantity': quantity,
      if (documentNumber != null) 'document_number': documentNumber,
      if (remarks != null) 'remarks': remarks,
      if (arrangementCode != null) 'arrangement_code': arrangementCode,
      if (caseNumber != null) 'case_number': caseNumber,
    });
  }

  NifudaRowsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? seiban,
      Value<String>? itemNumber,
      Value<String>? productName,
      Value<String>? form,
      Value<String>? quantity,
      Value<String>? documentNumber,
      Value<String>? remarks,
      Value<String>? arrangementCode,
      Value<String>? caseNumber}) {
    return NifudaRowsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      seiban: seiban ?? this.seiban,
      itemNumber: itemNumber ?? this.itemNumber,
      productName: productName ?? this.productName,
      form: form ?? this.form,
      quantity: quantity ?? this.quantity,
      documentNumber: documentNumber ?? this.documentNumber,
      remarks: remarks ?? this.remarks,
      arrangementCode: arrangementCode ?? this.arrangementCode,
      caseNumber: caseNumber ?? this.caseNumber,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (seiban.present) {
      map['seiban'] = Variable<String>(seiban.value);
    }
    if (itemNumber.present) {
      map['item_number'] = Variable<String>(itemNumber.value);
    }
    if (productName.present) {
      map['product_name'] = Variable<String>(productName.value);
    }
    if (form.present) {
      map['form'] = Variable<String>(form.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<String>(quantity.value);
    }
    if (documentNumber.present) {
      map['document_number'] = Variable<String>(documentNumber.value);
    }
    if (remarks.present) {
      map['remarks'] = Variable<String>(remarks.value);
    }
    if (arrangementCode.present) {
      map['arrangement_code'] = Variable<String>(arrangementCode.value);
    }
    if (caseNumber.present) {
      map['case_number'] = Variable<String>(caseNumber.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NifudaRowsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('seiban: $seiban, ')
          ..write('itemNumber: $itemNumber, ')
          ..write('productName: $productName, ')
          ..write('form: $form, ')
          ..write('quantity: $quantity, ')
          ..write('documentNumber: $documentNumber, ')
          ..write('remarks: $remarks, ')
          ..write('arrangementCode: $arrangementCode, ')
          ..write('caseNumber: $caseNumber')
          ..write(')'))
        .toString();
  }
}

class $ProductListRowsTable extends ProductListRows
    with TableInfo<$ProductListRowsTable, ProductListRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProductListRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _projectIdMeta =
      const VerificationMeta('projectId');
  @override
  late final GeneratedColumn<int> projectId = GeneratedColumn<int>(
      'project_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('REFERENCES projects (id)'));
  static const VerificationMeta _orderNoMeta =
      const VerificationMeta('orderNo');
  @override
  late final GeneratedColumn<String> orderNo = GeneratedColumn<String>(
      'order_no', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _itemOfSpareMeta =
      const VerificationMeta('itemOfSpare');
  @override
  late final GeneratedColumn<String> itemOfSpare = GeneratedColumn<String>(
      'item_of_spare', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productSymbolMeta =
      const VerificationMeta('productSymbol');
  @override
  late final GeneratedColumn<String> productSymbol = GeneratedColumn<String>(
      'product_symbol', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _formSpecMeta =
      const VerificationMeta('formSpec');
  @override
  late final GeneratedColumn<String> formSpec = GeneratedColumn<String>(
      'form_spec', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _productCodeMeta =
      const VerificationMeta('productCode');
  @override
  late final GeneratedColumn<String> productCode = GeneratedColumn<String>(
      'product_code', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderQuantityMeta =
      const VerificationMeta('orderQuantity');
  @override
  late final GeneratedColumn<String> orderQuantity = GeneratedColumn<String>(
      'order_quantity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _articleMeta =
      const VerificationMeta('article');
  @override
  late final GeneratedColumn<String> article = GeneratedColumn<String>(
      'article', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchedCaseMeta =
      const VerificationMeta('matchedCase');
  @override
  late final GeneratedColumn<String> matchedCase = GeneratedColumn<String>(
      'matched_case', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        orderNo,
        itemOfSpare,
        productSymbol,
        formSpec,
        productCode,
        orderQuantity,
        article,
        note,
        matchedCase
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'product_list_rows';
  @override
  VerificationContext validateIntegrity(Insertable<ProductListRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('project_id')) {
      context.handle(_projectIdMeta,
          projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta));
    } else if (isInserting) {
      context.missing(_projectIdMeta);
    }
    if (data.containsKey('order_no')) {
      context.handle(_orderNoMeta,
          orderNo.isAcceptableOrUnknown(data['order_no']!, _orderNoMeta));
    } else if (isInserting) {
      context.missing(_orderNoMeta);
    }
    if (data.containsKey('item_of_spare')) {
      context.handle(
          _itemOfSpareMeta,
          itemOfSpare.isAcceptableOrUnknown(
              data['item_of_spare']!, _itemOfSpareMeta));
    } else if (isInserting) {
      context.missing(_itemOfSpareMeta);
    }
    if (data.containsKey('product_symbol')) {
      context.handle(
          _productSymbolMeta,
          productSymbol.isAcceptableOrUnknown(
              data['product_symbol']!, _productSymbolMeta));
    } else if (isInserting) {
      context.missing(_productSymbolMeta);
    }
    if (data.containsKey('form_spec')) {
      context.handle(_formSpecMeta,
          formSpec.isAcceptableOrUnknown(data['form_spec']!, _formSpecMeta));
    } else if (isInserting) {
      context.missing(_formSpecMeta);
    }
    if (data.containsKey('product_code')) {
      context.handle(
          _productCodeMeta,
          productCode.isAcceptableOrUnknown(
              data['product_code']!, _productCodeMeta));
    } else if (isInserting) {
      context.missing(_productCodeMeta);
    }
    if (data.containsKey('order_quantity')) {
      context.handle(
          _orderQuantityMeta,
          orderQuantity.isAcceptableOrUnknown(
              data['order_quantity']!, _orderQuantityMeta));
    } else if (isInserting) {
      context.missing(_orderQuantityMeta);
    }
    if (data.containsKey('article')) {
      context.handle(_articleMeta,
          article.isAcceptableOrUnknown(data['article']!, _articleMeta));
    } else if (isInserting) {
      context.missing(_articleMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    } else if (isInserting) {
      context.missing(_noteMeta);
    }
    if (data.containsKey('matched_case')) {
      context.handle(
          _matchedCaseMeta,
          matchedCase.isAcceptableOrUnknown(
              data['matched_case']!, _matchedCaseMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProductListRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProductListRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      projectId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}project_id'])!,
      orderNo: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_no'])!,
      itemOfSpare: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}item_of_spare'])!,
      productSymbol: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_symbol'])!,
      formSpec: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_spec'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      orderQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_quantity'])!,
      article: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}article'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      matchedCase: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matched_case']),
    );
  }

  @override
  $ProductListRowsTable createAlias(String alias) {
    return $ProductListRowsTable(attachedDatabase, alias);
  }
}

class ProductListRow extends DataClass implements Insertable<ProductListRow> {
  final int id;
  final int projectId;
  final String orderNo;
  final String itemOfSpare;
  final String productSymbol;
  final String formSpec;
  final String productCode;
  final String orderQuantity;
  final String article;
  final String note;
  final String? matchedCase;
  const ProductListRow(
      {required this.id,
      required this.projectId,
      required this.orderNo,
      required this.itemOfSpare,
      required this.productSymbol,
      required this.formSpec,
      required this.productCode,
      required this.orderQuantity,
      required this.article,
      required this.note,
      this.matchedCase});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['order_no'] = Variable<String>(orderNo);
    map['item_of_spare'] = Variable<String>(itemOfSpare);
    map['product_symbol'] = Variable<String>(productSymbol);
    map['form_spec'] = Variable<String>(formSpec);
    map['product_code'] = Variable<String>(productCode);
    map['order_quantity'] = Variable<String>(orderQuantity);
    map['article'] = Variable<String>(article);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || matchedCase != null) {
      map['matched_case'] = Variable<String>(matchedCase);
    }
    return map;
  }

  ProductListRowsCompanion toCompanion(bool nullToAbsent) {
    return ProductListRowsCompanion(
      id: Value(id),
      projectId: Value(projectId),
      orderNo: Value(orderNo),
      itemOfSpare: Value(itemOfSpare),
      productSymbol: Value(productSymbol),
      formSpec: Value(formSpec),
      productCode: Value(productCode),
      orderQuantity: Value(orderQuantity),
      article: Value(article),
      note: Value(note),
      matchedCase: matchedCase == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedCase),
    );
  }

  factory ProductListRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProductListRow(
      id: serializer.fromJson<int>(json['id']),
      projectId: serializer.fromJson<int>(json['projectId']),
      orderNo: serializer.fromJson<String>(json['orderNo']),
      itemOfSpare: serializer.fromJson<String>(json['itemOfSpare']),
      productSymbol: serializer.fromJson<String>(json['productSymbol']),
      formSpec: serializer.fromJson<String>(json['formSpec']),
      productCode: serializer.fromJson<String>(json['productCode']),
      orderQuantity: serializer.fromJson<String>(json['orderQuantity']),
      article: serializer.fromJson<String>(json['article']),
      note: serializer.fromJson<String>(json['note']),
      matchedCase: serializer.fromJson<String?>(json['matchedCase']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'projectId': serializer.toJson<int>(projectId),
      'orderNo': serializer.toJson<String>(orderNo),
      'itemOfSpare': serializer.toJson<String>(itemOfSpare),
      'productSymbol': serializer.toJson<String>(productSymbol),
      'formSpec': serializer.toJson<String>(formSpec),
      'productCode': serializer.toJson<String>(productCode),
      'orderQuantity': serializer.toJson<String>(orderQuantity),
      'article': serializer.toJson<String>(article),
      'note': serializer.toJson<String>(note),
      'matchedCase': serializer.toJson<String?>(matchedCase),
    };
  }

  ProductListRow copyWith(
          {int? id,
          int? projectId,
          String? orderNo,
          String? itemOfSpare,
          String? productSymbol,
          String? formSpec,
          String? productCode,
          String? orderQuantity,
          String? article,
          String? note,
          Value<String?> matchedCase = const Value.absent()}) =>
      ProductListRow(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        orderNo: orderNo ?? this.orderNo,
        itemOfSpare: itemOfSpare ?? this.itemOfSpare,
        productSymbol: productSymbol ?? this.productSymbol,
        formSpec: formSpec ?? this.formSpec,
        productCode: productCode ?? this.productCode,
        orderQuantity: orderQuantity ?? this.orderQuantity,
        article: article ?? this.article,
        note: note ?? this.note,
        matchedCase: matchedCase.present ? matchedCase.value : this.matchedCase,
      );
  ProductListRow copyWithCompanion(ProductListRowsCompanion data) {
    return ProductListRow(
      id: data.id.present ? data.id.value : this.id,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      orderNo: data.orderNo.present ? data.orderNo.value : this.orderNo,
      itemOfSpare:
          data.itemOfSpare.present ? data.itemOfSpare.value : this.itemOfSpare,
      productSymbol: data.productSymbol.present
          ? data.productSymbol.value
          : this.productSymbol,
      formSpec: data.formSpec.present ? data.formSpec.value : this.formSpec,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      orderQuantity: data.orderQuantity.present
          ? data.orderQuantity.value
          : this.orderQuantity,
      article: data.article.present ? data.article.value : this.article,
      note: data.note.present ? data.note.value : this.note,
      matchedCase:
          data.matchedCase.present ? data.matchedCase.value : this.matchedCase,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProductListRow(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('orderNo: $orderNo, ')
          ..write('itemOfSpare: $itemOfSpare, ')
          ..write('productSymbol: $productSymbol, ')
          ..write('formSpec: $formSpec, ')
          ..write('productCode: $productCode, ')
          ..write('orderQuantity: $orderQuantity, ')
          ..write('article: $article, ')
          ..write('note: $note, ')
          ..write('matchedCase: $matchedCase')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      projectId,
      orderNo,
      itemOfSpare,
      productSymbol,
      formSpec,
      productCode,
      orderQuantity,
      article,
      note,
      matchedCase);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductListRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.orderNo == this.orderNo &&
          other.itemOfSpare == this.itemOfSpare &&
          other.productSymbol == this.productSymbol &&
          other.formSpec == this.formSpec &&
          other.productCode == this.productCode &&
          other.orderQuantity == this.orderQuantity &&
          other.article == this.article &&
          other.note == this.note &&
          other.matchedCase == this.matchedCase);
}

class ProductListRowsCompanion extends UpdateCompanion<ProductListRow> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> orderNo;
  final Value<String> itemOfSpare;
  final Value<String> productSymbol;
  final Value<String> formSpec;
  final Value<String> productCode;
  final Value<String> orderQuantity;
  final Value<String> article;
  final Value<String> note;
  final Value<String?> matchedCase;
  const ProductListRowsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.orderNo = const Value.absent(),
    this.itemOfSpare = const Value.absent(),
    this.productSymbol = const Value.absent(),
    this.formSpec = const Value.absent(),
    this.productCode = const Value.absent(),
    this.orderQuantity = const Value.absent(),
    this.article = const Value.absent(),
    this.note = const Value.absent(),
    this.matchedCase = const Value.absent(),
  });
  ProductListRowsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String orderNo,
    required String itemOfSpare,
    required String productSymbol,
    required String formSpec,
    required String productCode,
    required String orderQuantity,
    required String article,
    required String note,
    this.matchedCase = const Value.absent(),
  })  : projectId = Value(projectId),
        orderNo = Value(orderNo),
        itemOfSpare = Value(itemOfSpare),
        productSymbol = Value(productSymbol),
        formSpec = Value(formSpec),
        productCode = Value(productCode),
        orderQuantity = Value(orderQuantity),
        article = Value(article),
        note = Value(note);
  static Insertable<ProductListRow> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? orderNo,
    Expression<String>? itemOfSpare,
    Expression<String>? productSymbol,
    Expression<String>? formSpec,
    Expression<String>? productCode,
    Expression<String>? orderQuantity,
    Expression<String>? article,
    Expression<String>? note,
    Expression<String>? matchedCase,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (orderNo != null) 'order_no': orderNo,
      if (itemOfSpare != null) 'item_of_spare': itemOfSpare,
      if (productSymbol != null) 'product_symbol': productSymbol,
      if (formSpec != null) 'form_spec': formSpec,
      if (productCode != null) 'product_code': productCode,
      if (orderQuantity != null) 'order_quantity': orderQuantity,
      if (article != null) 'article': article,
      if (note != null) 'note': note,
      if (matchedCase != null) 'matched_case': matchedCase,
    });
  }

  ProductListRowsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? orderNo,
      Value<String>? itemOfSpare,
      Value<String>? productSymbol,
      Value<String>? formSpec,
      Value<String>? productCode,
      Value<String>? orderQuantity,
      Value<String>? article,
      Value<String>? note,
      Value<String?>? matchedCase}) {
    return ProductListRowsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      orderNo: orderNo ?? this.orderNo,
      itemOfSpare: itemOfSpare ?? this.itemOfSpare,
      productSymbol: productSymbol ?? this.productSymbol,
      formSpec: formSpec ?? this.formSpec,
      productCode: productCode ?? this.productCode,
      orderQuantity: orderQuantity ?? this.orderQuantity,
      article: article ?? this.article,
      note: note ?? this.note,
      matchedCase: matchedCase ?? this.matchedCase,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<int>(projectId.value);
    }
    if (orderNo.present) {
      map['order_no'] = Variable<String>(orderNo.value);
    }
    if (itemOfSpare.present) {
      map['item_of_spare'] = Variable<String>(itemOfSpare.value);
    }
    if (productSymbol.present) {
      map['product_symbol'] = Variable<String>(productSymbol.value);
    }
    if (formSpec.present) {
      map['form_spec'] = Variable<String>(formSpec.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (orderQuantity.present) {
      map['order_quantity'] = Variable<String>(orderQuantity.value);
    }
    if (article.present) {
      map['article'] = Variable<String>(article.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (matchedCase.present) {
      map['matched_case'] = Variable<String>(matchedCase.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProductListRowsCompanion(')
          ..write('id: $id, ')
          ..write('projectId: $projectId, ')
          ..write('orderNo: $orderNo, ')
          ..write('itemOfSpare: $itemOfSpare, ')
          ..write('productSymbol: $productSymbol, ')
          ..write('formSpec: $formSpec, ')
          ..write('productCode: $productCode, ')
          ..write('orderQuantity: $orderQuantity, ')
          ..write('article: $article, ')
          ..write('note: $note, ')
          ..write('matchedCase: $matchedCase')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $NifudaRowsTable nifudaRows = $NifudaRowsTable(this);
  late final $ProductListRowsTable productListRows =
      $ProductListRowsTable(this);
  late final ProjectsDao projectsDao = ProjectsDao(this as AppDatabase);
  late final NifudaRowsDao nifudaRowsDao = NifudaRowsDao(this as AppDatabase);
  late final ProductListRowsDao productListRowsDao =
      ProductListRowsDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [projects, nifudaRows, productListRows];
}

typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  required String projectCode,
  required String projectTitle,
  required String inspectionStatus,
  required String projectFolderPath,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<int> id,
  Value<String> projectCode,
  Value<String> projectTitle,
  Value<String> inspectionStatus,
  Value<String> projectFolderPath,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, Project> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NifudaRowsTable, List<NifudaRow>>
      _nifudaRowsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
          db.nifudaRows,
          aliasName:
              $_aliasNameGenerator(db.projects.id, db.nifudaRows.projectId));

  $$NifudaRowsTableProcessedTableManager get nifudaRowsRefs {
    final manager = $$NifudaRowsTableTableManager($_db, $_db.nifudaRows)
        .filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_nifudaRowsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ProductListRowsTable, List<ProductListRow>>
      _productListRowsRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.productListRows,
              aliasName: $_aliasNameGenerator(
                  db.projects.id, db.productListRows.projectId));

  $$ProductListRowsTableProcessedTableManager get productListRowsRefs {
    final manager =
        $$ProductListRowsTableTableManager($_db, $_db.productListRows)
            .filter((f) => f.projectId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_productListRowsRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectCode => $composableBuilder(
      column: $table.projectCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectTitle => $composableBuilder(
      column: $table.projectTitle, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get inspectionStatus => $composableBuilder(
      column: $table.inspectionStatus,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get projectFolderPath => $composableBuilder(
      column: $table.projectFolderPath,
      builder: (column) => ColumnFilters(column));

  Expression<bool> nifudaRowsRefs(
      Expression<bool> Function($$NifudaRowsTableFilterComposer f) f) {
    final $$NifudaRowsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nifudaRows,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NifudaRowsTableFilterComposer(
              $db: $db,
              $table: $db.nifudaRows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> productListRowsRefs(
      Expression<bool> Function($$ProductListRowsTableFilterComposer f) f) {
    final $$ProductListRowsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productListRows,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductListRowsTableFilterComposer(
              $db: $db,
              $table: $db.productListRows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectCode => $composableBuilder(
      column: $table.projectCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectTitle => $composableBuilder(
      column: $table.projectTitle,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get inspectionStatus => $composableBuilder(
      column: $table.inspectionStatus,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get projectFolderPath => $composableBuilder(
      column: $table.projectFolderPath,
      builder: (column) => ColumnOrderings(column));
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get projectCode => $composableBuilder(
      column: $table.projectCode, builder: (column) => column);

  GeneratedColumn<String> get projectTitle => $composableBuilder(
      column: $table.projectTitle, builder: (column) => column);

  GeneratedColumn<String> get inspectionStatus => $composableBuilder(
      column: $table.inspectionStatus, builder: (column) => column);

  GeneratedColumn<String> get projectFolderPath => $composableBuilder(
      column: $table.projectFolderPath, builder: (column) => column);

  Expression<T> nifudaRowsRefs<T extends Object>(
      Expression<T> Function($$NifudaRowsTableAnnotationComposer a) f) {
    final $$NifudaRowsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.nifudaRows,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$NifudaRowsTableAnnotationComposer(
              $db: $db,
              $table: $db.nifudaRows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> productListRowsRefs<T extends Object>(
      Expression<T> Function($$ProductListRowsTableAnnotationComposer a) f) {
    final $$ProductListRowsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.productListRows,
        getReferencedColumn: (t) => t.projectId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProductListRowsTableAnnotationComposer(
              $db: $db,
              $table: $db.productListRows,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ProjectsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool nifudaRowsRefs, bool productListRowsRefs})> {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> projectCode = const Value.absent(),
            Value<String> projectTitle = const Value.absent(),
            Value<String> inspectionStatus = const Value.absent(),
            Value<String> projectFolderPath = const Value.absent(),
          }) =>
              ProjectsCompanion(
            id: id,
            projectCode: projectCode,
            projectTitle: projectTitle,
            inspectionStatus: inspectionStatus,
            projectFolderPath: projectFolderPath,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String projectCode,
            required String projectTitle,
            required String inspectionStatus,
            required String projectFolderPath,
          }) =>
              ProjectsCompanion.insert(
            id: id,
            projectCode: projectCode,
            projectTitle: projectTitle,
            inspectionStatus: inspectionStatus,
            projectFolderPath: projectFolderPath,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) =>
                  (e.readTable(table), $$ProjectsTableReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: (
              {nifudaRowsRefs = false, productListRowsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (nifudaRowsRefs) db.nifudaRows,
                if (productListRowsRefs) db.productListRows
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (nifudaRowsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable,
                            NifudaRow>(
                        currentTable: table,
                        referencedTable:
                            $$ProjectsTableReferences._nifudaRowsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .nifudaRowsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items),
                  if (productListRowsRefs)
                    await $_getPrefetchedData<Project, $ProjectsTable,
                            ProductListRow>(
                        currentTable: table,
                        referencedTable: $$ProjectsTableReferences
                            ._productListRowsRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ProjectsTableReferences(db, table, p0)
                                .productListRowsRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.projectId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ProjectsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProjectsTable,
    Project,
    $$ProjectsTableFilterComposer,
    $$ProjectsTableOrderingComposer,
    $$ProjectsTableAnnotationComposer,
    $$ProjectsTableCreateCompanionBuilder,
    $$ProjectsTableUpdateCompanionBuilder,
    (Project, $$ProjectsTableReferences),
    Project,
    PrefetchHooks Function({bool nifudaRowsRefs, bool productListRowsRefs})>;
typedef $$NifudaRowsTableCreateCompanionBuilder = NifudaRowsCompanion Function({
  Value<int> id,
  required int projectId,
  required String seiban,
  required String itemNumber,
  required String productName,
  required String form,
  required String quantity,
  required String documentNumber,
  required String remarks,
  required String arrangementCode,
  required String caseNumber,
});
typedef $$NifudaRowsTableUpdateCompanionBuilder = NifudaRowsCompanion Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> seiban,
  Value<String> itemNumber,
  Value<String> productName,
  Value<String> form,
  Value<String> quantity,
  Value<String> documentNumber,
  Value<String> remarks,
  Value<String> arrangementCode,
  Value<String> caseNumber,
});

final class $$NifudaRowsTableReferences
    extends BaseReferences<_$AppDatabase, $NifudaRowsTable, NifudaRow> {
  $$NifudaRowsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.nifudaRows.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$NifudaRowsTableFilterComposer
    extends Composer<_$AppDatabase, $NifudaRowsTable> {
  $$NifudaRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get seiban => $composableBuilder(
      column: $table.seiban, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemNumber => $composableBuilder(
      column: $table.itemNumber, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get form => $composableBuilder(
      column: $table.form, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get documentNumber => $composableBuilder(
      column: $table.documentNumber,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get arrangementCode => $composableBuilder(
      column: $table.arrangementCode,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get caseNumber => $composableBuilder(
      column: $table.caseNumber, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NifudaRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $NifudaRowsTable> {
  $$NifudaRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get seiban => $composableBuilder(
      column: $table.seiban, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemNumber => $composableBuilder(
      column: $table.itemNumber, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get form => $composableBuilder(
      column: $table.form, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get quantity => $composableBuilder(
      column: $table.quantity, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get documentNumber => $composableBuilder(
      column: $table.documentNumber,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get remarks => $composableBuilder(
      column: $table.remarks, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get arrangementCode => $composableBuilder(
      column: $table.arrangementCode,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get caseNumber => $composableBuilder(
      column: $table.caseNumber, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NifudaRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NifudaRowsTable> {
  $$NifudaRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get seiban =>
      $composableBuilder(column: $table.seiban, builder: (column) => column);

  GeneratedColumn<String> get itemNumber => $composableBuilder(
      column: $table.itemNumber, builder: (column) => column);

  GeneratedColumn<String> get productName => $composableBuilder(
      column: $table.productName, builder: (column) => column);

  GeneratedColumn<String> get form =>
      $composableBuilder(column: $table.form, builder: (column) => column);

  GeneratedColumn<String> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<String> get documentNumber => $composableBuilder(
      column: $table.documentNumber, builder: (column) => column);

  GeneratedColumn<String> get remarks =>
      $composableBuilder(column: $table.remarks, builder: (column) => column);

  GeneratedColumn<String> get arrangementCode => $composableBuilder(
      column: $table.arrangementCode, builder: (column) => column);

  GeneratedColumn<String> get caseNumber => $composableBuilder(
      column: $table.caseNumber, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$NifudaRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $NifudaRowsTable,
    NifudaRow,
    $$NifudaRowsTableFilterComposer,
    $$NifudaRowsTableOrderingComposer,
    $$NifudaRowsTableAnnotationComposer,
    $$NifudaRowsTableCreateCompanionBuilder,
    $$NifudaRowsTableUpdateCompanionBuilder,
    (NifudaRow, $$NifudaRowsTableReferences),
    NifudaRow,
    PrefetchHooks Function({bool projectId})> {
  $$NifudaRowsTableTableManager(_$AppDatabase db, $NifudaRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NifudaRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NifudaRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NifudaRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> seiban = const Value.absent(),
            Value<String> itemNumber = const Value.absent(),
            Value<String> productName = const Value.absent(),
            Value<String> form = const Value.absent(),
            Value<String> quantity = const Value.absent(),
            Value<String> documentNumber = const Value.absent(),
            Value<String> remarks = const Value.absent(),
            Value<String> arrangementCode = const Value.absent(),
            Value<String> caseNumber = const Value.absent(),
          }) =>
              NifudaRowsCompanion(
            id: id,
            projectId: projectId,
            seiban: seiban,
            itemNumber: itemNumber,
            productName: productName,
            form: form,
            quantity: quantity,
            documentNumber: documentNumber,
            remarks: remarks,
            arrangementCode: arrangementCode,
            caseNumber: caseNumber,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String seiban,
            required String itemNumber,
            required String productName,
            required String form,
            required String quantity,
            required String documentNumber,
            required String remarks,
            required String arrangementCode,
            required String caseNumber,
          }) =>
              NifudaRowsCompanion.insert(
            id: id,
            projectId: projectId,
            seiban: seiban,
            itemNumber: itemNumber,
            productName: productName,
            form: form,
            quantity: quantity,
            documentNumber: documentNumber,
            remarks: remarks,
            arrangementCode: arrangementCode,
            caseNumber: caseNumber,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$NifudaRowsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$NifudaRowsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$NifudaRowsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$NifudaRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $NifudaRowsTable,
    NifudaRow,
    $$NifudaRowsTableFilterComposer,
    $$NifudaRowsTableOrderingComposer,
    $$NifudaRowsTableAnnotationComposer,
    $$NifudaRowsTableCreateCompanionBuilder,
    $$NifudaRowsTableUpdateCompanionBuilder,
    (NifudaRow, $$NifudaRowsTableReferences),
    NifudaRow,
    PrefetchHooks Function({bool projectId})>;
typedef $$ProductListRowsTableCreateCompanionBuilder = ProductListRowsCompanion
    Function({
  Value<int> id,
  required int projectId,
  required String orderNo,
  required String itemOfSpare,
  required String productSymbol,
  required String formSpec,
  required String productCode,
  required String orderQuantity,
  required String article,
  required String note,
  Value<String?> matchedCase,
});
typedef $$ProductListRowsTableUpdateCompanionBuilder = ProductListRowsCompanion
    Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> orderNo,
  Value<String> itemOfSpare,
  Value<String> productSymbol,
  Value<String> formSpec,
  Value<String> productCode,
  Value<String> orderQuantity,
  Value<String> article,
  Value<String> note,
  Value<String?> matchedCase,
});

final class $$ProductListRowsTableReferences extends BaseReferences<
    _$AppDatabase, $ProductListRowsTable, ProductListRow> {
  $$ProductListRowsTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias(
          $_aliasNameGenerator(db.productListRows.projectId, db.projects.id));

  $$ProjectsTableProcessedTableManager get projectId {
    final $_column = $_itemColumn<int>('project_id')!;

    final manager = $$ProjectsTableTableManager($_db, $_db.projects)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ProductListRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ProductListRowsTable> {
  $$ProductListRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderNo => $composableBuilder(
      column: $table.orderNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemOfSpare => $composableBuilder(
      column: $table.itemOfSpare, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productSymbol => $composableBuilder(
      column: $table.productSymbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formSpec => $composableBuilder(
      column: $table.formSpec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderQuantity => $composableBuilder(
      column: $table.orderQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get article => $composableBuilder(
      column: $table.article, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchedCase => $composableBuilder(
      column: $table.matchedCase, builder: (column) => ColumnFilters(column));

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableFilterComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductListRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProductListRowsTable> {
  $$ProductListRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderNo => $composableBuilder(
      column: $table.orderNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemOfSpare => $composableBuilder(
      column: $table.itemOfSpare, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productSymbol => $composableBuilder(
      column: $table.productSymbol,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formSpec => $composableBuilder(
      column: $table.formSpec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderQuantity => $composableBuilder(
      column: $table.orderQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get article => $composableBuilder(
      column: $table.article, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchedCase => $composableBuilder(
      column: $table.matchedCase, builder: (column) => ColumnOrderings(column));

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableOrderingComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductListRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProductListRowsTable> {
  $$ProductListRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get orderNo =>
      $composableBuilder(column: $table.orderNo, builder: (column) => column);

  GeneratedColumn<String> get itemOfSpare => $composableBuilder(
      column: $table.itemOfSpare, builder: (column) => column);

  GeneratedColumn<String> get productSymbol => $composableBuilder(
      column: $table.productSymbol, builder: (column) => column);

  GeneratedColumn<String> get formSpec =>
      $composableBuilder(column: $table.formSpec, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get orderQuantity => $composableBuilder(
      column: $table.orderQuantity, builder: (column) => column);

  GeneratedColumn<String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get matchedCase => $composableBuilder(
      column: $table.matchedCase, builder: (column) => column);

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.projectId,
        referencedTable: $db.projects,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ProjectsTableAnnotationComposer(
              $db: $db,
              $table: $db.projects,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ProductListRowsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ProductListRowsTable,
    ProductListRow,
    $$ProductListRowsTableFilterComposer,
    $$ProductListRowsTableOrderingComposer,
    $$ProductListRowsTableAnnotationComposer,
    $$ProductListRowsTableCreateCompanionBuilder,
    $$ProductListRowsTableUpdateCompanionBuilder,
    (ProductListRow, $$ProductListRowsTableReferences),
    ProductListRow,
    PrefetchHooks Function({bool projectId})> {
  $$ProductListRowsTableTableManager(
      _$AppDatabase db, $ProductListRowsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProductListRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProductListRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProductListRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> projectId = const Value.absent(),
            Value<String> orderNo = const Value.absent(),
            Value<String> itemOfSpare = const Value.absent(),
            Value<String> productSymbol = const Value.absent(),
            Value<String> formSpec = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> orderQuantity = const Value.absent(),
            Value<String> article = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String?> matchedCase = const Value.absent(),
          }) =>
              ProductListRowsCompanion(
            id: id,
            projectId: projectId,
            orderNo: orderNo,
            itemOfSpare: itemOfSpare,
            productSymbol: productSymbol,
            formSpec: formSpec,
            productCode: productCode,
            orderQuantity: orderQuantity,
            article: article,
            note: note,
            matchedCase: matchedCase,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String orderNo,
            required String itemOfSpare,
            required String productSymbol,
            required String formSpec,
            required String productCode,
            required String orderQuantity,
            required String article,
            required String note,
            Value<String?> matchedCase = const Value.absent(),
          }) =>
              ProductListRowsCompanion.insert(
            id: id,
            projectId: projectId,
            orderNo: orderNo,
            itemOfSpare: itemOfSpare,
            productSymbol: productSymbol,
            formSpec: formSpec,
            productCode: productCode,
            orderQuantity: orderQuantity,
            article: article,
            note: note,
            matchedCase: matchedCase,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ProductListRowsTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({projectId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins: <
                  T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic>>(state) {
                if (projectId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.projectId,
                    referencedTable:
                        $$ProductListRowsTableReferences._projectIdTable(db),
                    referencedColumn:
                        $$ProductListRowsTableReferences._projectIdTable(db).id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ));
}

typedef $$ProductListRowsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ProductListRowsTable,
    ProductListRow,
    $$ProductListRowsTableFilterComposer,
    $$ProductListRowsTableOrderingComposer,
    $$ProductListRowsTableAnnotationComposer,
    $$ProductListRowsTableCreateCompanionBuilder,
    $$ProductListRowsTableUpdateCompanionBuilder,
    (ProductListRow, $$ProductListRowsTableReferences),
    ProductListRow,
    PrefetchHooks Function({bool projectId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$NifudaRowsTableTableManager get nifudaRows =>
      $$NifudaRowsTableTableManager(_db, _db.nifudaRows);
  $$ProductListRowsTableTableManager get productListRows =>
      $$ProductListRowsTableTableManager(_db, _db.productListRows);
}

mixin _$ProjectsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
}
mixin _$NifudaRowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $NifudaRowsTable get nifudaRows => attachedDatabase.nifudaRows;
}
mixin _$ProductListRowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
  $ProductListRowsTable get productListRows => attachedDatabase.productListRows;
}
