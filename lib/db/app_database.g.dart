// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $StoredDaysTable extends StoredDays
    with TableInfo<$StoredDaysTable, StoredDay> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredDaysTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateKeyMeta = const VerificationMeta(
    'dateKey',
  );
  @override
  late final GeneratedColumn<String> dateKey = GeneratedColumn<String>(
    'date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _morningValueMeta = const VerificationMeta(
    'morningValue',
  );
  @override
  late final GeneratedColumn<int> morningValue = GeneratedColumn<int>(
    'morning_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _eveningValueMeta = const VerificationMeta(
    'eveningValue',
  );
  @override
  late final GeneratedColumn<int> eveningValue = GeneratedColumn<int>(
    'evening_value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(-1),
  );
  static const VerificationMeta _checkboxValuesJsonMeta =
      const VerificationMeta('checkboxValuesJson');
  @override
  late final GeneratedColumn<String> checkboxValuesJson =
      GeneratedColumn<String>(
        'checkbox_values_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  @override
  List<GeneratedColumn> get $columns => [
    dateKey,
    date,
    note,
    morningValue,
    eveningValue,
    checkboxValuesJson,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_days';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredDay> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date_key')) {
      context.handle(
        _dateKeyMeta,
        dateKey.isAcceptableOrUnknown(data['date_key']!, _dateKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_dateKeyMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('morning_value')) {
      context.handle(
        _morningValueMeta,
        morningValue.isAcceptableOrUnknown(
          data['morning_value']!,
          _morningValueMeta,
        ),
      );
    }
    if (data.containsKey('evening_value')) {
      context.handle(
        _eveningValueMeta,
        eveningValue.isAcceptableOrUnknown(
          data['evening_value']!,
          _eveningValueMeta,
        ),
      );
    }
    if (data.containsKey('checkbox_values_json')) {
      context.handle(
        _checkboxValuesJsonMeta,
        checkboxValuesJson.isAcceptableOrUnknown(
          data['checkbox_values_json']!,
          _checkboxValuesJsonMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {dateKey};
  @override
  StoredDay map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredDay(
      dateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date_key'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
      morningValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}morning_value'],
      )!,
      eveningValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}evening_value'],
      )!,
      checkboxValuesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}checkbox_values_json'],
      )!,
    );
  }

  @override
  $StoredDaysTable createAlias(String alias) {
    return $StoredDaysTable(attachedDatabase, alias);
  }
}

class StoredDay extends DataClass implements Insertable<StoredDay> {
  final String dateKey;
  final DateTime date;
  final String note;
  final int morningValue;
  final int eveningValue;
  final String checkboxValuesJson;
  const StoredDay({
    required this.dateKey,
    required this.date,
    required this.note,
    required this.morningValue,
    required this.eveningValue,
    required this.checkboxValuesJson,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date_key'] = Variable<String>(dateKey);
    map['date'] = Variable<DateTime>(date);
    map['note'] = Variable<String>(note);
    map['morning_value'] = Variable<int>(morningValue);
    map['evening_value'] = Variable<int>(eveningValue);
    map['checkbox_values_json'] = Variable<String>(checkboxValuesJson);
    return map;
  }

  StoredDaysCompanion toCompanion(bool nullToAbsent) {
    return StoredDaysCompanion(
      dateKey: Value(dateKey),
      date: Value(date),
      note: Value(note),
      morningValue: Value(morningValue),
      eveningValue: Value(eveningValue),
      checkboxValuesJson: Value(checkboxValuesJson),
    );
  }

  factory StoredDay.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredDay(
      dateKey: serializer.fromJson<String>(json['dateKey']),
      date: serializer.fromJson<DateTime>(json['date']),
      note: serializer.fromJson<String>(json['note']),
      morningValue: serializer.fromJson<int>(json['morningValue']),
      eveningValue: serializer.fromJson<int>(json['eveningValue']),
      checkboxValuesJson: serializer.fromJson<String>(
        json['checkboxValuesJson'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dateKey': serializer.toJson<String>(dateKey),
      'date': serializer.toJson<DateTime>(date),
      'note': serializer.toJson<String>(note),
      'morningValue': serializer.toJson<int>(morningValue),
      'eveningValue': serializer.toJson<int>(eveningValue),
      'checkboxValuesJson': serializer.toJson<String>(checkboxValuesJson),
    };
  }

  StoredDay copyWith({
    String? dateKey,
    DateTime? date,
    String? note,
    int? morningValue,
    int? eveningValue,
    String? checkboxValuesJson,
  }) => StoredDay(
    dateKey: dateKey ?? this.dateKey,
    date: date ?? this.date,
    note: note ?? this.note,
    morningValue: morningValue ?? this.morningValue,
    eveningValue: eveningValue ?? this.eveningValue,
    checkboxValuesJson: checkboxValuesJson ?? this.checkboxValuesJson,
  );
  StoredDay copyWithCompanion(StoredDaysCompanion data) {
    return StoredDay(
      dateKey: data.dateKey.present ? data.dateKey.value : this.dateKey,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      morningValue: data.morningValue.present
          ? data.morningValue.value
          : this.morningValue,
      eveningValue: data.eveningValue.present
          ? data.eveningValue.value
          : this.eveningValue,
      checkboxValuesJson: data.checkboxValuesJson.present
          ? data.checkboxValuesJson.value
          : this.checkboxValuesJson,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredDay(')
          ..write('dateKey: $dateKey, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('morningValue: $morningValue, ')
          ..write('eveningValue: $eveningValue, ')
          ..write('checkboxValuesJson: $checkboxValuesJson')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    dateKey,
    date,
    note,
    morningValue,
    eveningValue,
    checkboxValuesJson,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredDay &&
          other.dateKey == this.dateKey &&
          other.date == this.date &&
          other.note == this.note &&
          other.morningValue == this.morningValue &&
          other.eveningValue == this.eveningValue &&
          other.checkboxValuesJson == this.checkboxValuesJson);
}

class StoredDaysCompanion extends UpdateCompanion<StoredDay> {
  final Value<String> dateKey;
  final Value<DateTime> date;
  final Value<String> note;
  final Value<int> morningValue;
  final Value<int> eveningValue;
  final Value<String> checkboxValuesJson;
  final Value<int> rowid;
  const StoredDaysCompanion({
    this.dateKey = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.morningValue = const Value.absent(),
    this.eveningValue = const Value.absent(),
    this.checkboxValuesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StoredDaysCompanion.insert({
    required String dateKey,
    required DateTime date,
    this.note = const Value.absent(),
    this.morningValue = const Value.absent(),
    this.eveningValue = const Value.absent(),
    this.checkboxValuesJson = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : dateKey = Value(dateKey),
       date = Value(date);
  static Insertable<StoredDay> custom({
    Expression<String>? dateKey,
    Expression<DateTime>? date,
    Expression<String>? note,
    Expression<int>? morningValue,
    Expression<int>? eveningValue,
    Expression<String>? checkboxValuesJson,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (dateKey != null) 'date_key': dateKey,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (morningValue != null) 'morning_value': morningValue,
      if (eveningValue != null) 'evening_value': eveningValue,
      if (checkboxValuesJson != null)
        'checkbox_values_json': checkboxValuesJson,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StoredDaysCompanion copyWith({
    Value<String>? dateKey,
    Value<DateTime>? date,
    Value<String>? note,
    Value<int>? morningValue,
    Value<int>? eveningValue,
    Value<String>? checkboxValuesJson,
    Value<int>? rowid,
  }) {
    return StoredDaysCompanion(
      dateKey: dateKey ?? this.dateKey,
      date: date ?? this.date,
      note: note ?? this.note,
      morningValue: morningValue ?? this.morningValue,
      eveningValue: eveningValue ?? this.eveningValue,
      checkboxValuesJson: checkboxValuesJson ?? this.checkboxValuesJson,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (dateKey.present) {
      map['date_key'] = Variable<String>(dateKey.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (morningValue.present) {
      map['morning_value'] = Variable<int>(morningValue.value);
    }
    if (eveningValue.present) {
      map['evening_value'] = Variable<int>(eveningValue.value);
    }
    if (checkboxValuesJson.present) {
      map['checkbox_values_json'] = Variable<String>(checkboxValuesJson.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredDaysCompanion(')
          ..write('dateKey: $dateKey, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('morningValue: $morningValue, ')
          ..write('eveningValue: $eveningValue, ')
          ..write('checkboxValuesJson: $checkboxValuesJson, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StoredReadingsTable extends StoredReadings
    with TableInfo<$StoredReadingsTable, StoredReading> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StoredReadingsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _dayDateKeyMeta = const VerificationMeta(
    'dayDateKey',
  );
  @override
  late final GeneratedColumn<String> dayDateKey = GeneratedColumn<String>(
    'day_date_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES stored_days (date_key) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _hourMeta = const VerificationMeta('hour');
  @override
  late final GeneratedColumn<int> hour = GeneratedColumn<int>(
    'hour',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minuteMeta = const VerificationMeta('minute');
  @override
  late final GeneratedColumn<int> minute = GeneratedColumn<int>(
    'minute',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayDateKey,
    hour,
    minute,
    value,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stored_readings';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredReading> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_date_key')) {
      context.handle(
        _dayDateKeyMeta,
        dayDateKey.isAcceptableOrUnknown(
          data['day_date_key']!,
          _dayDateKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dayDateKeyMeta);
    }
    if (data.containsKey('hour')) {
      context.handle(
        _hourMeta,
        hour.isAcceptableOrUnknown(data['hour']!, _hourMeta),
      );
    } else if (isInserting) {
      context.missing(_hourMeta);
    }
    if (data.containsKey('minute')) {
      context.handle(
        _minuteMeta,
        minute.isAcceptableOrUnknown(data['minute']!, _minuteMeta),
      );
    } else if (isInserting) {
      context.missing(_minuteMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredReading map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredReading(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayDateKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day_date_key'],
      )!,
      hour: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hour'],
      )!,
      minute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minute'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      )!,
    );
  }

  @override
  $StoredReadingsTable createAlias(String alias) {
    return $StoredReadingsTable(attachedDatabase, alias);
  }
}

class StoredReading extends DataClass implements Insertable<StoredReading> {
  final int id;
  final String dayDateKey;
  final int hour;
  final int minute;
  final int value;
  final String note;
  const StoredReading({
    required this.id,
    required this.dayDateKey,
    required this.hour,
    required this.minute,
    required this.value,
    required this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_date_key'] = Variable<String>(dayDateKey);
    map['hour'] = Variable<int>(hour);
    map['minute'] = Variable<int>(minute);
    map['value'] = Variable<int>(value);
    map['note'] = Variable<String>(note);
    return map;
  }

  StoredReadingsCompanion toCompanion(bool nullToAbsent) {
    return StoredReadingsCompanion(
      id: Value(id),
      dayDateKey: Value(dayDateKey),
      hour: Value(hour),
      minute: Value(minute),
      value: Value(value),
      note: Value(note),
    );
  }

  factory StoredReading.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredReading(
      id: serializer.fromJson<int>(json['id']),
      dayDateKey: serializer.fromJson<String>(json['dayDateKey']),
      hour: serializer.fromJson<int>(json['hour']),
      minute: serializer.fromJson<int>(json['minute']),
      value: serializer.fromJson<int>(json['value']),
      note: serializer.fromJson<String>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayDateKey': serializer.toJson<String>(dayDateKey),
      'hour': serializer.toJson<int>(hour),
      'minute': serializer.toJson<int>(minute),
      'value': serializer.toJson<int>(value),
      'note': serializer.toJson<String>(note),
    };
  }

  StoredReading copyWith({
    int? id,
    String? dayDateKey,
    int? hour,
    int? minute,
    int? value,
    String? note,
  }) => StoredReading(
    id: id ?? this.id,
    dayDateKey: dayDateKey ?? this.dayDateKey,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    value: value ?? this.value,
    note: note ?? this.note,
  );
  StoredReading copyWithCompanion(StoredReadingsCompanion data) {
    return StoredReading(
      id: data.id.present ? data.id.value : this.id,
      dayDateKey: data.dayDateKey.present
          ? data.dayDateKey.value
          : this.dayDateKey,
      hour: data.hour.present ? data.hour.value : this.hour,
      minute: data.minute.present ? data.minute.value : this.minute,
      value: data.value.present ? data.value.value : this.value,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredReading(')
          ..write('id: $id, ')
          ..write('dayDateKey: $dayDateKey, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('value: $value, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, dayDateKey, hour, minute, value, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredReading &&
          other.id == this.id &&
          other.dayDateKey == this.dayDateKey &&
          other.hour == this.hour &&
          other.minute == this.minute &&
          other.value == this.value &&
          other.note == this.note);
}

class StoredReadingsCompanion extends UpdateCompanion<StoredReading> {
  final Value<int> id;
  final Value<String> dayDateKey;
  final Value<int> hour;
  final Value<int> minute;
  final Value<int> value;
  final Value<String> note;
  const StoredReadingsCompanion({
    this.id = const Value.absent(),
    this.dayDateKey = const Value.absent(),
    this.hour = const Value.absent(),
    this.minute = const Value.absent(),
    this.value = const Value.absent(),
    this.note = const Value.absent(),
  });
  StoredReadingsCompanion.insert({
    this.id = const Value.absent(),
    required String dayDateKey,
    required int hour,
    required int minute,
    required int value,
    this.note = const Value.absent(),
  }) : dayDateKey = Value(dayDateKey),
       hour = Value(hour),
       minute = Value(minute),
       value = Value(value);
  static Insertable<StoredReading> custom({
    Expression<int>? id,
    Expression<String>? dayDateKey,
    Expression<int>? hour,
    Expression<int>? minute,
    Expression<int>? value,
    Expression<String>? note,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayDateKey != null) 'day_date_key': dayDateKey,
      if (hour != null) 'hour': hour,
      if (minute != null) 'minute': minute,
      if (value != null) 'value': value,
      if (note != null) 'note': note,
    });
  }

  StoredReadingsCompanion copyWith({
    Value<int>? id,
    Value<String>? dayDateKey,
    Value<int>? hour,
    Value<int>? minute,
    Value<int>? value,
    Value<String>? note,
  }) {
    return StoredReadingsCompanion(
      id: id ?? this.id,
      dayDateKey: dayDateKey ?? this.dayDateKey,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      value: value ?? this.value,
      note: note ?? this.note,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayDateKey.present) {
      map['day_date_key'] = Variable<String>(dayDateKey.value);
    }
    if (hour.present) {
      map['hour'] = Variable<int>(hour.value);
    }
    if (minute.present) {
      map['minute'] = Variable<int>(minute.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StoredReadingsCompanion(')
          ..write('id: $id, ')
          ..write('dayDateKey: $dayDateKey, ')
          ..write('hour: $hour, ')
          ..write('minute: $minute, ')
          ..write('value: $value, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $StoredDaysTable storedDays = $StoredDaysTable(this);
  late final $StoredReadingsTable storedReadings = $StoredReadingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    storedDays,
    storedReadings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'stored_days',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('stored_readings', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$StoredDaysTableCreateCompanionBuilder =
    StoredDaysCompanion Function({
      required String dateKey,
      required DateTime date,
      Value<String> note,
      Value<int> morningValue,
      Value<int> eveningValue,
      Value<String> checkboxValuesJson,
      Value<int> rowid,
    });
typedef $$StoredDaysTableUpdateCompanionBuilder =
    StoredDaysCompanion Function({
      Value<String> dateKey,
      Value<DateTime> date,
      Value<String> note,
      Value<int> morningValue,
      Value<int> eveningValue,
      Value<String> checkboxValuesJson,
      Value<int> rowid,
    });

final class $$StoredDaysTableReferences
    extends BaseReferences<_$AppDatabase, $StoredDaysTable, StoredDay> {
  $$StoredDaysTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$StoredReadingsTable, List<StoredReading>>
  _storedReadingsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.storedReadings,
    aliasName: $_aliasNameGenerator(
      db.storedDays.dateKey,
      db.storedReadings.dayDateKey,
    ),
  );

  $$StoredReadingsTableProcessedTableManager get storedReadingsRefs {
    final manager = $$StoredReadingsTableTableManager($_db, $_db.storedReadings)
        .filter(
          (f) =>
              f.dayDateKey.dateKey.sqlEquals($_itemColumn<String>('date_key')!),
        );

    final cache = $_typedResult.readTableOrNull(_storedReadingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$StoredDaysTableFilterComposer
    extends Composer<_$AppDatabase, $StoredDaysTable> {
  $$StoredDaysTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get morningValue => $composableBuilder(
    column: $table.morningValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get eveningValue => $composableBuilder(
    column: $table.eveningValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get checkboxValuesJson => $composableBuilder(
    column: $table.checkboxValuesJson,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> storedReadingsRefs(
    Expression<bool> Function($$StoredReadingsTableFilterComposer f) f,
  ) {
    final $$StoredReadingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dateKey,
      referencedTable: $db.storedReadings,
      getReferencedColumn: (t) => t.dayDateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredReadingsTableFilterComposer(
            $db: $db,
            $table: $db.storedReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoredDaysTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredDaysTable> {
  $$StoredDaysTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get dateKey => $composableBuilder(
    column: $table.dateKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get morningValue => $composableBuilder(
    column: $table.morningValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get eveningValue => $composableBuilder(
    column: $table.eveningValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get checkboxValuesJson => $composableBuilder(
    column: $table.checkboxValuesJson,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$StoredDaysTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredDaysTable> {
  $$StoredDaysTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get dateKey =>
      $composableBuilder(column: $table.dateKey, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get morningValue => $composableBuilder(
    column: $table.morningValue,
    builder: (column) => column,
  );

  GeneratedColumn<int> get eveningValue => $composableBuilder(
    column: $table.eveningValue,
    builder: (column) => column,
  );

  GeneratedColumn<String> get checkboxValuesJson => $composableBuilder(
    column: $table.checkboxValuesJson,
    builder: (column) => column,
  );

  Expression<T> storedReadingsRefs<T extends Object>(
    Expression<T> Function($$StoredReadingsTableAnnotationComposer a) f,
  ) {
    final $$StoredReadingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dateKey,
      referencedTable: $db.storedReadings,
      getReferencedColumn: (t) => t.dayDateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredReadingsTableAnnotationComposer(
            $db: $db,
            $table: $db.storedReadings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$StoredDaysTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredDaysTable,
          StoredDay,
          $$StoredDaysTableFilterComposer,
          $$StoredDaysTableOrderingComposer,
          $$StoredDaysTableAnnotationComposer,
          $$StoredDaysTableCreateCompanionBuilder,
          $$StoredDaysTableUpdateCompanionBuilder,
          (StoredDay, $$StoredDaysTableReferences),
          StoredDay,
          PrefetchHooks Function({bool storedReadingsRefs})
        > {
  $$StoredDaysTableTableManager(_$AppDatabase db, $StoredDaysTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredDaysTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredDaysTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredDaysTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> dateKey = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<String> note = const Value.absent(),
                Value<int> morningValue = const Value.absent(),
                Value<int> eveningValue = const Value.absent(),
                Value<String> checkboxValuesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredDaysCompanion(
                dateKey: dateKey,
                date: date,
                note: note,
                morningValue: morningValue,
                eveningValue: eveningValue,
                checkboxValuesJson: checkboxValuesJson,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String dateKey,
                required DateTime date,
                Value<String> note = const Value.absent(),
                Value<int> morningValue = const Value.absent(),
                Value<int> eveningValue = const Value.absent(),
                Value<String> checkboxValuesJson = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => StoredDaysCompanion.insert(
                dateKey: dateKey,
                date: date,
                note: note,
                morningValue: morningValue,
                eveningValue: eveningValue,
                checkboxValuesJson: checkboxValuesJson,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoredDaysTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({storedReadingsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (storedReadingsRefs) db.storedReadings,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (storedReadingsRefs)
                    await $_getPrefetchedData<
                      StoredDay,
                      $StoredDaysTable,
                      StoredReading
                    >(
                      currentTable: table,
                      referencedTable: $$StoredDaysTableReferences
                          ._storedReadingsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$StoredDaysTableReferences(
                            db,
                            table,
                            p0,
                          ).storedReadingsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.dayDateKey == item.dateKey,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$StoredDaysTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredDaysTable,
      StoredDay,
      $$StoredDaysTableFilterComposer,
      $$StoredDaysTableOrderingComposer,
      $$StoredDaysTableAnnotationComposer,
      $$StoredDaysTableCreateCompanionBuilder,
      $$StoredDaysTableUpdateCompanionBuilder,
      (StoredDay, $$StoredDaysTableReferences),
      StoredDay,
      PrefetchHooks Function({bool storedReadingsRefs})
    >;
typedef $$StoredReadingsTableCreateCompanionBuilder =
    StoredReadingsCompanion Function({
      Value<int> id,
      required String dayDateKey,
      required int hour,
      required int minute,
      required int value,
      Value<String> note,
    });
typedef $$StoredReadingsTableUpdateCompanionBuilder =
    StoredReadingsCompanion Function({
      Value<int> id,
      Value<String> dayDateKey,
      Value<int> hour,
      Value<int> minute,
      Value<int> value,
      Value<String> note,
    });

final class $$StoredReadingsTableReferences
    extends BaseReferences<_$AppDatabase, $StoredReadingsTable, StoredReading> {
  $$StoredReadingsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $StoredDaysTable _dayDateKeyTable(_$AppDatabase db) =>
      db.storedDays.createAlias(
        $_aliasNameGenerator(
          db.storedReadings.dayDateKey,
          db.storedDays.dateKey,
        ),
      );

  $$StoredDaysTableProcessedTableManager get dayDateKey {
    final $_column = $_itemColumn<String>('day_date_key')!;

    final manager = $$StoredDaysTableTableManager(
      $_db,
      $_db.storedDays,
    ).filter((f) => f.dateKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_dayDateKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$StoredReadingsTableFilterComposer
    extends Composer<_$AppDatabase, $StoredReadingsTable> {
  $$StoredReadingsTableFilterComposer({
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

  ColumnFilters<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$StoredDaysTableFilterComposer get dayDateKey {
    final $$StoredDaysTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayDateKey,
      referencedTable: $db.storedDays,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredDaysTableFilterComposer(
            $db: $db,
            $table: $db.storedDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredReadingsTableOrderingComposer
    extends Composer<_$AppDatabase, $StoredReadingsTable> {
  $$StoredReadingsTableOrderingComposer({
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

  ColumnOrderings<int> get hour => $composableBuilder(
    column: $table.hour,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minute => $composableBuilder(
    column: $table.minute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$StoredDaysTableOrderingComposer get dayDateKey {
    final $$StoredDaysTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayDateKey,
      referencedTable: $db.storedDays,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredDaysTableOrderingComposer(
            $db: $db,
            $table: $db.storedDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredReadingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $StoredReadingsTable> {
  $$StoredReadingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get hour =>
      $composableBuilder(column: $table.hour, builder: (column) => column);

  GeneratedColumn<int> get minute =>
      $composableBuilder(column: $table.minute, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$StoredDaysTableAnnotationComposer get dayDateKey {
    final $$StoredDaysTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.dayDateKey,
      referencedTable: $db.storedDays,
      getReferencedColumn: (t) => t.dateKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$StoredDaysTableAnnotationComposer(
            $db: $db,
            $table: $db.storedDays,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$StoredReadingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $StoredReadingsTable,
          StoredReading,
          $$StoredReadingsTableFilterComposer,
          $$StoredReadingsTableOrderingComposer,
          $$StoredReadingsTableAnnotationComposer,
          $$StoredReadingsTableCreateCompanionBuilder,
          $$StoredReadingsTableUpdateCompanionBuilder,
          (StoredReading, $$StoredReadingsTableReferences),
          StoredReading,
          PrefetchHooks Function({bool dayDateKey})
        > {
  $$StoredReadingsTableTableManager(
    _$AppDatabase db,
    $StoredReadingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$StoredReadingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$StoredReadingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$StoredReadingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> dayDateKey = const Value.absent(),
                Value<int> hour = const Value.absent(),
                Value<int> minute = const Value.absent(),
                Value<int> value = const Value.absent(),
                Value<String> note = const Value.absent(),
              }) => StoredReadingsCompanion(
                id: id,
                dayDateKey: dayDateKey,
                hour: hour,
                minute: minute,
                value: value,
                note: note,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String dayDateKey,
                required int hour,
                required int minute,
                required int value,
                Value<String> note = const Value.absent(),
              }) => StoredReadingsCompanion.insert(
                id: id,
                dayDateKey: dayDateKey,
                hour: hour,
                minute: minute,
                value: value,
                note: note,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$StoredReadingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({dayDateKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
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
                      dynamic
                    >
                  >(state) {
                    if (dayDateKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.dayDateKey,
                                referencedTable: $$StoredReadingsTableReferences
                                    ._dayDateKeyTable(db),
                                referencedColumn:
                                    $$StoredReadingsTableReferences
                                        ._dayDateKeyTable(db)
                                        .dateKey,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$StoredReadingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $StoredReadingsTable,
      StoredReading,
      $$StoredReadingsTableFilterComposer,
      $$StoredReadingsTableOrderingComposer,
      $$StoredReadingsTableAnnotationComposer,
      $$StoredReadingsTableCreateCompanionBuilder,
      $$StoredReadingsTableUpdateCompanionBuilder,
      (StoredReading, $$StoredReadingsTableReferences),
      StoredReading,
      PrefetchHooks Function({bool dayDateKey})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$StoredDaysTableTableManager get storedDays =>
      $$StoredDaysTableTableManager(_db, _db.storedDays);
  $$StoredReadingsTableTableManager get storedReadings =>
      $$StoredReadingsTableTableManager(_db, _db.storedReadings);
}
