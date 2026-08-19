// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PendingOperationsTable extends PendingOperations
    with TableInfo<$PendingOperationsTable, PendingOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _httpMethodMeta = const VerificationMeta(
    'httpMethod',
  );
  @override
  late final GeneratedColumn<String> httpMethod = GeneratedColumn<String>(
    'http_method',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<int> userId = GeneratedColumn<int>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  @override
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextRetryAtMeta = const VerificationMeta(
    'nextRetryAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextRetryAt = GeneratedColumn<DateTime>(
    'next_retry_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _responseJsonMeta = const VerificationMeta(
    'responseJson',
  );
  @override
  late final GeneratedColumn<String> responseJson = GeneratedColumn<String>(
    'response_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localRecordKeyMeta = const VerificationMeta(
    'localRecordKey',
  );
  @override
  late final GeneratedColumn<String> localRecordKey = GeneratedColumn<String>(
    'local_record_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    endpoint,
    httpMethod,
    userId,
    idempotencyKey,
    payloadJson,
    createdAt,
    status,
    attemptCount,
    nextRetryAt,
    lastError,
    responseJson,
    localRecordKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<PendingOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('http_method')) {
      context.handle(
        _httpMethodMeta,
        httpMethod.isAcceptableOrUnknown(data['http_method']!, _httpMethodMeta),
      );
    } else if (isInserting) {
      context.missing(_httpMethodMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_idempotencyKeyMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_retry_at')) {
      context.handle(
        _nextRetryAtMeta,
        nextRetryAt.isAcceptableOrUnknown(
          data['next_retry_at']!,
          _nextRetryAtMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('response_json')) {
      context.handle(
        _responseJsonMeta,
        responseJson.isAcceptableOrUnknown(
          data['response_json']!,
          _responseJsonMeta,
        ),
      );
    }
    if (data.containsKey('local_record_key')) {
      context.handle(
        _localRecordKeyMeta,
        localRecordKey.isAcceptableOrUnknown(
          data['local_record_key']!,
          _localRecordKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      httpMethod: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}http_method'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_id'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextRetryAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_retry_at'],
      ),
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      responseJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}response_json'],
      ),
      localRecordKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_record_key'],
      ),
    );
  }

  @override
  $PendingOperationsTable createAlias(String alias) {
    return $PendingOperationsTable(attachedDatabase, alias);
  }
}

class PendingOperation extends DataClass
    implements Insertable<PendingOperation> {
  final int id;
  final String operationType;
  final String endpoint;
  final String httpMethod;
  final int userId;
  final String idempotencyKey;
  final String payloadJson;
  final DateTime createdAt;
  final String status;
  final int attemptCount;
  final DateTime? nextRetryAt;
  final String? lastError;
  final String? responseJson;
  final String? localRecordKey;
  const PendingOperation({
    required this.id,
    required this.operationType,
    required this.endpoint,
    required this.httpMethod,
    required this.userId,
    required this.idempotencyKey,
    required this.payloadJson,
    required this.createdAt,
    required this.status,
    required this.attemptCount,
    this.nextRetryAt,
    this.lastError,
    this.responseJson,
    this.localRecordKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['endpoint'] = Variable<String>(endpoint);
    map['http_method'] = Variable<String>(httpMethod);
    map['user_id'] = Variable<int>(userId);
    map['idempotency_key'] = Variable<String>(idempotencyKey);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['status'] = Variable<String>(status);
    map['attempt_count'] = Variable<int>(attemptCount);
    if (!nullToAbsent || nextRetryAt != null) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt);
    }
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    if (!nullToAbsent || responseJson != null) {
      map['response_json'] = Variable<String>(responseJson);
    }
    if (!nullToAbsent || localRecordKey != null) {
      map['local_record_key'] = Variable<String>(localRecordKey);
    }
    return map;
  }

  PendingOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingOperationsCompanion(
      id: Value(id),
      operationType: Value(operationType),
      endpoint: Value(endpoint),
      httpMethod: Value(httpMethod),
      userId: Value(userId),
      idempotencyKey: Value(idempotencyKey),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      status: Value(status),
      attemptCount: Value(attemptCount),
      nextRetryAt: nextRetryAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextRetryAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      responseJson: responseJson == null && nullToAbsent
          ? const Value.absent()
          : Value(responseJson),
      localRecordKey: localRecordKey == null && nullToAbsent
          ? const Value.absent()
          : Value(localRecordKey),
    );
  }

  factory PendingOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingOperation(
      id: serializer.fromJson<int>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      httpMethod: serializer.fromJson<String>(json['httpMethod']),
      userId: serializer.fromJson<int>(json['userId']),
      idempotencyKey: serializer.fromJson<String>(json['idempotencyKey']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      status: serializer.fromJson<String>(json['status']),
      attemptCount: serializer.fromJson<int>(json['attemptCount']),
      nextRetryAt: serializer.fromJson<DateTime?>(json['nextRetryAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      responseJson: serializer.fromJson<String?>(json['responseJson']),
      localRecordKey: serializer.fromJson<String?>(json['localRecordKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'operationType': serializer.toJson<String>(operationType),
      'endpoint': serializer.toJson<String>(endpoint),
      'httpMethod': serializer.toJson<String>(httpMethod),
      'userId': serializer.toJson<int>(userId),
      'idempotencyKey': serializer.toJson<String>(idempotencyKey),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'status': serializer.toJson<String>(status),
      'attemptCount': serializer.toJson<int>(attemptCount),
      'nextRetryAt': serializer.toJson<DateTime?>(nextRetryAt),
      'lastError': serializer.toJson<String?>(lastError),
      'responseJson': serializer.toJson<String?>(responseJson),
      'localRecordKey': serializer.toJson<String?>(localRecordKey),
    };
  }

  PendingOperation copyWith({
    int? id,
    String? operationType,
    String? endpoint,
    String? httpMethod,
    int? userId,
    String? idempotencyKey,
    String? payloadJson,
    DateTime? createdAt,
    String? status,
    int? attemptCount,
    Value<DateTime?> nextRetryAt = const Value.absent(),
    Value<String?> lastError = const Value.absent(),
    Value<String?> responseJson = const Value.absent(),
    Value<String?> localRecordKey = const Value.absent(),
  }) => PendingOperation(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    endpoint: endpoint ?? this.endpoint,
    httpMethod: httpMethod ?? this.httpMethod,
    userId: userId ?? this.userId,
    idempotencyKey: idempotencyKey ?? this.idempotencyKey,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    status: status ?? this.status,
    attemptCount: attemptCount ?? this.attemptCount,
    nextRetryAt: nextRetryAt.present ? nextRetryAt.value : this.nextRetryAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    responseJson: responseJson.present ? responseJson.value : this.responseJson,
    localRecordKey: localRecordKey.present
        ? localRecordKey.value
        : this.localRecordKey,
  );
  PendingOperation copyWithCompanion(PendingOperationsCompanion data) {
    return PendingOperation(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      httpMethod: data.httpMethod.present
          ? data.httpMethod.value
          : this.httpMethod,
      userId: data.userId.present ? data.userId.value : this.userId,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      status: data.status.present ? data.status.value : this.status,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextRetryAt: data.nextRetryAt.present
          ? data.nextRetryAt.value
          : this.nextRetryAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      responseJson: data.responseJson.present
          ? data.responseJson.value
          : this.responseJson,
      localRecordKey: data.localRecordKey.present
          ? data.localRecordKey.value
          : this.localRecordKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperation(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('userId: $userId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('responseJson: $responseJson, ')
          ..write('localRecordKey: $localRecordKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    endpoint,
    httpMethod,
    userId,
    idempotencyKey,
    payloadJson,
    createdAt,
    status,
    attemptCount,
    nextRetryAt,
    lastError,
    responseJson,
    localRecordKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingOperation &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.endpoint == this.endpoint &&
          other.httpMethod == this.httpMethod &&
          other.userId == this.userId &&
          other.idempotencyKey == this.idempotencyKey &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.status == this.status &&
          other.attemptCount == this.attemptCount &&
          other.nextRetryAt == this.nextRetryAt &&
          other.lastError == this.lastError &&
          other.responseJson == this.responseJson &&
          other.localRecordKey == this.localRecordKey);
}

class PendingOperationsCompanion extends UpdateCompanion<PendingOperation> {
  final Value<int> id;
  final Value<String> operationType;
  final Value<String> endpoint;
  final Value<String> httpMethod;
  final Value<int> userId;
  final Value<String> idempotencyKey;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<String> status;
  final Value<int> attemptCount;
  final Value<DateTime?> nextRetryAt;
  final Value<String?> lastError;
  final Value<String?> responseJson;
  final Value<String?> localRecordKey;
  const PendingOperationsCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.httpMethod = const Value.absent(),
    this.userId = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.localRecordKey = const Value.absent(),
  });
  PendingOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String operationType,
    required String endpoint,
    required String httpMethod,
    required int userId,
    required String idempotencyKey,
    required String payloadJson,
    required DateTime createdAt,
    this.status = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextRetryAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.responseJson = const Value.absent(),
    this.localRecordKey = const Value.absent(),
  }) : operationType = Value(operationType),
       endpoint = Value(endpoint),
       httpMethod = Value(httpMethod),
       userId = Value(userId),
       idempotencyKey = Value(idempotencyKey),
       payloadJson = Value(payloadJson),
       createdAt = Value(createdAt);
  static Insertable<PendingOperation> custom({
    Expression<int>? id,
    Expression<String>? operationType,
    Expression<String>? endpoint,
    Expression<String>? httpMethod,
    Expression<int>? userId,
    Expression<String>? idempotencyKey,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<String>? status,
    Expression<int>? attemptCount,
    Expression<DateTime>? nextRetryAt,
    Expression<String>? lastError,
    Expression<String>? responseJson,
    Expression<String>? localRecordKey,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (endpoint != null) 'endpoint': endpoint,
      if (httpMethod != null) 'http_method': httpMethod,
      if (userId != null) 'user_id': userId,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (status != null) 'status': status,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextRetryAt != null) 'next_retry_at': nextRetryAt,
      if (lastError != null) 'last_error': lastError,
      if (responseJson != null) 'response_json': responseJson,
      if (localRecordKey != null) 'local_record_key': localRecordKey,
    });
  }

  PendingOperationsCompanion copyWith({
    Value<int>? id,
    Value<String>? operationType,
    Value<String>? endpoint,
    Value<String>? httpMethod,
    Value<int>? userId,
    Value<String>? idempotencyKey,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<String>? status,
    Value<int>? attemptCount,
    Value<DateTime?>? nextRetryAt,
    Value<String?>? lastError,
    Value<String?>? responseJson,
    Value<String?>? localRecordKey,
  }) {
    return PendingOperationsCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      endpoint: endpoint ?? this.endpoint,
      httpMethod: httpMethod ?? this.httpMethod,
      userId: userId ?? this.userId,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      attemptCount: attemptCount ?? this.attemptCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      lastError: lastError ?? this.lastError,
      responseJson: responseJson ?? this.responseJson,
      localRecordKey: localRecordKey ?? this.localRecordKey,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (httpMethod.present) {
      map['http_method'] = Variable<String>(httpMethod.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<int>(userId.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextRetryAt.present) {
      map['next_retry_at'] = Variable<DateTime>(nextRetryAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (responseJson.present) {
      map['response_json'] = Variable<String>(responseJson.value);
    }
    if (localRecordKey.present) {
      map['local_record_key'] = Variable<String>(localRecordKey.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingOperationsCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('endpoint: $endpoint, ')
          ..write('httpMethod: $httpMethod, ')
          ..write('userId: $userId, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('status: $status, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextRetryAt: $nextRetryAt, ')
          ..write('lastError: $lastError, ')
          ..write('responseJson: $responseJson, ')
          ..write('localRecordKey: $localRecordKey')
          ..write(')'))
        .toString();
  }
}

class $CachedSalesTable extends CachedSales
    with TableInfo<$CachedSalesTable, CachedSale> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSalesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localKeyMeta = const VerificationMeta(
    'localKey',
  );
  @override
  late final GeneratedColumn<String> localKey = GeneratedColumn<String>(
    'local_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_sales';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSale> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_key')) {
      context.handle(
        _localKeyMeta,
        localKey.isAcceptableOrUnknown(data['local_key']!, _localKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_localKeyMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localKey};
  @override
  CachedSale map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSale(
      localKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_key'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
    );
  }

  @override
  $CachedSalesTable createAlias(String alias) {
    return $CachedSalesTable(attachedDatabase, alias);
  }
}

class CachedSale extends DataClass implements Insertable<CachedSale> {
  final String localKey;
  final int? serverId;
  final String payloadJson;
  final DateTime? serverUpdatedAt;
  final DateTime localUpdatedAt;
  final String syncState;
  final String? idempotencyKey;
  const CachedSale({
    required this.localKey,
    this.serverId,
    required this.payloadJson,
    this.serverUpdatedAt,
    required this.localUpdatedAt,
    required this.syncState,
    this.idempotencyKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_key'] = Variable<String>(localKey);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    return map;
  }

  CachedSalesCompanion toCompanion(bool nullToAbsent) {
    return CachedSalesCompanion(
      localKey: Value(localKey),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payloadJson: Value(payloadJson),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      syncState: Value(syncState),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
    );
  }

  factory CachedSale.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSale(
      localKey: serializer.fromJson<String>(json['localKey']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localKey': serializer.toJson<String>(localKey),
      'serverId': serializer.toJson<int?>(serverId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'syncState': serializer.toJson<String>(syncState),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
    };
  }

  CachedSale copyWith({
    String? localKey,
    Value<int?> serverId = const Value.absent(),
    String? payloadJson,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? localUpdatedAt,
    String? syncState,
    Value<String?> idempotencyKey = const Value.absent(),
  }) => CachedSale(
    localKey: localKey ?? this.localKey,
    serverId: serverId.present ? serverId.value : this.serverId,
    payloadJson: payloadJson ?? this.payloadJson,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    syncState: syncState ?? this.syncState,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
  );
  CachedSale copyWithCompanion(CachedSalesCompanion data) {
    return CachedSale(
      localKey: data.localKey.present ? data.localKey.value : this.localKey,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSale(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSale &&
          other.localKey == this.localKey &&
          other.serverId == this.serverId &&
          other.payloadJson == this.payloadJson &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.syncState == this.syncState &&
          other.idempotencyKey == this.idempotencyKey);
}

class CachedSalesCompanion extends UpdateCompanion<CachedSale> {
  final Value<String> localKey;
  final Value<int?> serverId;
  final Value<String> payloadJson;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<String> syncState;
  final Value<String?> idempotencyKey;
  final Value<int> rowid;
  const CachedSalesCompanion({
    this.localKey = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSalesCompanion.insert({
    required String localKey,
    this.serverId = const Value.absent(),
    required String payloadJson,
    this.serverUpdatedAt = const Value.absent(),
    required DateTime localUpdatedAt,
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localKey = Value(localKey),
       payloadJson = Value(payloadJson),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<CachedSale> custom({
    Expression<String>? localKey,
    Expression<int>? serverId,
    Expression<String>? payloadJson,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<String>? syncState,
    Expression<String>? idempotencyKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localKey != null) 'local_key': localKey,
      if (serverId != null) 'server_id': serverId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSalesCompanion copyWith({
    Value<String>? localKey,
    Value<int?>? serverId,
    Value<String>? payloadJson,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? localUpdatedAt,
    Value<String>? syncState,
    Value<String?>? idempotencyKey,
    Value<int>? rowid,
  }) {
    return CachedSalesCompanion(
      localKey: localKey ?? this.localKey,
      serverId: serverId ?? this.serverId,
      payloadJson: payloadJson ?? this.payloadJson,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncState: syncState ?? this.syncState,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localKey.present) {
      map['local_key'] = Variable<String>(localKey.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSalesCompanion(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedExpensesTable extends CachedExpenses
    with TableInfo<$CachedExpensesTable, CachedExpense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localKeyMeta = const VerificationMeta(
    'localKey',
  );
  @override
  late final GeneratedColumn<String> localKey = GeneratedColumn<String>(
    'local_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedExpense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_key')) {
      context.handle(
        _localKeyMeta,
        localKey.isAcceptableOrUnknown(data['local_key']!, _localKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_localKeyMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localKey};
  @override
  CachedExpense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedExpense(
      localKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_key'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
    );
  }

  @override
  $CachedExpensesTable createAlias(String alias) {
    return $CachedExpensesTable(attachedDatabase, alias);
  }
}

class CachedExpense extends DataClass implements Insertable<CachedExpense> {
  final String localKey;
  final int? serverId;
  final String payloadJson;
  final DateTime? serverUpdatedAt;
  final DateTime localUpdatedAt;
  final String syncState;
  final String? idempotencyKey;
  const CachedExpense({
    required this.localKey,
    this.serverId,
    required this.payloadJson,
    this.serverUpdatedAt,
    required this.localUpdatedAt,
    required this.syncState,
    this.idempotencyKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_key'] = Variable<String>(localKey);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    return map;
  }

  CachedExpensesCompanion toCompanion(bool nullToAbsent) {
    return CachedExpensesCompanion(
      localKey: Value(localKey),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payloadJson: Value(payloadJson),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      syncState: Value(syncState),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
    );
  }

  factory CachedExpense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedExpense(
      localKey: serializer.fromJson<String>(json['localKey']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localKey': serializer.toJson<String>(localKey),
      'serverId': serializer.toJson<int?>(serverId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'syncState': serializer.toJson<String>(syncState),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
    };
  }

  CachedExpense copyWith({
    String? localKey,
    Value<int?> serverId = const Value.absent(),
    String? payloadJson,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? localUpdatedAt,
    String? syncState,
    Value<String?> idempotencyKey = const Value.absent(),
  }) => CachedExpense(
    localKey: localKey ?? this.localKey,
    serverId: serverId.present ? serverId.value : this.serverId,
    payloadJson: payloadJson ?? this.payloadJson,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    syncState: syncState ?? this.syncState,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
  );
  CachedExpense copyWithCompanion(CachedExpensesCompanion data) {
    return CachedExpense(
      localKey: data.localKey.present ? data.localKey.value : this.localKey,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedExpense(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedExpense &&
          other.localKey == this.localKey &&
          other.serverId == this.serverId &&
          other.payloadJson == this.payloadJson &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.syncState == this.syncState &&
          other.idempotencyKey == this.idempotencyKey);
}

class CachedExpensesCompanion extends UpdateCompanion<CachedExpense> {
  final Value<String> localKey;
  final Value<int?> serverId;
  final Value<String> payloadJson;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<String> syncState;
  final Value<String?> idempotencyKey;
  final Value<int> rowid;
  const CachedExpensesCompanion({
    this.localKey = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedExpensesCompanion.insert({
    required String localKey,
    this.serverId = const Value.absent(),
    required String payloadJson,
    this.serverUpdatedAt = const Value.absent(),
    required DateTime localUpdatedAt,
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localKey = Value(localKey),
       payloadJson = Value(payloadJson),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<CachedExpense> custom({
    Expression<String>? localKey,
    Expression<int>? serverId,
    Expression<String>? payloadJson,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<String>? syncState,
    Expression<String>? idempotencyKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localKey != null) 'local_key': localKey,
      if (serverId != null) 'server_id': serverId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedExpensesCompanion copyWith({
    Value<String>? localKey,
    Value<int?>? serverId,
    Value<String>? payloadJson,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? localUpdatedAt,
    Value<String>? syncState,
    Value<String?>? idempotencyKey,
    Value<int>? rowid,
  }) {
    return CachedExpensesCompanion(
      localKey: localKey ?? this.localKey,
      serverId: serverId ?? this.serverId,
      payloadJson: payloadJson ?? this.payloadJson,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncState: syncState ?? this.syncState,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localKey.present) {
      map['local_key'] = Variable<String>(localKey.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedExpensesCompanion(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedPurchasesTable extends CachedPurchases
    with TableInfo<$CachedPurchasesTable, CachedPurchase> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedPurchasesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localKeyMeta = const VerificationMeta(
    'localKey',
  );
  @override
  late final GeneratedColumn<String> localKey = GeneratedColumn<String>(
    'local_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_purchases';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedPurchase> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_key')) {
      context.handle(
        _localKeyMeta,
        localKey.isAcceptableOrUnknown(data['local_key']!, _localKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_localKeyMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localKey};
  @override
  CachedPurchase map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedPurchase(
      localKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_key'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
    );
  }

  @override
  $CachedPurchasesTable createAlias(String alias) {
    return $CachedPurchasesTable(attachedDatabase, alias);
  }
}

class CachedPurchase extends DataClass implements Insertable<CachedPurchase> {
  final String localKey;
  final int? serverId;
  final String payloadJson;
  final DateTime? serverUpdatedAt;
  final DateTime localUpdatedAt;
  final String syncState;
  final String? idempotencyKey;
  const CachedPurchase({
    required this.localKey,
    this.serverId,
    required this.payloadJson,
    this.serverUpdatedAt,
    required this.localUpdatedAt,
    required this.syncState,
    this.idempotencyKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_key'] = Variable<String>(localKey);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    return map;
  }

  CachedPurchasesCompanion toCompanion(bool nullToAbsent) {
    return CachedPurchasesCompanion(
      localKey: Value(localKey),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payloadJson: Value(payloadJson),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      syncState: Value(syncState),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
    );
  }

  factory CachedPurchase.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedPurchase(
      localKey: serializer.fromJson<String>(json['localKey']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localKey': serializer.toJson<String>(localKey),
      'serverId': serializer.toJson<int?>(serverId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'syncState': serializer.toJson<String>(syncState),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
    };
  }

  CachedPurchase copyWith({
    String? localKey,
    Value<int?> serverId = const Value.absent(),
    String? payloadJson,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? localUpdatedAt,
    String? syncState,
    Value<String?> idempotencyKey = const Value.absent(),
  }) => CachedPurchase(
    localKey: localKey ?? this.localKey,
    serverId: serverId.present ? serverId.value : this.serverId,
    payloadJson: payloadJson ?? this.payloadJson,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    syncState: syncState ?? this.syncState,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
  );
  CachedPurchase copyWithCompanion(CachedPurchasesCompanion data) {
    return CachedPurchase(
      localKey: data.localKey.present ? data.localKey.value : this.localKey,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedPurchase(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedPurchase &&
          other.localKey == this.localKey &&
          other.serverId == this.serverId &&
          other.payloadJson == this.payloadJson &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.syncState == this.syncState &&
          other.idempotencyKey == this.idempotencyKey);
}

class CachedPurchasesCompanion extends UpdateCompanion<CachedPurchase> {
  final Value<String> localKey;
  final Value<int?> serverId;
  final Value<String> payloadJson;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<String> syncState;
  final Value<String?> idempotencyKey;
  final Value<int> rowid;
  const CachedPurchasesCompanion({
    this.localKey = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedPurchasesCompanion.insert({
    required String localKey,
    this.serverId = const Value.absent(),
    required String payloadJson,
    this.serverUpdatedAt = const Value.absent(),
    required DateTime localUpdatedAt,
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localKey = Value(localKey),
       payloadJson = Value(payloadJson),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<CachedPurchase> custom({
    Expression<String>? localKey,
    Expression<int>? serverId,
    Expression<String>? payloadJson,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<String>? syncState,
    Expression<String>? idempotencyKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localKey != null) 'local_key': localKey,
      if (serverId != null) 'server_id': serverId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedPurchasesCompanion copyWith({
    Value<String>? localKey,
    Value<int?>? serverId,
    Value<String>? payloadJson,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? localUpdatedAt,
    Value<String>? syncState,
    Value<String?>? idempotencyKey,
    Value<int>? rowid,
  }) {
    return CachedPurchasesCompanion(
      localKey: localKey ?? this.localKey,
      serverId: serverId ?? this.serverId,
      payloadJson: payloadJson ?? this.payloadJson,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncState: syncState ?? this.syncState,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localKey.present) {
      map['local_key'] = Variable<String>(localKey.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedPurchasesCompanion(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMovementsTable extends CachedMovements
    with TableInfo<$CachedMovementsTable, CachedMovement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMovementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _localKeyMeta = const VerificationMeta(
    'localKey',
  );
  @override
  late final GeneratedColumn<String> localKey = GeneratedColumn<String>(
    'local_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverIdMeta = const VerificationMeta(
    'serverId',
  );
  @override
  late final GeneratedColumn<int> serverId = GeneratedColumn<int>(
    'server_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _serverUpdatedAtMeta = const VerificationMeta(
    'serverUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> serverUpdatedAt =
      GeneratedColumn<DateTime>(
        'server_updated_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _localUpdatedAtMeta = const VerificationMeta(
    'localUpdatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localUpdatedAt =
      GeneratedColumn<DateTime>(
        'local_updated_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncStateMeta = const VerificationMeta(
    'syncState',
  );
  @override
  late final GeneratedColumn<String> syncState = GeneratedColumn<String>(
    'sync_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _idempotencyKeyMeta = const VerificationMeta(
    'idempotencyKey',
  );
  @override
  late final GeneratedColumn<String> idempotencyKey = GeneratedColumn<String>(
    'idempotency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_movements';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedMovement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('local_key')) {
      context.handle(
        _localKeyMeta,
        localKey.isAcceptableOrUnknown(data['local_key']!, _localKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_localKeyMeta);
    }
    if (data.containsKey('server_id')) {
      context.handle(
        _serverIdMeta,
        serverId.isAcceptableOrUnknown(data['server_id']!, _serverIdMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('server_updated_at')) {
      context.handle(
        _serverUpdatedAtMeta,
        serverUpdatedAt.isAcceptableOrUnknown(
          data['server_updated_at']!,
          _serverUpdatedAtMeta,
        ),
      );
    }
    if (data.containsKey('local_updated_at')) {
      context.handle(
        _localUpdatedAtMeta,
        localUpdatedAt.isAcceptableOrUnknown(
          data['local_updated_at']!,
          _localUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localUpdatedAtMeta);
    }
    if (data.containsKey('sync_state')) {
      context.handle(
        _syncStateMeta,
        syncState.isAcceptableOrUnknown(data['sync_state']!, _syncStateMeta),
      );
    }
    if (data.containsKey('idempotency_key')) {
      context.handle(
        _idempotencyKeyMeta,
        idempotencyKey.isAcceptableOrUnknown(
          data['idempotency_key']!,
          _idempotencyKeyMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {localKey};
  @override
  CachedMovement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMovement(
      localKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_key'],
      )!,
      serverId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}server_id'],
      ),
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      serverUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}server_updated_at'],
      ),
      localUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_updated_at'],
      )!,
      syncState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_state'],
      )!,
      idempotencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}idempotency_key'],
      ),
    );
  }

  @override
  $CachedMovementsTable createAlias(String alias) {
    return $CachedMovementsTable(attachedDatabase, alias);
  }
}

class CachedMovement extends DataClass implements Insertable<CachedMovement> {
  final String localKey;
  final int? serverId;
  final String payloadJson;
  final DateTime? serverUpdatedAt;
  final DateTime localUpdatedAt;
  final String syncState;
  final String? idempotencyKey;
  const CachedMovement({
    required this.localKey,
    this.serverId,
    required this.payloadJson,
    this.serverUpdatedAt,
    required this.localUpdatedAt,
    required this.syncState,
    this.idempotencyKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['local_key'] = Variable<String>(localKey);
    if (!nullToAbsent || serverId != null) {
      map['server_id'] = Variable<int>(serverId);
    }
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || serverUpdatedAt != null) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt);
    }
    map['local_updated_at'] = Variable<DateTime>(localUpdatedAt);
    map['sync_state'] = Variable<String>(syncState);
    if (!nullToAbsent || idempotencyKey != null) {
      map['idempotency_key'] = Variable<String>(idempotencyKey);
    }
    return map;
  }

  CachedMovementsCompanion toCompanion(bool nullToAbsent) {
    return CachedMovementsCompanion(
      localKey: Value(localKey),
      serverId: serverId == null && nullToAbsent
          ? const Value.absent()
          : Value(serverId),
      payloadJson: Value(payloadJson),
      serverUpdatedAt: serverUpdatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(serverUpdatedAt),
      localUpdatedAt: Value(localUpdatedAt),
      syncState: Value(syncState),
      idempotencyKey: idempotencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(idempotencyKey),
    );
  }

  factory CachedMovement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMovement(
      localKey: serializer.fromJson<String>(json['localKey']),
      serverId: serializer.fromJson<int?>(json['serverId']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      serverUpdatedAt: serializer.fromJson<DateTime?>(json['serverUpdatedAt']),
      localUpdatedAt: serializer.fromJson<DateTime>(json['localUpdatedAt']),
      syncState: serializer.fromJson<String>(json['syncState']),
      idempotencyKey: serializer.fromJson<String?>(json['idempotencyKey']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'localKey': serializer.toJson<String>(localKey),
      'serverId': serializer.toJson<int?>(serverId),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'serverUpdatedAt': serializer.toJson<DateTime?>(serverUpdatedAt),
      'localUpdatedAt': serializer.toJson<DateTime>(localUpdatedAt),
      'syncState': serializer.toJson<String>(syncState),
      'idempotencyKey': serializer.toJson<String?>(idempotencyKey),
    };
  }

  CachedMovement copyWith({
    String? localKey,
    Value<int?> serverId = const Value.absent(),
    String? payloadJson,
    Value<DateTime?> serverUpdatedAt = const Value.absent(),
    DateTime? localUpdatedAt,
    String? syncState,
    Value<String?> idempotencyKey = const Value.absent(),
  }) => CachedMovement(
    localKey: localKey ?? this.localKey,
    serverId: serverId.present ? serverId.value : this.serverId,
    payloadJson: payloadJson ?? this.payloadJson,
    serverUpdatedAt: serverUpdatedAt.present
        ? serverUpdatedAt.value
        : this.serverUpdatedAt,
    localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
    syncState: syncState ?? this.syncState,
    idempotencyKey: idempotencyKey.present
        ? idempotencyKey.value
        : this.idempotencyKey,
  );
  CachedMovement copyWithCompanion(CachedMovementsCompanion data) {
    return CachedMovement(
      localKey: data.localKey.present ? data.localKey.value : this.localKey,
      serverId: data.serverId.present ? data.serverId.value : this.serverId,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      serverUpdatedAt: data.serverUpdatedAt.present
          ? data.serverUpdatedAt.value
          : this.serverUpdatedAt,
      localUpdatedAt: data.localUpdatedAt.present
          ? data.localUpdatedAt.value
          : this.localUpdatedAt,
      syncState: data.syncState.present ? data.syncState.value : this.syncState,
      idempotencyKey: data.idempotencyKey.present
          ? data.idempotencyKey.value
          : this.idempotencyKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMovement(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    localKey,
    serverId,
    payloadJson,
    serverUpdatedAt,
    localUpdatedAt,
    syncState,
    idempotencyKey,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMovement &&
          other.localKey == this.localKey &&
          other.serverId == this.serverId &&
          other.payloadJson == this.payloadJson &&
          other.serverUpdatedAt == this.serverUpdatedAt &&
          other.localUpdatedAt == this.localUpdatedAt &&
          other.syncState == this.syncState &&
          other.idempotencyKey == this.idempotencyKey);
}

class CachedMovementsCompanion extends UpdateCompanion<CachedMovement> {
  final Value<String> localKey;
  final Value<int?> serverId;
  final Value<String> payloadJson;
  final Value<DateTime?> serverUpdatedAt;
  final Value<DateTime> localUpdatedAt;
  final Value<String> syncState;
  final Value<String?> idempotencyKey;
  final Value<int> rowid;
  const CachedMovementsCompanion({
    this.localKey = const Value.absent(),
    this.serverId = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.serverUpdatedAt = const Value.absent(),
    this.localUpdatedAt = const Value.absent(),
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMovementsCompanion.insert({
    required String localKey,
    this.serverId = const Value.absent(),
    required String payloadJson,
    this.serverUpdatedAt = const Value.absent(),
    required DateTime localUpdatedAt,
    this.syncState = const Value.absent(),
    this.idempotencyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : localKey = Value(localKey),
       payloadJson = Value(payloadJson),
       localUpdatedAt = Value(localUpdatedAt);
  static Insertable<CachedMovement> custom({
    Expression<String>? localKey,
    Expression<int>? serverId,
    Expression<String>? payloadJson,
    Expression<DateTime>? serverUpdatedAt,
    Expression<DateTime>? localUpdatedAt,
    Expression<String>? syncState,
    Expression<String>? idempotencyKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (localKey != null) 'local_key': localKey,
      if (serverId != null) 'server_id': serverId,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (serverUpdatedAt != null) 'server_updated_at': serverUpdatedAt,
      if (localUpdatedAt != null) 'local_updated_at': localUpdatedAt,
      if (syncState != null) 'sync_state': syncState,
      if (idempotencyKey != null) 'idempotency_key': idempotencyKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMovementsCompanion copyWith({
    Value<String>? localKey,
    Value<int?>? serverId,
    Value<String>? payloadJson,
    Value<DateTime?>? serverUpdatedAt,
    Value<DateTime>? localUpdatedAt,
    Value<String>? syncState,
    Value<String?>? idempotencyKey,
    Value<int>? rowid,
  }) {
    return CachedMovementsCompanion(
      localKey: localKey ?? this.localKey,
      serverId: serverId ?? this.serverId,
      payloadJson: payloadJson ?? this.payloadJson,
      serverUpdatedAt: serverUpdatedAt ?? this.serverUpdatedAt,
      localUpdatedAt: localUpdatedAt ?? this.localUpdatedAt,
      syncState: syncState ?? this.syncState,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (localKey.present) {
      map['local_key'] = Variable<String>(localKey.value);
    }
    if (serverId.present) {
      map['server_id'] = Variable<int>(serverId.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (serverUpdatedAt.present) {
      map['server_updated_at'] = Variable<DateTime>(serverUpdatedAt.value);
    }
    if (localUpdatedAt.present) {
      map['local_updated_at'] = Variable<DateTime>(localUpdatedAt.value);
    }
    if (syncState.present) {
      map['sync_state'] = Variable<String>(syncState.value);
    }
    if (idempotencyKey.present) {
      map['idempotency_key'] = Variable<String>(idempotencyKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMovementsCompanion(')
          ..write('localKey: $localKey, ')
          ..write('serverId: $serverId, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('serverUpdatedAt: $serverUpdatedAt, ')
          ..write('localUpdatedAt: $localUpdatedAt, ')
          ..write('syncState: $syncState, ')
          ..write('idempotencyKey: $idempotencyKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PendingOperationsTable pendingOperations =
      $PendingOperationsTable(this);
  late final $CachedSalesTable cachedSales = $CachedSalesTable(this);
  late final $CachedExpensesTable cachedExpenses = $CachedExpensesTable(this);
  late final $CachedPurchasesTable cachedPurchases = $CachedPurchasesTable(
    this,
  );
  late final $CachedMovementsTable cachedMovements = $CachedMovementsTable(
    this,
  );
  late final Index pendingUserStatusCreated = Index(
    'pending_user_status_created',
    'CREATE INDEX pending_user_status_created ON pending_operations (user_id, status, created_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    pendingOperations,
    cachedSales,
    cachedExpenses,
    cachedPurchases,
    cachedMovements,
    pendingUserStatusCreated,
  ];
}

typedef $$PendingOperationsTableCreateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      required String operationType,
      required String endpoint,
      required String httpMethod,
      required int userId,
      required String idempotencyKey,
      required String payloadJson,
      required DateTime createdAt,
      Value<String> status,
      Value<int> attemptCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> responseJson,
      Value<String?> localRecordKey,
    });
typedef $$PendingOperationsTableUpdateCompanionBuilder =
    PendingOperationsCompanion Function({
      Value<int> id,
      Value<String> operationType,
      Value<String> endpoint,
      Value<String> httpMethod,
      Value<int> userId,
      Value<String> idempotencyKey,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<String> status,
      Value<int> attemptCount,
      Value<DateTime?> nextRetryAt,
      Value<String?> lastError,
      Value<String?> responseJson,
      Value<String?> localRecordKey,
    });

class $$PendingOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localRecordKey => $composableBuilder(
    column: $table.localRecordKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PendingOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localRecordKey => $composableBuilder(
    column: $table.localRecordKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PendingOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingOperationsTable> {
  $$PendingOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get httpMethod => $composableBuilder(
    column: $table.httpMethod,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get attemptCount => $composableBuilder(
    column: $table.attemptCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get nextRetryAt => $composableBuilder(
    column: $table.nextRetryAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<String> get responseJson => $composableBuilder(
    column: $table.responseJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get localRecordKey => $composableBuilder(
    column: $table.localRecordKey,
    builder: (column) => column,
  );
}

class $$PendingOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation,
          $$PendingOperationsTableFilterComposer,
          $$PendingOperationsTableOrderingComposer,
          $$PendingOperationsTableAnnotationComposer,
          $$PendingOperationsTableCreateCompanionBuilder,
          $$PendingOperationsTableUpdateCompanionBuilder,
          (
            PendingOperation,
            BaseReferences<
              _$AppDatabase,
              $PendingOperationsTable,
              PendingOperation
            >,
          ),
          PendingOperation,
          PrefetchHooks Function()
        > {
  $$PendingOperationsTableTableManager(
    _$AppDatabase db,
    $PendingOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingOperationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> httpMethod = const Value.absent(),
                Value<int> userId = const Value.absent(),
                Value<String> idempotencyKey = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> responseJson = const Value.absent(),
                Value<String?> localRecordKey = const Value.absent(),
              }) => PendingOperationsCompanion(
                id: id,
                operationType: operationType,
                endpoint: endpoint,
                httpMethod: httpMethod,
                userId: userId,
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                createdAt: createdAt,
                status: status,
                attemptCount: attemptCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                responseJson: responseJson,
                localRecordKey: localRecordKey,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String operationType,
                required String endpoint,
                required String httpMethod,
                required int userId,
                required String idempotencyKey,
                required String payloadJson,
                required DateTime createdAt,
                Value<String> status = const Value.absent(),
                Value<int> attemptCount = const Value.absent(),
                Value<DateTime?> nextRetryAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<String?> responseJson = const Value.absent(),
                Value<String?> localRecordKey = const Value.absent(),
              }) => PendingOperationsCompanion.insert(
                id: id,
                operationType: operationType,
                endpoint: endpoint,
                httpMethod: httpMethod,
                userId: userId,
                idempotencyKey: idempotencyKey,
                payloadJson: payloadJson,
                createdAt: createdAt,
                status: status,
                attemptCount: attemptCount,
                nextRetryAt: nextRetryAt,
                lastError: lastError,
                responseJson: responseJson,
                localRecordKey: localRecordKey,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PendingOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PendingOperationsTable,
      PendingOperation,
      $$PendingOperationsTableFilterComposer,
      $$PendingOperationsTableOrderingComposer,
      $$PendingOperationsTableAnnotationComposer,
      $$PendingOperationsTableCreateCompanionBuilder,
      $$PendingOperationsTableUpdateCompanionBuilder,
      (
        PendingOperation,
        BaseReferences<
          _$AppDatabase,
          $PendingOperationsTable,
          PendingOperation
        >,
      ),
      PendingOperation,
      PrefetchHooks Function()
    >;
typedef $$CachedSalesTableCreateCompanionBuilder =
    CachedSalesCompanion Function({
      required String localKey,
      Value<int?> serverId,
      required String payloadJson,
      Value<DateTime?> serverUpdatedAt,
      required DateTime localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });
typedef $$CachedSalesTableUpdateCompanionBuilder =
    CachedSalesCompanion Function({
      Value<String> localKey,
      Value<int?> serverId,
      Value<String> payloadJson,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });

class $$CachedSalesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSalesTable> {
  $$CachedSalesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedSalesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSalesTable> {
  $$CachedSalesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedSalesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSalesTable> {
  $$CachedSalesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localKey =>
      $composableBuilder(column: $table.localKey, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );
}

class $$CachedSalesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedSalesTable,
          CachedSale,
          $$CachedSalesTableFilterComposer,
          $$CachedSalesTableOrderingComposer,
          $$CachedSalesTableAnnotationComposer,
          $$CachedSalesTableCreateCompanionBuilder,
          $$CachedSalesTableUpdateCompanionBuilder,
          (
            CachedSale,
            BaseReferences<_$AppDatabase, $CachedSalesTable, CachedSale>,
          ),
          CachedSale,
          PrefetchHooks Function()
        > {
  $$CachedSalesTableTableManager(_$AppDatabase db, $CachedSalesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSalesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSalesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSalesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localKey = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSalesCompanion(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localKey,
                Value<int?> serverId = const Value.absent(),
                required String payloadJson,
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSalesCompanion.insert(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSalesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedSalesTable,
      CachedSale,
      $$CachedSalesTableFilterComposer,
      $$CachedSalesTableOrderingComposer,
      $$CachedSalesTableAnnotationComposer,
      $$CachedSalesTableCreateCompanionBuilder,
      $$CachedSalesTableUpdateCompanionBuilder,
      (
        CachedSale,
        BaseReferences<_$AppDatabase, $CachedSalesTable, CachedSale>,
      ),
      CachedSale,
      PrefetchHooks Function()
    >;
typedef $$CachedExpensesTableCreateCompanionBuilder =
    CachedExpensesCompanion Function({
      required String localKey,
      Value<int?> serverId,
      required String payloadJson,
      Value<DateTime?> serverUpdatedAt,
      required DateTime localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });
typedef $$CachedExpensesTableUpdateCompanionBuilder =
    CachedExpensesCompanion Function({
      Value<String> localKey,
      Value<int?> serverId,
      Value<String> payloadJson,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });

class $$CachedExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedExpensesTable> {
  $$CachedExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedExpensesTable> {
  $$CachedExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedExpensesTable> {
  $$CachedExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localKey =>
      $composableBuilder(column: $table.localKey, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );
}

class $$CachedExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedExpensesTable,
          CachedExpense,
          $$CachedExpensesTableFilterComposer,
          $$CachedExpensesTableOrderingComposer,
          $$CachedExpensesTableAnnotationComposer,
          $$CachedExpensesTableCreateCompanionBuilder,
          $$CachedExpensesTableUpdateCompanionBuilder,
          (
            CachedExpense,
            BaseReferences<_$AppDatabase, $CachedExpensesTable, CachedExpense>,
          ),
          CachedExpense,
          PrefetchHooks Function()
        > {
  $$CachedExpensesTableTableManager(
    _$AppDatabase db,
    $CachedExpensesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localKey = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExpensesCompanion(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localKey,
                Value<int?> serverId = const Value.absent(),
                required String payloadJson,
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedExpensesCompanion.insert(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedExpensesTable,
      CachedExpense,
      $$CachedExpensesTableFilterComposer,
      $$CachedExpensesTableOrderingComposer,
      $$CachedExpensesTableAnnotationComposer,
      $$CachedExpensesTableCreateCompanionBuilder,
      $$CachedExpensesTableUpdateCompanionBuilder,
      (
        CachedExpense,
        BaseReferences<_$AppDatabase, $CachedExpensesTable, CachedExpense>,
      ),
      CachedExpense,
      PrefetchHooks Function()
    >;
typedef $$CachedPurchasesTableCreateCompanionBuilder =
    CachedPurchasesCompanion Function({
      required String localKey,
      Value<int?> serverId,
      required String payloadJson,
      Value<DateTime?> serverUpdatedAt,
      required DateTime localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });
typedef $$CachedPurchasesTableUpdateCompanionBuilder =
    CachedPurchasesCompanion Function({
      Value<String> localKey,
      Value<int?> serverId,
      Value<String> payloadJson,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });

class $$CachedPurchasesTableFilterComposer
    extends Composer<_$AppDatabase, $CachedPurchasesTable> {
  $$CachedPurchasesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedPurchasesTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedPurchasesTable> {
  $$CachedPurchasesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedPurchasesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedPurchasesTable> {
  $$CachedPurchasesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localKey =>
      $composableBuilder(column: $table.localKey, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );
}

class $$CachedPurchasesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedPurchasesTable,
          CachedPurchase,
          $$CachedPurchasesTableFilterComposer,
          $$CachedPurchasesTableOrderingComposer,
          $$CachedPurchasesTableAnnotationComposer,
          $$CachedPurchasesTableCreateCompanionBuilder,
          $$CachedPurchasesTableUpdateCompanionBuilder,
          (
            CachedPurchase,
            BaseReferences<
              _$AppDatabase,
              $CachedPurchasesTable,
              CachedPurchase
            >,
          ),
          CachedPurchase,
          PrefetchHooks Function()
        > {
  $$CachedPurchasesTableTableManager(
    _$AppDatabase db,
    $CachedPurchasesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedPurchasesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedPurchasesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedPurchasesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localKey = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPurchasesCompanion(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localKey,
                Value<int?> serverId = const Value.absent(),
                required String payloadJson,
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedPurchasesCompanion.insert(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedPurchasesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedPurchasesTable,
      CachedPurchase,
      $$CachedPurchasesTableFilterComposer,
      $$CachedPurchasesTableOrderingComposer,
      $$CachedPurchasesTableAnnotationComposer,
      $$CachedPurchasesTableCreateCompanionBuilder,
      $$CachedPurchasesTableUpdateCompanionBuilder,
      (
        CachedPurchase,
        BaseReferences<_$AppDatabase, $CachedPurchasesTable, CachedPurchase>,
      ),
      CachedPurchase,
      PrefetchHooks Function()
    >;
typedef $$CachedMovementsTableCreateCompanionBuilder =
    CachedMovementsCompanion Function({
      required String localKey,
      Value<int?> serverId,
      required String payloadJson,
      Value<DateTime?> serverUpdatedAt,
      required DateTime localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });
typedef $$CachedMovementsTableUpdateCompanionBuilder =
    CachedMovementsCompanion Function({
      Value<String> localKey,
      Value<int?> serverId,
      Value<String> payloadJson,
      Value<DateTime?> serverUpdatedAt,
      Value<DateTime> localUpdatedAt,
      Value<String> syncState,
      Value<String?> idempotencyKey,
      Value<int> rowid,
    });

class $$CachedMovementsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMovementsTable> {
  $$CachedMovementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CachedMovementsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMovementsTable> {
  $$CachedMovementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get localKey => $composableBuilder(
    column: $table.localKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get serverId => $composableBuilder(
    column: $table.serverId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncState => $composableBuilder(
    column: $table.syncState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CachedMovementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMovementsTable> {
  $$CachedMovementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get localKey =>
      $composableBuilder(column: $table.localKey, builder: (column) => column);

  GeneratedColumn<int> get serverId =>
      $composableBuilder(column: $table.serverId, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get serverUpdatedAt => $composableBuilder(
    column: $table.serverUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get localUpdatedAt => $composableBuilder(
    column: $table.localUpdatedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncState =>
      $composableBuilder(column: $table.syncState, builder: (column) => column);

  GeneratedColumn<String> get idempotencyKey => $composableBuilder(
    column: $table.idempotencyKey,
    builder: (column) => column,
  );
}

class $$CachedMovementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CachedMovementsTable,
          CachedMovement,
          $$CachedMovementsTableFilterComposer,
          $$CachedMovementsTableOrderingComposer,
          $$CachedMovementsTableAnnotationComposer,
          $$CachedMovementsTableCreateCompanionBuilder,
          $$CachedMovementsTableUpdateCompanionBuilder,
          (
            CachedMovement,
            BaseReferences<
              _$AppDatabase,
              $CachedMovementsTable,
              CachedMovement
            >,
          ),
          CachedMovement,
          PrefetchHooks Function()
        > {
  $$CachedMovementsTableTableManager(
    _$AppDatabase db,
    $CachedMovementsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMovementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMovementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMovementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> localKey = const Value.absent(),
                Value<int?> serverId = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                Value<DateTime> localUpdatedAt = const Value.absent(),
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMovementsCompanion(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String localKey,
                Value<int?> serverId = const Value.absent(),
                required String payloadJson,
                Value<DateTime?> serverUpdatedAt = const Value.absent(),
                required DateTime localUpdatedAt,
                Value<String> syncState = const Value.absent(),
                Value<String?> idempotencyKey = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedMovementsCompanion.insert(
                localKey: localKey,
                serverId: serverId,
                payloadJson: payloadJson,
                serverUpdatedAt: serverUpdatedAt,
                localUpdatedAt: localUpdatedAt,
                syncState: syncState,
                idempotencyKey: idempotencyKey,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedMovementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CachedMovementsTable,
      CachedMovement,
      $$CachedMovementsTableFilterComposer,
      $$CachedMovementsTableOrderingComposer,
      $$CachedMovementsTableAnnotationComposer,
      $$CachedMovementsTableCreateCompanionBuilder,
      $$CachedMovementsTableUpdateCompanionBuilder,
      (
        CachedMovement,
        BaseReferences<_$AppDatabase, $CachedMovementsTable, CachedMovement>,
      ),
      CachedMovement,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PendingOperationsTableTableManager get pendingOperations =>
      $$PendingOperationsTableTableManager(_db, _db.pendingOperations);
  $$CachedSalesTableTableManager get cachedSales =>
      $$CachedSalesTableTableManager(_db, _db.cachedSales);
  $$CachedExpensesTableTableManager get cachedExpenses =>
      $$CachedExpensesTableTableManager(_db, _db.cachedExpenses);
  $$CachedPurchasesTableTableManager get cachedPurchases =>
      $$CachedPurchasesTableTableManager(_db, _db.cachedPurchases);
  $$CachedMovementsTableTableManager get cachedMovements =>
      $$CachedMovementsTableTableManager(_db, _db.cachedMovements);
}
