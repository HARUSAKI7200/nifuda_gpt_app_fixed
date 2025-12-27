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
      type: DriftSqlType.int, requiredDuringInsert: true);
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
      type: DriftSqlType.int, requiredDuringInsert: true);
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
  static const VerificationMeta _orderQuantityMeta =
      const VerificationMeta('orderQuantity');
  @override
  late final GeneratedColumn<String> orderQuantity = GeneratedColumn<String>(
      'order_quantity', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _matchedCaseMeta =
      const VerificationMeta('matchedCase');
  @override
  late final GeneratedColumn<String> matchedCase = GeneratedColumn<String>(
      'matched_case', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _contentJsonMeta =
      const VerificationMeta('contentJson');
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
      'content_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        projectId,
        orderNo,
        itemOfSpare,
        productSymbol,
        orderQuantity,
        matchedCase,
        formSpec,
        productCode,
        article,
        note,
        contentJson
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
    if (data.containsKey('order_quantity')) {
      context.handle(
          _orderQuantityMeta,
          orderQuantity.isAcceptableOrUnknown(
              data['order_quantity']!, _orderQuantityMeta));
    } else if (isInserting) {
      context.missing(_orderQuantityMeta);
    }
    if (data.containsKey('matched_case')) {
      context.handle(
          _matchedCaseMeta,
          matchedCase.isAcceptableOrUnknown(
              data['matched_case']!, _matchedCaseMeta));
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
    if (data.containsKey('content_json')) {
      context.handle(
          _contentJsonMeta,
          contentJson.isAcceptableOrUnknown(
              data['content_json']!, _contentJsonMeta));
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
      orderQuantity: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}order_quantity'])!,
      matchedCase: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}matched_case']),
      formSpec: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}form_spec'])!,
      productCode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}product_code'])!,
      article: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}article'])!,
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note'])!,
      contentJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}content_json']),
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
  final String orderQuantity;
  final String? matchedCase;
  final String formSpec;
  final String productCode;
  final String article;
  final String note;
  final String? contentJson;
  const ProductListRow(
      {required this.id,
      required this.projectId,
      required this.orderNo,
      required this.itemOfSpare,
      required this.productSymbol,
      required this.orderQuantity,
      this.matchedCase,
      required this.formSpec,
      required this.productCode,
      required this.article,
      required this.note,
      this.contentJson});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['project_id'] = Variable<int>(projectId);
    map['order_no'] = Variable<String>(orderNo);
    map['item_of_spare'] = Variable<String>(itemOfSpare);
    map['product_symbol'] = Variable<String>(productSymbol);
    map['order_quantity'] = Variable<String>(orderQuantity);
    if (!nullToAbsent || matchedCase != null) {
      map['matched_case'] = Variable<String>(matchedCase);
    }
    map['form_spec'] = Variable<String>(formSpec);
    map['product_code'] = Variable<String>(productCode);
    map['article'] = Variable<String>(article);
    map['note'] = Variable<String>(note);
    if (!nullToAbsent || contentJson != null) {
      map['content_json'] = Variable<String>(contentJson);
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
      orderQuantity: Value(orderQuantity),
      matchedCase: matchedCase == null && nullToAbsent
          ? const Value.absent()
          : Value(matchedCase),
      formSpec: Value(formSpec),
      productCode: Value(productCode),
      article: Value(article),
      note: Value(note),
      contentJson: contentJson == null && nullToAbsent
          ? const Value.absent()
          : Value(contentJson),
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
      orderQuantity: serializer.fromJson<String>(json['orderQuantity']),
      matchedCase: serializer.fromJson<String?>(json['matchedCase']),
      formSpec: serializer.fromJson<String>(json['formSpec']),
      productCode: serializer.fromJson<String>(json['productCode']),
      article: serializer.fromJson<String>(json['article']),
      note: serializer.fromJson<String>(json['note']),
      contentJson: serializer.fromJson<String?>(json['contentJson']),
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
      'orderQuantity': serializer.toJson<String>(orderQuantity),
      'matchedCase': serializer.toJson<String?>(matchedCase),
      'formSpec': serializer.toJson<String>(formSpec),
      'productCode': serializer.toJson<String>(productCode),
      'article': serializer.toJson<String>(article),
      'note': serializer.toJson<String>(note),
      'contentJson': serializer.toJson<String?>(contentJson),
    };
  }

  ProductListRow copyWith(
          {int? id,
          int? projectId,
          String? orderNo,
          String? itemOfSpare,
          String? productSymbol,
          String? orderQuantity,
          Value<String?> matchedCase = const Value.absent(),
          String? formSpec,
          String? productCode,
          String? article,
          String? note,
          Value<String?> contentJson = const Value.absent()}) =>
      ProductListRow(
        id: id ?? this.id,
        projectId: projectId ?? this.projectId,
        orderNo: orderNo ?? this.orderNo,
        itemOfSpare: itemOfSpare ?? this.itemOfSpare,
        productSymbol: productSymbol ?? this.productSymbol,
        orderQuantity: orderQuantity ?? this.orderQuantity,
        matchedCase: matchedCase.present ? matchedCase.value : this.matchedCase,
        formSpec: formSpec ?? this.formSpec,
        productCode: productCode ?? this.productCode,
        article: article ?? this.article,
        note: note ?? this.note,
        contentJson: contentJson.present ? contentJson.value : this.contentJson,
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
      orderQuantity: data.orderQuantity.present
          ? data.orderQuantity.value
          : this.orderQuantity,
      matchedCase:
          data.matchedCase.present ? data.matchedCase.value : this.matchedCase,
      formSpec: data.formSpec.present ? data.formSpec.value : this.formSpec,
      productCode:
          data.productCode.present ? data.productCode.value : this.productCode,
      article: data.article.present ? data.article.value : this.article,
      note: data.note.present ? data.note.value : this.note,
      contentJson:
          data.contentJson.present ? data.contentJson.value : this.contentJson,
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
          ..write('orderQuantity: $orderQuantity, ')
          ..write('matchedCase: $matchedCase, ')
          ..write('formSpec: $formSpec, ')
          ..write('productCode: $productCode, ')
          ..write('article: $article, ')
          ..write('note: $note, ')
          ..write('contentJson: $contentJson')
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
      orderQuantity,
      matchedCase,
      formSpec,
      productCode,
      article,
      note,
      contentJson);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProductListRow &&
          other.id == this.id &&
          other.projectId == this.projectId &&
          other.orderNo == this.orderNo &&
          other.itemOfSpare == this.itemOfSpare &&
          other.productSymbol == this.productSymbol &&
          other.orderQuantity == this.orderQuantity &&
          other.matchedCase == this.matchedCase &&
          other.formSpec == this.formSpec &&
          other.productCode == this.productCode &&
          other.article == this.article &&
          other.note == this.note &&
          other.contentJson == this.contentJson);
}

class ProductListRowsCompanion extends UpdateCompanion<ProductListRow> {
  final Value<int> id;
  final Value<int> projectId;
  final Value<String> orderNo;
  final Value<String> itemOfSpare;
  final Value<String> productSymbol;
  final Value<String> orderQuantity;
  final Value<String?> matchedCase;
  final Value<String> formSpec;
  final Value<String> productCode;
  final Value<String> article;
  final Value<String> note;
  final Value<String?> contentJson;
  const ProductListRowsCompanion({
    this.id = const Value.absent(),
    this.projectId = const Value.absent(),
    this.orderNo = const Value.absent(),
    this.itemOfSpare = const Value.absent(),
    this.productSymbol = const Value.absent(),
    this.orderQuantity = const Value.absent(),
    this.matchedCase = const Value.absent(),
    this.formSpec = const Value.absent(),
    this.productCode = const Value.absent(),
    this.article = const Value.absent(),
    this.note = const Value.absent(),
    this.contentJson = const Value.absent(),
  });
  ProductListRowsCompanion.insert({
    this.id = const Value.absent(),
    required int projectId,
    required String orderNo,
    required String itemOfSpare,
    required String productSymbol,
    required String orderQuantity,
    this.matchedCase = const Value.absent(),
    required String formSpec,
    required String productCode,
    required String article,
    required String note,
    this.contentJson = const Value.absent(),
  })  : projectId = Value(projectId),
        orderNo = Value(orderNo),
        itemOfSpare = Value(itemOfSpare),
        productSymbol = Value(productSymbol),
        orderQuantity = Value(orderQuantity),
        formSpec = Value(formSpec),
        productCode = Value(productCode),
        article = Value(article),
        note = Value(note);
  static Insertable<ProductListRow> custom({
    Expression<int>? id,
    Expression<int>? projectId,
    Expression<String>? orderNo,
    Expression<String>? itemOfSpare,
    Expression<String>? productSymbol,
    Expression<String>? orderQuantity,
    Expression<String>? matchedCase,
    Expression<String>? formSpec,
    Expression<String>? productCode,
    Expression<String>? article,
    Expression<String>? note,
    Expression<String>? contentJson,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (projectId != null) 'project_id': projectId,
      if (orderNo != null) 'order_no': orderNo,
      if (itemOfSpare != null) 'item_of_spare': itemOfSpare,
      if (productSymbol != null) 'product_symbol': productSymbol,
      if (orderQuantity != null) 'order_quantity': orderQuantity,
      if (matchedCase != null) 'matched_case': matchedCase,
      if (formSpec != null) 'form_spec': formSpec,
      if (productCode != null) 'product_code': productCode,
      if (article != null) 'article': article,
      if (note != null) 'note': note,
      if (contentJson != null) 'content_json': contentJson,
    });
  }

  ProductListRowsCompanion copyWith(
      {Value<int>? id,
      Value<int>? projectId,
      Value<String>? orderNo,
      Value<String>? itemOfSpare,
      Value<String>? productSymbol,
      Value<String>? orderQuantity,
      Value<String?>? matchedCase,
      Value<String>? formSpec,
      Value<String>? productCode,
      Value<String>? article,
      Value<String>? note,
      Value<String?>? contentJson}) {
    return ProductListRowsCompanion(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      orderNo: orderNo ?? this.orderNo,
      itemOfSpare: itemOfSpare ?? this.itemOfSpare,
      productSymbol: productSymbol ?? this.productSymbol,
      orderQuantity: orderQuantity ?? this.orderQuantity,
      matchedCase: matchedCase ?? this.matchedCase,
      formSpec: formSpec ?? this.formSpec,
      productCode: productCode ?? this.productCode,
      article: article ?? this.article,
      note: note ?? this.note,
      contentJson: contentJson ?? this.contentJson,
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
    if (orderQuantity.present) {
      map['order_quantity'] = Variable<String>(orderQuantity.value);
    }
    if (matchedCase.present) {
      map['matched_case'] = Variable<String>(matchedCase.value);
    }
    if (formSpec.present) {
      map['form_spec'] = Variable<String>(formSpec.value);
    }
    if (productCode.present) {
      map['product_code'] = Variable<String>(productCode.value);
    }
    if (article.present) {
      map['article'] = Variable<String>(article.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
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
          ..write('orderQuantity: $orderQuantity, ')
          ..write('matchedCase: $matchedCase, ')
          ..write('formSpec: $formSpec, ')
          ..write('productCode: $productCode, ')
          ..write('article: $article, ')
          ..write('note: $note, ')
          ..write('contentJson: $contentJson')
          ..write(')'))
        .toString();
  }
}

class $MaskProfilesTable extends MaskProfiles
    with TableInfo<$MaskProfilesTable, MaskProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MaskProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _profileNameMeta =
      const VerificationMeta('profileName');
  @override
  late final GeneratedColumn<String> profileName = GeneratedColumn<String>(
      'profile_name', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _rectsJsonMeta =
      const VerificationMeta('rectsJson');
  @override
  late final GeneratedColumn<String> rectsJson = GeneratedColumn<String>(
      'rects_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _promptIdMeta =
      const VerificationMeta('promptId');
  @override
  late final GeneratedColumn<String> promptId = GeneratedColumn<String>(
      'prompt_id', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _productListFieldsJsonMeta =
      const VerificationMeta('productListFieldsJson');
  @override
  late final GeneratedColumn<String> productListFieldsJson =
      GeneratedColumn<String>('product_list_fields_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _nifudaFieldsJsonMeta =
      const VerificationMeta('nifudaFieldsJson');
  @override
  late final GeneratedColumn<String> nifudaFieldsJson = GeneratedColumn<String>(
      'nifuda_fields_json', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _matchingPairsJsonMeta =
      const VerificationMeta('matchingPairsJson');
  @override
  late final GeneratedColumn<String> matchingPairsJson =
      GeneratedColumn<String>('matching_pairs_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _extractionModeMeta =
      const VerificationMeta('extractionMode');
  @override
  late final GeneratedColumn<String> extractionMode = GeneratedColumn<String>(
      'extraction_mode', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        profileName,
        rectsJson,
        promptId,
        productListFieldsJson,
        nifudaFieldsJson,
        matchingPairsJson,
        extractionMode
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mask_profiles';
  @override
  VerificationContext validateIntegrity(Insertable<MaskProfile> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('profile_name')) {
      context.handle(
          _profileNameMeta,
          profileName.isAcceptableOrUnknown(
              data['profile_name']!, _profileNameMeta));
    } else if (isInserting) {
      context.missing(_profileNameMeta);
    }
    if (data.containsKey('rects_json')) {
      context.handle(_rectsJsonMeta,
          rectsJson.isAcceptableOrUnknown(data['rects_json']!, _rectsJsonMeta));
    } else if (isInserting) {
      context.missing(_rectsJsonMeta);
    }
    if (data.containsKey('prompt_id')) {
      context.handle(_promptIdMeta,
          promptId.isAcceptableOrUnknown(data['prompt_id']!, _promptIdMeta));
    }
    if (data.containsKey('product_list_fields_json')) {
      context.handle(
          _productListFieldsJsonMeta,
          productListFieldsJson.isAcceptableOrUnknown(
              data['product_list_fields_json']!, _productListFieldsJsonMeta));
    }
    if (data.containsKey('nifuda_fields_json')) {
      context.handle(
          _nifudaFieldsJsonMeta,
          nifudaFieldsJson.isAcceptableOrUnknown(
              data['nifuda_fields_json']!, _nifudaFieldsJsonMeta));
    }
    if (data.containsKey('matching_pairs_json')) {
      context.handle(
          _matchingPairsJsonMeta,
          matchingPairsJson.isAcceptableOrUnknown(
              data['matching_pairs_json']!, _matchingPairsJsonMeta));
    }
    if (data.containsKey('extraction_mode')) {
      context.handle(
          _extractionModeMeta,
          extractionMode.isAcceptableOrUnknown(
              data['extraction_mode']!, _extractionModeMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MaskProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MaskProfile(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      profileName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}profile_name'])!,
      rectsJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}rects_json'])!,
      promptId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prompt_id']),
      productListFieldsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}product_list_fields_json']),
      nifudaFieldsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}nifuda_fields_json']),
      matchingPairsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}matching_pairs_json']),
      extractionMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}extraction_mode']),
    );
  }

  @override
  $MaskProfilesTable createAlias(String alias) {
    return $MaskProfilesTable(attachedDatabase, alias);
  }
}

class MaskProfile extends DataClass implements Insertable<MaskProfile> {
  final int id;
  final String profileName;
  final String rectsJson;
  final String? promptId;
  final String? productListFieldsJson;
  final String? nifudaFieldsJson;
  final String? matchingPairsJson;
  final String? extractionMode;
  const MaskProfile(
      {required this.id,
      required this.profileName,
      required this.rectsJson,
      this.promptId,
      this.productListFieldsJson,
      this.nifudaFieldsJson,
      this.matchingPairsJson,
      this.extractionMode});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['profile_name'] = Variable<String>(profileName);
    map['rects_json'] = Variable<String>(rectsJson);
    if (!nullToAbsent || promptId != null) {
      map['prompt_id'] = Variable<String>(promptId);
    }
    if (!nullToAbsent || productListFieldsJson != null) {
      map['product_list_fields_json'] = Variable<String>(productListFieldsJson);
    }
    if (!nullToAbsent || nifudaFieldsJson != null) {
      map['nifuda_fields_json'] = Variable<String>(nifudaFieldsJson);
    }
    if (!nullToAbsent || matchingPairsJson != null) {
      map['matching_pairs_json'] = Variable<String>(matchingPairsJson);
    }
    if (!nullToAbsent || extractionMode != null) {
      map['extraction_mode'] = Variable<String>(extractionMode);
    }
    return map;
  }

  MaskProfilesCompanion toCompanion(bool nullToAbsent) {
    return MaskProfilesCompanion(
      id: Value(id),
      profileName: Value(profileName),
      rectsJson: Value(rectsJson),
      promptId: promptId == null && nullToAbsent
          ? const Value.absent()
          : Value(promptId),
      productListFieldsJson: productListFieldsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(productListFieldsJson),
      nifudaFieldsJson: nifudaFieldsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(nifudaFieldsJson),
      matchingPairsJson: matchingPairsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(matchingPairsJson),
      extractionMode: extractionMode == null && nullToAbsent
          ? const Value.absent()
          : Value(extractionMode),
    );
  }

  factory MaskProfile.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MaskProfile(
      id: serializer.fromJson<int>(json['id']),
      profileName: serializer.fromJson<String>(json['profileName']),
      rectsJson: serializer.fromJson<String>(json['rectsJson']),
      promptId: serializer.fromJson<String?>(json['promptId']),
      productListFieldsJson:
          serializer.fromJson<String?>(json['productListFieldsJson']),
      nifudaFieldsJson: serializer.fromJson<String?>(json['nifudaFieldsJson']),
      matchingPairsJson:
          serializer.fromJson<String?>(json['matchingPairsJson']),
      extractionMode: serializer.fromJson<String?>(json['extractionMode']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'profileName': serializer.toJson<String>(profileName),
      'rectsJson': serializer.toJson<String>(rectsJson),
      'promptId': serializer.toJson<String?>(promptId),
      'productListFieldsJson':
          serializer.toJson<String?>(productListFieldsJson),
      'nifudaFieldsJson': serializer.toJson<String?>(nifudaFieldsJson),
      'matchingPairsJson': serializer.toJson<String?>(matchingPairsJson),
      'extractionMode': serializer.toJson<String?>(extractionMode),
    };
  }

  MaskProfile copyWith(
          {int? id,
          String? profileName,
          String? rectsJson,
          Value<String?> promptId = const Value.absent(),
          Value<String?> productListFieldsJson = const Value.absent(),
          Value<String?> nifudaFieldsJson = const Value.absent(),
          Value<String?> matchingPairsJson = const Value.absent(),
          Value<String?> extractionMode = const Value.absent()}) =>
      MaskProfile(
        id: id ?? this.id,
        profileName: profileName ?? this.profileName,
        rectsJson: rectsJson ?? this.rectsJson,
        promptId: promptId.present ? promptId.value : this.promptId,
        productListFieldsJson: productListFieldsJson.present
            ? productListFieldsJson.value
            : this.productListFieldsJson,
        nifudaFieldsJson: nifudaFieldsJson.present
            ? nifudaFieldsJson.value
            : this.nifudaFieldsJson,
        matchingPairsJson: matchingPairsJson.present
            ? matchingPairsJson.value
            : this.matchingPairsJson,
        extractionMode:
            extractionMode.present ? extractionMode.value : this.extractionMode,
      );
  MaskProfile copyWithCompanion(MaskProfilesCompanion data) {
    return MaskProfile(
      id: data.id.present ? data.id.value : this.id,
      profileName:
          data.profileName.present ? data.profileName.value : this.profileName,
      rectsJson: data.rectsJson.present ? data.rectsJson.value : this.rectsJson,
      promptId: data.promptId.present ? data.promptId.value : this.promptId,
      productListFieldsJson: data.productListFieldsJson.present
          ? data.productListFieldsJson.value
          : this.productListFieldsJson,
      nifudaFieldsJson: data.nifudaFieldsJson.present
          ? data.nifudaFieldsJson.value
          : this.nifudaFieldsJson,
      matchingPairsJson: data.matchingPairsJson.present
          ? data.matchingPairsJson.value
          : this.matchingPairsJson,
      extractionMode: data.extractionMode.present
          ? data.extractionMode.value
          : this.extractionMode,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MaskProfile(')
          ..write('id: $id, ')
          ..write('profileName: $profileName, ')
          ..write('rectsJson: $rectsJson, ')
          ..write('promptId: $promptId, ')
          ..write('productListFieldsJson: $productListFieldsJson, ')
          ..write('nifudaFieldsJson: $nifudaFieldsJson, ')
          ..write('matchingPairsJson: $matchingPairsJson, ')
          ..write('extractionMode: $extractionMode')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      profileName,
      rectsJson,
      promptId,
      productListFieldsJson,
      nifudaFieldsJson,
      matchingPairsJson,
      extractionMode);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MaskProfile &&
          other.id == this.id &&
          other.profileName == this.profileName &&
          other.rectsJson == this.rectsJson &&
          other.promptId == this.promptId &&
          other.productListFieldsJson == this.productListFieldsJson &&
          other.nifudaFieldsJson == this.nifudaFieldsJson &&
          other.matchingPairsJson == this.matchingPairsJson &&
          other.extractionMode == this.extractionMode);
}

class MaskProfilesCompanion extends UpdateCompanion<MaskProfile> {
  final Value<int> id;
  final Value<String> profileName;
  final Value<String> rectsJson;
  final Value<String?> promptId;
  final Value<String?> productListFieldsJson;
  final Value<String?> nifudaFieldsJson;
  final Value<String?> matchingPairsJson;
  final Value<String?> extractionMode;
  const MaskProfilesCompanion({
    this.id = const Value.absent(),
    this.profileName = const Value.absent(),
    this.rectsJson = const Value.absent(),
    this.promptId = const Value.absent(),
    this.productListFieldsJson = const Value.absent(),
    this.nifudaFieldsJson = const Value.absent(),
    this.matchingPairsJson = const Value.absent(),
    this.extractionMode = const Value.absent(),
  });
  MaskProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String profileName,
    required String rectsJson,
    this.promptId = const Value.absent(),
    this.productListFieldsJson = const Value.absent(),
    this.nifudaFieldsJson = const Value.absent(),
    this.matchingPairsJson = const Value.absent(),
    this.extractionMode = const Value.absent(),
  })  : profileName = Value(profileName),
        rectsJson = Value(rectsJson);
  static Insertable<MaskProfile> custom({
    Expression<int>? id,
    Expression<String>? profileName,
    Expression<String>? rectsJson,
    Expression<String>? promptId,
    Expression<String>? productListFieldsJson,
    Expression<String>? nifudaFieldsJson,
    Expression<String>? matchingPairsJson,
    Expression<String>? extractionMode,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileName != null) 'profile_name': profileName,
      if (rectsJson != null) 'rects_json': rectsJson,
      if (promptId != null) 'prompt_id': promptId,
      if (productListFieldsJson != null)
        'product_list_fields_json': productListFieldsJson,
      if (nifudaFieldsJson != null) 'nifuda_fields_json': nifudaFieldsJson,
      if (matchingPairsJson != null) 'matching_pairs_json': matchingPairsJson,
      if (extractionMode != null) 'extraction_mode': extractionMode,
    });
  }

  MaskProfilesCompanion copyWith(
      {Value<int>? id,
      Value<String>? profileName,
      Value<String>? rectsJson,
      Value<String?>? promptId,
      Value<String?>? productListFieldsJson,
      Value<String?>? nifudaFieldsJson,
      Value<String?>? matchingPairsJson,
      Value<String?>? extractionMode}) {
    return MaskProfilesCompanion(
      id: id ?? this.id,
      profileName: profileName ?? this.profileName,
      rectsJson: rectsJson ?? this.rectsJson,
      promptId: promptId ?? this.promptId,
      productListFieldsJson:
          productListFieldsJson ?? this.productListFieldsJson,
      nifudaFieldsJson: nifudaFieldsJson ?? this.nifudaFieldsJson,
      matchingPairsJson: matchingPairsJson ?? this.matchingPairsJson,
      extractionMode: extractionMode ?? this.extractionMode,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (profileName.present) {
      map['profile_name'] = Variable<String>(profileName.value);
    }
    if (rectsJson.present) {
      map['rects_json'] = Variable<String>(rectsJson.value);
    }
    if (promptId.present) {
      map['prompt_id'] = Variable<String>(promptId.value);
    }
    if (productListFieldsJson.present) {
      map['product_list_fields_json'] =
          Variable<String>(productListFieldsJson.value);
    }
    if (nifudaFieldsJson.present) {
      map['nifuda_fields_json'] = Variable<String>(nifudaFieldsJson.value);
    }
    if (matchingPairsJson.present) {
      map['matching_pairs_json'] = Variable<String>(matchingPairsJson.value);
    }
    if (extractionMode.present) {
      map['extraction_mode'] = Variable<String>(extractionMode.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MaskProfilesCompanion(')
          ..write('id: $id, ')
          ..write('profileName: $profileName, ')
          ..write('rectsJson: $rectsJson, ')
          ..write('promptId: $promptId, ')
          ..write('productListFieldsJson: $productListFieldsJson, ')
          ..write('nifudaFieldsJson: $nifudaFieldsJson, ')
          ..write('matchingPairsJson: $matchingPairsJson, ')
          ..write('extractionMode: $extractionMode')
          ..write(')'))
        .toString();
  }
}

class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _usernameMeta =
      const VerificationMeta('username');
  @override
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
      'username', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _passwordMeta =
      const VerificationMeta('password');
  @override
  late final GeneratedColumn<String> password = GeneratedColumn<String>(
      'password', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime,
      requiredDuringInsert: false,
      defaultValue: currentDateAndTime);
  @override
  List<GeneratedColumn> get $columns => [id, username, password, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(Insertable<User> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('username')) {
      context.handle(_usernameMeta,
          username.isAcceptableOrUnknown(data['username']!, _usernameMeta));
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('password')) {
      context.handle(_passwordMeta,
          password.isAcceptableOrUnknown(data['password']!, _passwordMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      username: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}username'])!,
      password: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}password']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final int id;
  final String username;
  final String? password;
  final DateTime createdAt;
  const User(
      {required this.id,
      required this.username,
      this.password,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || password != null) {
      map['password'] = Variable<String>(password);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      username: Value(username),
      password: password == null && nullToAbsent
          ? const Value.absent()
          : Value(password),
      createdAt: Value(createdAt),
    );
  }

  factory User.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<int>(json['id']),
      username: serializer.fromJson<String>(json['username']),
      password: serializer.fromJson<String?>(json['password']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'username': serializer.toJson<String>(username),
      'password': serializer.toJson<String?>(password),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  User copyWith(
          {int? id,
          String? username,
          Value<String?> password = const Value.absent(),
          DateTime? createdAt}) =>
      User(
        id: id ?? this.id,
        username: username ?? this.username,
        password: password.present ? password.value : this.password,
        createdAt: createdAt ?? this.createdAt,
      );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      username: data.username.present ? data.username.value : this.username,
      password: data.password.present ? data.password.value : this.password,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, username, password, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.username == this.username &&
          other.password == this.password &&
          other.createdAt == this.createdAt);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<int> id;
  final Value<String> username;
  final Value<String?> password;
  final Value<DateTime> createdAt;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.username = const Value.absent(),
    this.password = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  UsersCompanion.insert({
    this.id = const Value.absent(),
    required String username,
    this.password = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : username = Value(username);
  static Insertable<User> custom({
    Expression<int>? id,
    Expression<String>? username,
    Expression<String>? password,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (username != null) 'username': username,
      if (password != null) 'password': password,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  UsersCompanion copyWith(
      {Value<int>? id,
      Value<String>? username,
      Value<String?>? password,
      Value<DateTime>? createdAt}) {
    return UsersCompanion(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (password.present) {
      map['password'] = Variable<String>(password.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('username: $username, ')
          ..write('password: $password, ')
          ..write('createdAt: $createdAt')
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
  late final $MaskProfilesTable maskProfiles = $MaskProfilesTable(this);
  late final $UsersTable users = $UsersTable(this);
  late final Index nifudaProjectIdIdx = Index('nifuda_project_id_idx',
      'CREATE INDEX nifuda_project_id_idx ON nifuda_rows (project_id)');
  late final Index productListProjectIdIdx = Index(
      'product_list_project_id_idx',
      'CREATE INDEX product_list_project_id_idx ON product_list_rows (project_id)');
  late final ProjectsDao projectsDao = ProjectsDao(this as AppDatabase);
  late final NifudaRowsDao nifudaRowsDao = NifudaRowsDao(this as AppDatabase);
  late final ProductListRowsDao productListRowsDao =
      ProductListRowsDao(this as AppDatabase);
  late final MaskProfilesDao maskProfilesDao =
      MaskProfilesDao(this as AppDatabase);
  late final UsersDao usersDao = UsersDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        projects,
        nifudaRows,
        productListRows,
        maskProfiles,
        users,
        nifudaProjectIdIdx,
        productListProjectIdIdx
      ];
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
    (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()> {
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
    (Project, BaseReferences<_$AppDatabase, $ProjectsTable, Project>),
    Project,
    PrefetchHooks Function()>;
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

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

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
    (NifudaRow, BaseReferences<_$AppDatabase, $NifudaRowsTable, NifudaRow>),
    NifudaRow,
    PrefetchHooks Function()> {
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
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
    (NifudaRow, BaseReferences<_$AppDatabase, $NifudaRowsTable, NifudaRow>),
    NifudaRow,
    PrefetchHooks Function()>;
typedef $$ProductListRowsTableCreateCompanionBuilder = ProductListRowsCompanion
    Function({
  Value<int> id,
  required int projectId,
  required String orderNo,
  required String itemOfSpare,
  required String productSymbol,
  required String orderQuantity,
  Value<String?> matchedCase,
  required String formSpec,
  required String productCode,
  required String article,
  required String note,
  Value<String?> contentJson,
});
typedef $$ProductListRowsTableUpdateCompanionBuilder = ProductListRowsCompanion
    Function({
  Value<int> id,
  Value<int> projectId,
  Value<String> orderNo,
  Value<String> itemOfSpare,
  Value<String> productSymbol,
  Value<String> orderQuantity,
  Value<String?> matchedCase,
  Value<String> formSpec,
  Value<String> productCode,
  Value<String> article,
  Value<String> note,
  Value<String?> contentJson,
});

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

  ColumnFilters<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderNo => $composableBuilder(
      column: $table.orderNo, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get itemOfSpare => $composableBuilder(
      column: $table.itemOfSpare, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productSymbol => $composableBuilder(
      column: $table.productSymbol, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get orderQuantity => $composableBuilder(
      column: $table.orderQuantity, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchedCase => $composableBuilder(
      column: $table.matchedCase, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get formSpec => $composableBuilder(
      column: $table.formSpec, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get article => $composableBuilder(
      column: $table.article, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnFilters(column));
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

  ColumnOrderings<int> get projectId => $composableBuilder(
      column: $table.projectId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderNo => $composableBuilder(
      column: $table.orderNo, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get itemOfSpare => $composableBuilder(
      column: $table.itemOfSpare, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productSymbol => $composableBuilder(
      column: $table.productSymbol,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get orderQuantity => $composableBuilder(
      column: $table.orderQuantity,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchedCase => $composableBuilder(
      column: $table.matchedCase, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get formSpec => $composableBuilder(
      column: $table.formSpec, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get article => $composableBuilder(
      column: $table.article, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => ColumnOrderings(column));
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

  GeneratedColumn<int> get projectId =>
      $composableBuilder(column: $table.projectId, builder: (column) => column);

  GeneratedColumn<String> get orderNo =>
      $composableBuilder(column: $table.orderNo, builder: (column) => column);

  GeneratedColumn<String> get itemOfSpare => $composableBuilder(
      column: $table.itemOfSpare, builder: (column) => column);

  GeneratedColumn<String> get productSymbol => $composableBuilder(
      column: $table.productSymbol, builder: (column) => column);

  GeneratedColumn<String> get orderQuantity => $composableBuilder(
      column: $table.orderQuantity, builder: (column) => column);

  GeneratedColumn<String> get matchedCase => $composableBuilder(
      column: $table.matchedCase, builder: (column) => column);

  GeneratedColumn<String> get formSpec =>
      $composableBuilder(column: $table.formSpec, builder: (column) => column);

  GeneratedColumn<String> get productCode => $composableBuilder(
      column: $table.productCode, builder: (column) => column);

  GeneratedColumn<String> get article =>
      $composableBuilder(column: $table.article, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
      column: $table.contentJson, builder: (column) => column);
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
    (
      ProductListRow,
      BaseReferences<_$AppDatabase, $ProductListRowsTable, ProductListRow>
    ),
    ProductListRow,
    PrefetchHooks Function()> {
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
            Value<String> orderQuantity = const Value.absent(),
            Value<String?> matchedCase = const Value.absent(),
            Value<String> formSpec = const Value.absent(),
            Value<String> productCode = const Value.absent(),
            Value<String> article = const Value.absent(),
            Value<String> note = const Value.absent(),
            Value<String?> contentJson = const Value.absent(),
          }) =>
              ProductListRowsCompanion(
            id: id,
            projectId: projectId,
            orderNo: orderNo,
            itemOfSpare: itemOfSpare,
            productSymbol: productSymbol,
            orderQuantity: orderQuantity,
            matchedCase: matchedCase,
            formSpec: formSpec,
            productCode: productCode,
            article: article,
            note: note,
            contentJson: contentJson,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int projectId,
            required String orderNo,
            required String itemOfSpare,
            required String productSymbol,
            required String orderQuantity,
            Value<String?> matchedCase = const Value.absent(),
            required String formSpec,
            required String productCode,
            required String article,
            required String note,
            Value<String?> contentJson = const Value.absent(),
          }) =>
              ProductListRowsCompanion.insert(
            id: id,
            projectId: projectId,
            orderNo: orderNo,
            itemOfSpare: itemOfSpare,
            productSymbol: productSymbol,
            orderQuantity: orderQuantity,
            matchedCase: matchedCase,
            formSpec: formSpec,
            productCode: productCode,
            article: article,
            note: note,
            contentJson: contentJson,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
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
    (
      ProductListRow,
      BaseReferences<_$AppDatabase, $ProductListRowsTable, ProductListRow>
    ),
    ProductListRow,
    PrefetchHooks Function()>;
typedef $$MaskProfilesTableCreateCompanionBuilder = MaskProfilesCompanion
    Function({
  Value<int> id,
  required String profileName,
  required String rectsJson,
  Value<String?> promptId,
  Value<String?> productListFieldsJson,
  Value<String?> nifudaFieldsJson,
  Value<String?> matchingPairsJson,
  Value<String?> extractionMode,
});
typedef $$MaskProfilesTableUpdateCompanionBuilder = MaskProfilesCompanion
    Function({
  Value<int> id,
  Value<String> profileName,
  Value<String> rectsJson,
  Value<String?> promptId,
  Value<String?> productListFieldsJson,
  Value<String?> nifudaFieldsJson,
  Value<String?> matchingPairsJson,
  Value<String?> extractionMode,
});

class $$MaskProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $MaskProfilesTable> {
  $$MaskProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get profileName => $composableBuilder(
      column: $table.profileName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get rectsJson => $composableBuilder(
      column: $table.rectsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get promptId => $composableBuilder(
      column: $table.promptId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get productListFieldsJson => $composableBuilder(
      column: $table.productListFieldsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get nifudaFieldsJson => $composableBuilder(
      column: $table.nifudaFieldsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get matchingPairsJson => $composableBuilder(
      column: $table.matchingPairsJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get extractionMode => $composableBuilder(
      column: $table.extractionMode,
      builder: (column) => ColumnFilters(column));
}

class $$MaskProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $MaskProfilesTable> {
  $$MaskProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get profileName => $composableBuilder(
      column: $table.profileName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get rectsJson => $composableBuilder(
      column: $table.rectsJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get promptId => $composableBuilder(
      column: $table.promptId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get productListFieldsJson => $composableBuilder(
      column: $table.productListFieldsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get nifudaFieldsJson => $composableBuilder(
      column: $table.nifudaFieldsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get matchingPairsJson => $composableBuilder(
      column: $table.matchingPairsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get extractionMode => $composableBuilder(
      column: $table.extractionMode,
      builder: (column) => ColumnOrderings(column));
}

class $$MaskProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MaskProfilesTable> {
  $$MaskProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileName => $composableBuilder(
      column: $table.profileName, builder: (column) => column);

  GeneratedColumn<String> get rectsJson =>
      $composableBuilder(column: $table.rectsJson, builder: (column) => column);

  GeneratedColumn<String> get promptId =>
      $composableBuilder(column: $table.promptId, builder: (column) => column);

  GeneratedColumn<String> get productListFieldsJson => $composableBuilder(
      column: $table.productListFieldsJson, builder: (column) => column);

  GeneratedColumn<String> get nifudaFieldsJson => $composableBuilder(
      column: $table.nifudaFieldsJson, builder: (column) => column);

  GeneratedColumn<String> get matchingPairsJson => $composableBuilder(
      column: $table.matchingPairsJson, builder: (column) => column);

  GeneratedColumn<String> get extractionMode => $composableBuilder(
      column: $table.extractionMode, builder: (column) => column);
}

class $$MaskProfilesTableTableManager extends RootTableManager<
    _$AppDatabase,
    $MaskProfilesTable,
    MaskProfile,
    $$MaskProfilesTableFilterComposer,
    $$MaskProfilesTableOrderingComposer,
    $$MaskProfilesTableAnnotationComposer,
    $$MaskProfilesTableCreateCompanionBuilder,
    $$MaskProfilesTableUpdateCompanionBuilder,
    (
      MaskProfile,
      BaseReferences<_$AppDatabase, $MaskProfilesTable, MaskProfile>
    ),
    MaskProfile,
    PrefetchHooks Function()> {
  $$MaskProfilesTableTableManager(_$AppDatabase db, $MaskProfilesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MaskProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MaskProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MaskProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> profileName = const Value.absent(),
            Value<String> rectsJson = const Value.absent(),
            Value<String?> promptId = const Value.absent(),
            Value<String?> productListFieldsJson = const Value.absent(),
            Value<String?> nifudaFieldsJson = const Value.absent(),
            Value<String?> matchingPairsJson = const Value.absent(),
            Value<String?> extractionMode = const Value.absent(),
          }) =>
              MaskProfilesCompanion(
            id: id,
            profileName: profileName,
            rectsJson: rectsJson,
            promptId: promptId,
            productListFieldsJson: productListFieldsJson,
            nifudaFieldsJson: nifudaFieldsJson,
            matchingPairsJson: matchingPairsJson,
            extractionMode: extractionMode,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String profileName,
            required String rectsJson,
            Value<String?> promptId = const Value.absent(),
            Value<String?> productListFieldsJson = const Value.absent(),
            Value<String?> nifudaFieldsJson = const Value.absent(),
            Value<String?> matchingPairsJson = const Value.absent(),
            Value<String?> extractionMode = const Value.absent(),
          }) =>
              MaskProfilesCompanion.insert(
            id: id,
            profileName: profileName,
            rectsJson: rectsJson,
            promptId: promptId,
            productListFieldsJson: productListFieldsJson,
            nifudaFieldsJson: nifudaFieldsJson,
            matchingPairsJson: matchingPairsJson,
            extractionMode: extractionMode,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$MaskProfilesTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $MaskProfilesTable,
    MaskProfile,
    $$MaskProfilesTableFilterComposer,
    $$MaskProfilesTableOrderingComposer,
    $$MaskProfilesTableAnnotationComposer,
    $$MaskProfilesTableCreateCompanionBuilder,
    $$MaskProfilesTableUpdateCompanionBuilder,
    (
      MaskProfile,
      BaseReferences<_$AppDatabase, $MaskProfilesTable, MaskProfile>
    ),
    MaskProfile,
    PrefetchHooks Function()>;
typedef $$UsersTableCreateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  required String username,
  Value<String?> password,
  Value<DateTime> createdAt,
});
typedef $$UsersTableUpdateCompanionBuilder = UsersCompanion Function({
  Value<int> id,
  Value<String> username,
  Value<String?> password,
  Value<DateTime> createdAt,
});

class $$UsersTableFilterComposer extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));
}

class $$UsersTableOrderingComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get username => $composableBuilder(
      column: $table.username, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get password => $composableBuilder(
      column: $table.password, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AppDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get password =>
      $composableBuilder(column: $table.password, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$UsersTableTableManager extends RootTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()> {
  $$UsersTableTableManager(_$AppDatabase db, $UsersTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> username = const Value.absent(),
            Value<String?> password = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UsersCompanion(
            id: id,
            username: username,
            password: password,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String username,
            Value<String?> password = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
          }) =>
              UsersCompanion.insert(
            id: id,
            username: username,
            password: password,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$UsersTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $UsersTable,
    User,
    $$UsersTableFilterComposer,
    $$UsersTableOrderingComposer,
    $$UsersTableAnnotationComposer,
    $$UsersTableCreateCompanionBuilder,
    $$UsersTableUpdateCompanionBuilder,
    (User, BaseReferences<_$AppDatabase, $UsersTable, User>),
    User,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$NifudaRowsTableTableManager get nifudaRows =>
      $$NifudaRowsTableTableManager(_db, _db.nifudaRows);
  $$ProductListRowsTableTableManager get productListRows =>
      $$ProductListRowsTableTableManager(_db, _db.productListRows);
  $$MaskProfilesTableTableManager get maskProfiles =>
      $$MaskProfilesTableTableManager(_db, _db.maskProfiles);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
}

mixin _$ProjectsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProjectsTable get projects => attachedDatabase.projects;
}
mixin _$NifudaRowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $NifudaRowsTable get nifudaRows => attachedDatabase.nifudaRows;
}
mixin _$ProductListRowsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductListRowsTable get productListRows => attachedDatabase.productListRows;
}
mixin _$MaskProfilesDaoMixin on DatabaseAccessor<AppDatabase> {
  $MaskProfilesTable get maskProfiles => attachedDatabase.maskProfiles;
}
mixin _$UsersDaoMixin on DatabaseAccessor<AppDatabase> {
  $UsersTable get users => attachedDatabase.users;
}
