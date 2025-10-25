// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_collections.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProjectCollection on Isar {
  IsarCollection<Project> get projects => this.collection();
}

const ProjectSchema = CollectionSchema(
  name: r'Project',
  id: 3302999628838485849,
  properties: {
    r'inspectionStatus': PropertySchema(
      id: 0,
      name: r'inspectionStatus',
      type: IsarType.string,
    ),
    r'projectCode': PropertySchema(
      id: 1,
      name: r'projectCode',
      type: IsarType.string,
    ),
    r'projectFolderPath': PropertySchema(
      id: 2,
      name: r'projectFolderPath',
      type: IsarType.string,
    ),
    r'projectTitle': PropertySchema(
      id: 3,
      name: r'projectTitle',
      type: IsarType.string,
    )
  },
  estimateSize: _projectEstimateSize,
  serialize: _projectSerialize,
  deserialize: _projectDeserialize,
  deserializeProp: _projectDeserializeProp,
  idName: r'id',
  indexes: {
    r'projectCode': IndexSchema(
      id: 2988860783562874805,
      name: r'projectCode',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectCode',
          type: IndexType.hash,
          caseSensitive: true,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _projectGetId,
  getLinks: _projectGetLinks,
  attach: _projectAttach,
  version: '3.1.0+1',
);

int _projectEstimateSize(
  Project object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.inspectionStatus.length * 3;
  bytesCount += 3 + object.projectCode.length * 3;
  bytesCount += 3 + object.projectFolderPath.length * 3;
  bytesCount += 3 + object.projectTitle.length * 3;
  return bytesCount;
}

void _projectSerialize(
  Project object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.inspectionStatus);
  writer.writeString(offsets[1], object.projectCode);
  writer.writeString(offsets[2], object.projectFolderPath);
  writer.writeString(offsets[3], object.projectTitle);
}

Project _projectDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = Project();
  object.id = id;
  object.inspectionStatus = reader.readString(offsets[0]);
  object.projectCode = reader.readString(offsets[1]);
  object.projectFolderPath = reader.readString(offsets[2]);
  object.projectTitle = reader.readString(offsets[3]);
  return object;
}

P _projectDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _projectGetId(Project object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _projectGetLinks(Project object) {
  return [];
}

void _projectAttach(IsarCollection<dynamic> col, Id id, Project object) {
  object.id = id;
}

extension ProjectByIndex on IsarCollection<Project> {
  Future<Project?> getByProjectCode(String projectCode) {
    return getByIndex(r'projectCode', [projectCode]);
  }

  Project? getByProjectCodeSync(String projectCode) {
    return getByIndexSync(r'projectCode', [projectCode]);
  }

  Future<bool> deleteByProjectCode(String projectCode) {
    return deleteByIndex(r'projectCode', [projectCode]);
  }

  bool deleteByProjectCodeSync(String projectCode) {
    return deleteByIndexSync(r'projectCode', [projectCode]);
  }

  Future<List<Project?>> getAllByProjectCode(List<String> projectCodeValues) {
    final values = projectCodeValues.map((e) => [e]).toList();
    return getAllByIndex(r'projectCode', values);
  }

  List<Project?> getAllByProjectCodeSync(List<String> projectCodeValues) {
    final values = projectCodeValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'projectCode', values);
  }

  Future<int> deleteAllByProjectCode(List<String> projectCodeValues) {
    final values = projectCodeValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'projectCode', values);
  }

  int deleteAllByProjectCodeSync(List<String> projectCodeValues) {
    final values = projectCodeValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'projectCode', values);
  }

  Future<Id> putByProjectCode(Project object) {
    return putByIndex(r'projectCode', object);
  }

  Id putByProjectCodeSync(Project object, {bool saveLinks = true}) {
    return putByIndexSync(r'projectCode', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByProjectCode(List<Project> objects) {
    return putAllByIndex(r'projectCode', objects);
  }

  List<Id> putAllByProjectCodeSync(List<Project> objects,
      {bool saveLinks = true}) {
    return putAllByIndexSync(r'projectCode', objects, saveLinks: saveLinks);
  }
}

extension ProjectQueryWhereSort on QueryBuilder<Project, Project, QWhere> {
  QueryBuilder<Project, Project, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension ProjectQueryWhere on QueryBuilder<Project, Project, QWhereClause> {
  QueryBuilder<Project, Project, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> projectCodeEqualTo(
      String projectCode) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectCode',
        value: [projectCode],
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterWhereClause> projectCodeNotEqualTo(
      String projectCode) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectCode',
              lower: [],
              upper: [projectCode],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectCode',
              lower: [projectCode],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectCode',
              lower: [projectCode],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectCode',
              lower: [],
              upper: [projectCode],
              includeUpper: false,
            ));
      }
    });
  }
}

extension ProjectQueryFilter
    on QueryBuilder<Project, Project, QFilterCondition> {
  QueryBuilder<Project, Project, QAfterFilterCondition> idEqualTo(Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> inspectionStatusEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inspectionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      inspectionStatusGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'inspectionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      inspectionStatusLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'inspectionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> inspectionStatusBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'inspectionStatus',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      inspectionStatusStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'inspectionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      inspectionStatusEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'inspectionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      inspectionStatusContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'inspectionStatus',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> inspectionStatusMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'inspectionStatus',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      inspectionStatusIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'inspectionStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      inspectionStatusIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'inspectionStatus',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'projectCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'projectCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'projectCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'projectCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'projectCode',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectFolderPath',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'projectFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'projectFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'projectFolderPath',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'projectFolderPath',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectFolderPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectFolderPathIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'projectFolderPath',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectTitle',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'projectTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'projectTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'projectTitle',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'projectTitle',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition> projectTitleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectTitle',
        value: '',
      ));
    });
  }

  QueryBuilder<Project, Project, QAfterFilterCondition>
      projectTitleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'projectTitle',
        value: '',
      ));
    });
  }
}

extension ProjectQueryObject
    on QueryBuilder<Project, Project, QFilterCondition> {}

extension ProjectQueryLinks
    on QueryBuilder<Project, Project, QFilterCondition> {}

extension ProjectQuerySortBy on QueryBuilder<Project, Project, QSortBy> {
  QueryBuilder<Project, Project, QAfterSortBy> sortByInspectionStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inspectionStatus', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByInspectionStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inspectionStatus', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectCode', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectCode', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectFolderPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFolderPath', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectFolderPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFolderPath', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectTitle', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> sortByProjectTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectTitle', Sort.desc);
    });
  }
}

extension ProjectQuerySortThenBy
    on QueryBuilder<Project, Project, QSortThenBy> {
  QueryBuilder<Project, Project, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByInspectionStatus() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inspectionStatus', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByInspectionStatusDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'inspectionStatus', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectCode', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectCode', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectFolderPath() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFolderPath', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectFolderPathDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectFolderPath', Sort.desc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectTitle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectTitle', Sort.asc);
    });
  }

  QueryBuilder<Project, Project, QAfterSortBy> thenByProjectTitleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectTitle', Sort.desc);
    });
  }
}

extension ProjectQueryWhereDistinct
    on QueryBuilder<Project, Project, QDistinct> {
  QueryBuilder<Project, Project, QDistinct> distinctByInspectionStatus(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'inspectionStatus',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByProjectCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByProjectFolderPath(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectFolderPath',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<Project, Project, QDistinct> distinctByProjectTitle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectTitle', caseSensitive: caseSensitive);
    });
  }
}

extension ProjectQueryProperty
    on QueryBuilder<Project, Project, QQueryProperty> {
  QueryBuilder<Project, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> inspectionStatusProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'inspectionStatus');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> projectCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectCode');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> projectFolderPathProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectFolderPath');
    });
  }

  QueryBuilder<Project, String, QQueryOperations> projectTitleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectTitle');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetNifudaRowCollection on Isar {
  IsarCollection<NifudaRow> get nifudaRows => this.collection();
}

const NifudaRowSchema = CollectionSchema(
  name: r'NifudaRow',
  id: 1891731996213446474,
  properties: {
    r'arrangementCode': PropertySchema(
      id: 0,
      name: r'arrangementCode',
      type: IsarType.string,
    ),
    r'documentNumber': PropertySchema(
      id: 1,
      name: r'documentNumber',
      type: IsarType.string,
    ),
    r'form': PropertySchema(
      id: 2,
      name: r'form',
      type: IsarType.string,
    ),
    r'itemNumber': PropertySchema(
      id: 3,
      name: r'itemNumber',
      type: IsarType.string,
    ),
    r'productName': PropertySchema(
      id: 4,
      name: r'productName',
      type: IsarType.string,
    ),
    r'projectId': PropertySchema(
      id: 5,
      name: r'projectId',
      type: IsarType.long,
    ),
    r'quantity': PropertySchema(
      id: 6,
      name: r'quantity',
      type: IsarType.string,
    ),
    r'remarks': PropertySchema(
      id: 7,
      name: r'remarks',
      type: IsarType.string,
    ),
    r'seiban': PropertySchema(
      id: 8,
      name: r'seiban',
      type: IsarType.string,
    )
  },
  estimateSize: _nifudaRowEstimateSize,
  serialize: _nifudaRowSerialize,
  deserialize: _nifudaRowDeserialize,
  deserializeProp: _nifudaRowDeserializeProp,
  idName: r'id',
  indexes: {
    r'projectId': IndexSchema(
      id: 3305656282123791113,
      name: r'projectId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _nifudaRowGetId,
  getLinks: _nifudaRowGetLinks,
  attach: _nifudaRowAttach,
  version: '3.1.0+1',
);

int _nifudaRowEstimateSize(
  NifudaRow object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.arrangementCode.length * 3;
  bytesCount += 3 + object.documentNumber.length * 3;
  bytesCount += 3 + object.form.length * 3;
  bytesCount += 3 + object.itemNumber.length * 3;
  bytesCount += 3 + object.productName.length * 3;
  bytesCount += 3 + object.quantity.length * 3;
  bytesCount += 3 + object.remarks.length * 3;
  bytesCount += 3 + object.seiban.length * 3;
  return bytesCount;
}

void _nifudaRowSerialize(
  NifudaRow object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.arrangementCode);
  writer.writeString(offsets[1], object.documentNumber);
  writer.writeString(offsets[2], object.form);
  writer.writeString(offsets[3], object.itemNumber);
  writer.writeString(offsets[4], object.productName);
  writer.writeLong(offsets[5], object.projectId);
  writer.writeString(offsets[6], object.quantity);
  writer.writeString(offsets[7], object.remarks);
  writer.writeString(offsets[8], object.seiban);
}

NifudaRow _nifudaRowDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = NifudaRow();
  object.arrangementCode = reader.readString(offsets[0]);
  object.documentNumber = reader.readString(offsets[1]);
  object.form = reader.readString(offsets[2]);
  object.id = id;
  object.itemNumber = reader.readString(offsets[3]);
  object.productName = reader.readString(offsets[4]);
  object.projectId = reader.readLong(offsets[5]);
  object.quantity = reader.readString(offsets[6]);
  object.remarks = reader.readString(offsets[7]);
  object.seiban = reader.readString(offsets[8]);
  return object;
}

P _nifudaRowDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readLong(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _nifudaRowGetId(NifudaRow object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _nifudaRowGetLinks(NifudaRow object) {
  return [];
}

void _nifudaRowAttach(IsarCollection<dynamic> col, Id id, NifudaRow object) {
  object.id = id;
}

extension NifudaRowQueryWhereSort
    on QueryBuilder<NifudaRow, NifudaRow, QWhere> {
  QueryBuilder<NifudaRow, NifudaRow, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhere> anyProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'projectId'),
      );
    });
  }
}

extension NifudaRowQueryWhere
    on QueryBuilder<NifudaRow, NifudaRow, QWhereClause> {
  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> idNotEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> idGreaterThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> idLessThan(Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> projectIdEqualTo(
      int projectId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectId',
        value: [projectId],
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> projectIdNotEqualTo(
      int projectId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> projectIdGreaterThan(
    int projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [projectId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> projectIdLessThan(
    int projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [],
        upper: [projectId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterWhereClause> projectIdBetween(
    int lowerProjectId,
    int upperProjectId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [lowerProjectId],
        includeLower: includeLower,
        upper: [upperProjectId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension NifudaRowQueryFilter
    on QueryBuilder<NifudaRow, NifudaRow, QFilterCondition> {
  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'arrangementCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'arrangementCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'arrangementCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'arrangementCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'arrangementCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'arrangementCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'arrangementCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'arrangementCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'arrangementCode',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      arrangementCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'arrangementCode',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'documentNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'documentNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'documentNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'documentNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'documentNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'documentNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'documentNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'documentNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      documentNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'documentNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'form',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'form',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'form',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'form',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'form',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'form',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'form',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'form',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'form',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> formIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'form',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> itemNumberEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      itemNumberGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> itemNumberLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> itemNumberBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemNumber',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      itemNumberStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> itemNumberEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> itemNumberContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemNumber',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> itemNumberMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemNumber',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      itemNumberIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      itemNumberIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemNumber',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> productNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      productNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> productNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> productNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      productNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> productNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> productNameContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> productNameMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      productNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      productNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productName',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> projectIdEqualTo(
      int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      projectIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> projectIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> projectIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'quantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'quantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'quantity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> quantityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'quantity',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      quantityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'quantity',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remarks',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remarks',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remarks',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> remarksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition>
      remarksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remarks',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seiban',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'seiban',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'seiban',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'seiban',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'seiban',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'seiban',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanContains(
      String value,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'seiban',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanMatches(
      String pattern,
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'seiban',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'seiban',
        value: '',
      ));
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterFilterCondition> seibanIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'seiban',
        value: '',
      ));
    });
  }
}

extension NifudaRowQueryObject
    on QueryBuilder<NifudaRow, NifudaRow, QFilterCondition> {}

extension NifudaRowQueryLinks
    on QueryBuilder<NifudaRow, NifudaRow, QFilterCondition> {}

extension NifudaRowQuerySortBy on QueryBuilder<NifudaRow, NifudaRow, QSortBy> {
  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByArrangementCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrangementCode', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByArrangementCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrangementCode', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByDocumentNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentNumber', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByDocumentNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentNumber', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByForm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'form', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByFormDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'form', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByItemNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByItemNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortBySeiban() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seiban', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> sortBySeibanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seiban', Sort.desc);
    });
  }
}

extension NifudaRowQuerySortThenBy
    on QueryBuilder<NifudaRow, NifudaRow, QSortThenBy> {
  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByArrangementCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrangementCode', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByArrangementCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'arrangementCode', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByDocumentNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentNumber', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByDocumentNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'documentNumber', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByForm() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'form', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByFormDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'form', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByItemNumber() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByItemNumberDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemNumber', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByProductName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByProductNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productName', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'quantity', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByRemarks() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenByRemarksDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remarks', Sort.desc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenBySeiban() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seiban', Sort.asc);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QAfterSortBy> thenBySeibanDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'seiban', Sort.desc);
    });
  }
}

extension NifudaRowQueryWhereDistinct
    on QueryBuilder<NifudaRow, NifudaRow, QDistinct> {
  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByArrangementCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'arrangementCode',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByDocumentNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'documentNumber',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByForm(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'form', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByItemNumber(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemNumber', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByProductName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId');
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByQuantity(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'quantity', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctByRemarks(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remarks', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<NifudaRow, NifudaRow, QDistinct> distinctBySeiban(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'seiban', caseSensitive: caseSensitive);
    });
  }
}

extension NifudaRowQueryProperty
    on QueryBuilder<NifudaRow, NifudaRow, QQueryProperty> {
  QueryBuilder<NifudaRow, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> arrangementCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'arrangementCode');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> documentNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'documentNumber');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> formProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'form');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> itemNumberProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemNumber');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> productNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productName');
    });
  }

  QueryBuilder<NifudaRow, int, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> quantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'quantity');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> remarksProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remarks');
    });
  }

  QueryBuilder<NifudaRow, String, QQueryOperations> seibanProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'seiban');
    });
  }
}

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetProductListRowCollection on Isar {
  IsarCollection<ProductListRow> get productListRows => this.collection();
}

const ProductListRowSchema = CollectionSchema(
  name: r'ProductListRow',
  id: 4147488872298603244,
  properties: {
    r'article': PropertySchema(
      id: 0,
      name: r'article',
      type: IsarType.string,
    ),
    r'formSpec': PropertySchema(
      id: 1,
      name: r'formSpec',
      type: IsarType.string,
    ),
    r'itemOfSpare': PropertySchema(
      id: 2,
      name: r'itemOfSpare',
      type: IsarType.string,
    ),
    r'note': PropertySchema(
      id: 3,
      name: r'note',
      type: IsarType.string,
    ),
    r'orderNo': PropertySchema(
      id: 4,
      name: r'orderNo',
      type: IsarType.string,
    ),
    r'orderQuantity': PropertySchema(
      id: 5,
      name: r'orderQuantity',
      type: IsarType.string,
    ),
    r'productCode': PropertySchema(
      id: 6,
      name: r'productCode',
      type: IsarType.string,
    ),
    r'productSymbol': PropertySchema(
      id: 7,
      name: r'productSymbol',
      type: IsarType.string,
    ),
    r'projectId': PropertySchema(
      id: 8,
      name: r'projectId',
      type: IsarType.long,
    )
  },
  estimateSize: _productListRowEstimateSize,
  serialize: _productListRowSerialize,
  deserialize: _productListRowDeserialize,
  deserializeProp: _productListRowDeserializeProp,
  idName: r'id',
  indexes: {
    r'projectId': IndexSchema(
      id: 3305656282123791113,
      name: r'projectId',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'projectId',
          type: IndexType.value,
          caseSensitive: false,
        )
      ],
    )
  },
  links: {},
  embeddedSchemas: {},
  getId: _productListRowGetId,
  getLinks: _productListRowGetLinks,
  attach: _productListRowAttach,
  version: '3.1.0+1',
);

int _productListRowEstimateSize(
  ProductListRow object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.article.length * 3;
  bytesCount += 3 + object.formSpec.length * 3;
  bytesCount += 3 + object.itemOfSpare.length * 3;
  bytesCount += 3 + object.note.length * 3;
  bytesCount += 3 + object.orderNo.length * 3;
  bytesCount += 3 + object.orderQuantity.length * 3;
  bytesCount += 3 + object.productCode.length * 3;
  bytesCount += 3 + object.productSymbol.length * 3;
  return bytesCount;
}

void _productListRowSerialize(
  ProductListRow object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.article);
  writer.writeString(offsets[1], object.formSpec);
  writer.writeString(offsets[2], object.itemOfSpare);
  writer.writeString(offsets[3], object.note);
  writer.writeString(offsets[4], object.orderNo);
  writer.writeString(offsets[5], object.orderQuantity);
  writer.writeString(offsets[6], object.productCode);
  writer.writeString(offsets[7], object.productSymbol);
  writer.writeLong(offsets[8], object.projectId);
}

ProductListRow _productListRowDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = ProductListRow();
  object.article = reader.readString(offsets[0]);
  object.formSpec = reader.readString(offsets[1]);
  object.id = id;
  object.itemOfSpare = reader.readString(offsets[2]);
  object.note = reader.readString(offsets[3]);
  object.orderNo = reader.readString(offsets[4]);
  object.orderQuantity = reader.readString(offsets[5]);
  object.productCode = reader.readString(offsets[6]);
  object.productSymbol = reader.readString(offsets[7]);
  object.projectId = reader.readLong(offsets[8]);
  return object;
}

P _productListRowDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readString(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _productListRowGetId(ProductListRow object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _productListRowGetLinks(ProductListRow object) {
  return [];
}

void _productListRowAttach(
    IsarCollection<dynamic> col, Id id, ProductListRow object) {
  object.id = id;
}

extension ProductListRowQueryWhereSort
    on QueryBuilder<ProductListRow, ProductListRow, QWhere> {
  QueryBuilder<ProductListRow, ProductListRow, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhere> anyProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        const IndexWhereClause.any(indexName: r'projectId'),
      );
    });
  }
}

extension ProductListRowQueryWhere
    on QueryBuilder<ProductListRow, ProductListRow, QWhereClause> {
  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause>
      projectIdEqualTo(int projectId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.equalTo(
        indexName: r'projectId',
        value: [projectId],
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause>
      projectIdNotEqualTo(int projectId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ));
      } else {
        return query
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [projectId],
              includeLower: false,
              upper: [],
            ))
            .addWhereClause(IndexWhereClause.between(
              indexName: r'projectId',
              lower: [],
              upper: [projectId],
              includeUpper: false,
            ));
      }
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause>
      projectIdGreaterThan(
    int projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [projectId],
        includeLower: include,
        upper: [],
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause>
      projectIdLessThan(
    int projectId, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [],
        upper: [projectId],
        includeUpper: include,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterWhereClause>
      projectIdBetween(
    int lowerProjectId,
    int upperProjectId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IndexWhereClause.between(
        indexName: r'projectId',
        lower: [lowerProjectId],
        includeLower: includeLower,
        upper: [upperProjectId],
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProductListRowQueryFilter
    on QueryBuilder<ProductListRow, ProductListRow, QFilterCondition> {
  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'article',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'article',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'article',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'article',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'article',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'article',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'article',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'article',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'article',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      articleIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'article',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formSpec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'formSpec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'formSpec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'formSpec',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'formSpec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'formSpec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'formSpec',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'formSpec',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'formSpec',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      formSpecIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'formSpec',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemOfSpare',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'itemOfSpare',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'itemOfSpare',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'itemOfSpare',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'itemOfSpare',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'itemOfSpare',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'itemOfSpare',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'itemOfSpare',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'itemOfSpare',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      itemOfSpareIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'itemOfSpare',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'note',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'note',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'note',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      noteIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'note',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderNo',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orderNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orderNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orderNo',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orderNo',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderNo',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderNoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orderNo',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'orderQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'orderQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'orderQuantity',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'orderQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'orderQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'orderQuantity',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'orderQuantity',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'orderQuantity',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      orderQuantityIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'orderQuantity',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productCode',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productCode',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productCode',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productCodeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productCode',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productSymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'productSymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'productSymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'productSymbol',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'productSymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'productSymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'productSymbol',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'productSymbol',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'productSymbol',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      productSymbolIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'productSymbol',
        value: '',
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      projectIdEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      projectIdGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      projectIdLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'projectId',
        value: value,
      ));
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterFilterCondition>
      projectIdBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'projectId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension ProductListRowQueryObject
    on QueryBuilder<ProductListRow, ProductListRow, QFilterCondition> {}

extension ProductListRowQueryLinks
    on QueryBuilder<ProductListRow, ProductListRow, QFilterCondition> {}

extension ProductListRowQuerySortBy
    on QueryBuilder<ProductListRow, ProductListRow, QSortBy> {
  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> sortByArticle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'article', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByArticleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'article', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> sortByFormSpec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formSpec', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByFormSpecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formSpec', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByItemOfSpare() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemOfSpare', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByItemOfSpareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemOfSpare', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> sortByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> sortByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> sortByOrderNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNo', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByOrderNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNo', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByOrderQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderQuantity', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByOrderQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderQuantity', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByProductCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByProductCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByProductSymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productSymbol', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByProductSymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productSymbol', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> sortByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      sortByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }
}

extension ProductListRowQuerySortThenBy
    on QueryBuilder<ProductListRow, ProductListRow, QSortThenBy> {
  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenByArticle() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'article', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByArticleDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'article', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenByFormSpec() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formSpec', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByFormSpecDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'formSpec', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByItemOfSpare() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemOfSpare', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByItemOfSpareDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'itemOfSpare', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenByNote() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenByNoteDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'note', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenByOrderNo() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNo', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByOrderNoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderNo', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByOrderQuantity() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderQuantity', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByOrderQuantityDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'orderQuantity', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByProductCode() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByProductCodeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productCode', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByProductSymbol() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productSymbol', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByProductSymbolDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'productSymbol', Sort.desc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy> thenByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.asc);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QAfterSortBy>
      thenByProjectIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'projectId', Sort.desc);
    });
  }
}

extension ProductListRowQueryWhereDistinct
    on QueryBuilder<ProductListRow, ProductListRow, QDistinct> {
  QueryBuilder<ProductListRow, ProductListRow, QDistinct> distinctByArticle(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'article', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct> distinctByFormSpec(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'formSpec', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct> distinctByItemOfSpare(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'itemOfSpare', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct> distinctByNote(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'note', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct> distinctByOrderNo(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderNo', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct>
      distinctByOrderQuantity({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'orderQuantity',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct> distinctByProductCode(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productCode', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct>
      distinctByProductSymbol({bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'productSymbol',
          caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<ProductListRow, ProductListRow, QDistinct>
      distinctByProjectId() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'projectId');
    });
  }
}

extension ProductListRowQueryProperty
    on QueryBuilder<ProductListRow, ProductListRow, QQueryProperty> {
  QueryBuilder<ProductListRow, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations> articleProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'article');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations> formSpecProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'formSpec');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations> itemOfSpareProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'itemOfSpare');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations> noteProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'note');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations> orderNoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderNo');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations>
      orderQuantityProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'orderQuantity');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations> productCodeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productCode');
    });
  }

  QueryBuilder<ProductListRow, String, QQueryOperations>
      productSymbolProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'productSymbol');
    });
  }

  QueryBuilder<ProductListRow, int, QQueryOperations> projectIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'projectId');
    });
  }
}
