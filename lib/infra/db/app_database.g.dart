// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      check: () => id.equals(1),
      type: DriftSqlType.int,
      requiredDuringInsert: false);
  static const VerificationMeta _baseAddressLabelMeta =
      const VerificationMeta('baseAddressLabel');
  @override
  late final GeneratedColumn<String> baseAddressLabel = GeneratedColumn<String>(
      'base_address_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _baseLatMeta =
      const VerificationMeta('baseLat');
  @override
  late final GeneratedColumn<double> baseLat = GeneratedColumn<double>(
      'base_lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _baseLonMeta =
      const VerificationMeta('baseLon');
  @override
  late final GeneratedColumn<double> baseLon = GeneratedColumn<double>(
      'base_lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _defaultRadiusKmMeta =
      const VerificationMeta('defaultRadiusKm');
  @override
  late final GeneratedColumn<int> defaultRadiusKm = GeneratedColumn<int>(
      'default_radius_km', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(15));
  static const VerificationMeta _travelFeeEurosPerBracketMeta =
      const VerificationMeta('travelFeeEurosPerBracket');
  @override
  late final GeneratedColumn<int> travelFeeEurosPerBracket =
      GeneratedColumn<int>('travel_fee_euros_per_bracket', aliasedName, false,
          type: DriftSqlType.int,
          requiredDuringInsert: false,
          defaultValue: const Constant(8));
  static const VerificationMeta _bracketKmMeta =
      const VerificationMeta('bracketKm');
  @override
  late final GeneratedColumn<int> bracketKm = GeneratedColumn<int>(
      'bracket_km', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(10));
  static const VerificationMeta _themeModeMeta =
      const VerificationMeta('themeMode');
  @override
  late final GeneratedColumn<String> themeMode = GeneratedColumn<String>(
      'theme_mode', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('system'));
  static const VerificationMeta _markerDefaultColorMeta =
      const VerificationMeta('markerDefaultColor');
  @override
  late final GeneratedColumn<String> markerDefaultColor =
      GeneratedColumn<String>('marker_default_color', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('#9CA3AF'));
  static const VerificationMeta _markerWaitingColorMeta =
      const VerificationMeta('markerWaitingColor');
  @override
  late final GeneratedColumn<String> markerWaitingColor =
      GeneratedColumn<String>('marker_waiting_color', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('#EAB308'));
  static const VerificationMeta _markerScheduledColorMeta =
      const VerificationMeta('markerScheduledColor');
  @override
  late final GeneratedColumn<String> markerScheduledColor =
      GeneratedColumn<String>('marker_scheduled_color', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('#65A30D'));
  static const VerificationMeta _markerDoneColorMeta =
      const VerificationMeta('markerDoneColor');
  @override
  late final GeneratedColumn<String> markerDoneColor = GeneratedColumn<String>(
      'marker_done_color', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: false,
      defaultValue: const Constant('#166534'));
  static const VerificationMeta _markerNoAnimalsColorMeta =
      const VerificationMeta('markerNoAnimalsColor');
  @override
  late final GeneratedColumn<String> markerNoAnimalsColor =
      GeneratedColumn<String>('marker_no_animals_color', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('#1F2937'));
  static const VerificationMeta _markerBannedColorMeta =
      const VerificationMeta('markerBannedColor');
  @override
  late final GeneratedColumn<String> markerBannedColor =
      GeneratedColumn<String>('marker_banned_color', aliasedName, false,
          type: DriftSqlType.string,
          requiredDuringInsert: false,
          defaultValue: const Constant('#B91C1C'));
  static const VerificationMeta _seasonStartedAtMeta =
      const VerificationMeta('seasonStartedAt');
  @override
  late final GeneratedColumn<int> seasonStartedAt = GeneratedColumn<int>(
      'season_started_at', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns => [
        id,
        baseAddressLabel,
        baseLat,
        baseLon,
        defaultRadiusKm,
        travelFeeEurosPerBracket,
        bracketKm,
        themeMode,
        markerDefaultColor,
        markerWaitingColor,
        markerScheduledColor,
        markerDoneColor,
        markerNoAnimalsColor,
        markerBannedColor,
        seasonStartedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(Insertable<SettingsRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('base_address_label')) {
      context.handle(
          _baseAddressLabelMeta,
          baseAddressLabel.isAcceptableOrUnknown(
              data['base_address_label']!, _baseAddressLabelMeta));
    } else if (isInserting) {
      context.missing(_baseAddressLabelMeta);
    }
    if (data.containsKey('base_lat')) {
      context.handle(_baseLatMeta,
          baseLat.isAcceptableOrUnknown(data['base_lat']!, _baseLatMeta));
    } else if (isInserting) {
      context.missing(_baseLatMeta);
    }
    if (data.containsKey('base_lon')) {
      context.handle(_baseLonMeta,
          baseLon.isAcceptableOrUnknown(data['base_lon']!, _baseLonMeta));
    } else if (isInserting) {
      context.missing(_baseLonMeta);
    }
    if (data.containsKey('default_radius_km')) {
      context.handle(
          _defaultRadiusKmMeta,
          defaultRadiusKm.isAcceptableOrUnknown(
              data['default_radius_km']!, _defaultRadiusKmMeta));
    }
    if (data.containsKey('travel_fee_euros_per_bracket')) {
      context.handle(
          _travelFeeEurosPerBracketMeta,
          travelFeeEurosPerBracket.isAcceptableOrUnknown(
              data['travel_fee_euros_per_bracket']!,
              _travelFeeEurosPerBracketMeta));
    }
    if (data.containsKey('bracket_km')) {
      context.handle(_bracketKmMeta,
          bracketKm.isAcceptableOrUnknown(data['bracket_km']!, _bracketKmMeta));
    }
    if (data.containsKey('theme_mode')) {
      context.handle(_themeModeMeta,
          themeMode.isAcceptableOrUnknown(data['theme_mode']!, _themeModeMeta));
    }
    if (data.containsKey('marker_default_color')) {
      context.handle(
          _markerDefaultColorMeta,
          markerDefaultColor.isAcceptableOrUnknown(
              data['marker_default_color']!, _markerDefaultColorMeta));
    }
    if (data.containsKey('marker_waiting_color')) {
      context.handle(
          _markerWaitingColorMeta,
          markerWaitingColor.isAcceptableOrUnknown(
              data['marker_waiting_color']!, _markerWaitingColorMeta));
    }
    if (data.containsKey('marker_scheduled_color')) {
      context.handle(
          _markerScheduledColorMeta,
          markerScheduledColor.isAcceptableOrUnknown(
              data['marker_scheduled_color']!, _markerScheduledColorMeta));
    }
    if (data.containsKey('marker_done_color')) {
      context.handle(
          _markerDoneColorMeta,
          markerDoneColor.isAcceptableOrUnknown(
              data['marker_done_color']!, _markerDoneColorMeta));
    }
    if (data.containsKey('marker_no_animals_color')) {
      context.handle(
          _markerNoAnimalsColorMeta,
          markerNoAnimalsColor.isAcceptableOrUnknown(
              data['marker_no_animals_color']!, _markerNoAnimalsColorMeta));
    }
    if (data.containsKey('marker_banned_color')) {
      context.handle(
          _markerBannedColorMeta,
          markerBannedColor.isAcceptableOrUnknown(
              data['marker_banned_color']!, _markerBannedColorMeta));
    }
    if (data.containsKey('season_started_at')) {
      context.handle(
          _seasonStartedAtMeta,
          seasonStartedAt.isAcceptableOrUnknown(
              data['season_started_at']!, _seasonStartedAtMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      baseAddressLabel: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}base_address_label'])!,
      baseLat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}base_lat'])!,
      baseLon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}base_lon'])!,
      defaultRadiusKm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}default_radius_km'])!,
      travelFeeEurosPerBracket: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}travel_fee_euros_per_bracket'])!,
      bracketKm: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}bracket_km'])!,
      themeMode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}theme_mode'])!,
      markerDefaultColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}marker_default_color'])!,
      markerWaitingColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}marker_waiting_color'])!,
      markerScheduledColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}marker_scheduled_color'])!,
      markerDoneColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}marker_done_color'])!,
      markerNoAnimalsColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}marker_no_animals_color'])!,
      markerBannedColor: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}marker_banned_color'])!,
      seasonStartedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}season_started_at'])!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;
  final String baseAddressLabel;
  final double baseLat;
  final double baseLon;
  final int defaultRadiusKm;
  final int travelFeeEurosPerBracket;
  final int bracketKm;
  final String themeMode;
  final String markerDefaultColor;
  final String markerWaitingColor;
  final String markerScheduledColor;
  final String markerDoneColor;
  final String markerNoAnimalsColor;
  final String markerBannedColor;
  final int seasonStartedAt;
  const SettingsRow(
      {required this.id,
      required this.baseAddressLabel,
      required this.baseLat,
      required this.baseLon,
      required this.defaultRadiusKm,
      required this.travelFeeEurosPerBracket,
      required this.bracketKm,
      required this.themeMode,
      required this.markerDefaultColor,
      required this.markerWaitingColor,
      required this.markerScheduledColor,
      required this.markerDoneColor,
      required this.markerNoAnimalsColor,
      required this.markerBannedColor,
      required this.seasonStartedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['base_address_label'] = Variable<String>(baseAddressLabel);
    map['base_lat'] = Variable<double>(baseLat);
    map['base_lon'] = Variable<double>(baseLon);
    map['default_radius_km'] = Variable<int>(defaultRadiusKm);
    map['travel_fee_euros_per_bracket'] =
        Variable<int>(travelFeeEurosPerBracket);
    map['bracket_km'] = Variable<int>(bracketKm);
    map['theme_mode'] = Variable<String>(themeMode);
    map['marker_default_color'] = Variable<String>(markerDefaultColor);
    map['marker_waiting_color'] = Variable<String>(markerWaitingColor);
    map['marker_scheduled_color'] = Variable<String>(markerScheduledColor);
    map['marker_done_color'] = Variable<String>(markerDoneColor);
    map['marker_no_animals_color'] = Variable<String>(markerNoAnimalsColor);
    map['marker_banned_color'] = Variable<String>(markerBannedColor);
    map['season_started_at'] = Variable<int>(seasonStartedAt);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      baseAddressLabel: Value(baseAddressLabel),
      baseLat: Value(baseLat),
      baseLon: Value(baseLon),
      defaultRadiusKm: Value(defaultRadiusKm),
      travelFeeEurosPerBracket: Value(travelFeeEurosPerBracket),
      bracketKm: Value(bracketKm),
      themeMode: Value(themeMode),
      markerDefaultColor: Value(markerDefaultColor),
      markerWaitingColor: Value(markerWaitingColor),
      markerScheduledColor: Value(markerScheduledColor),
      markerDoneColor: Value(markerDoneColor),
      markerNoAnimalsColor: Value(markerNoAnimalsColor),
      markerBannedColor: Value(markerBannedColor),
      seasonStartedAt: Value(seasonStartedAt),
    );
  }

  factory SettingsRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      baseAddressLabel: serializer.fromJson<String>(json['baseAddressLabel']),
      baseLat: serializer.fromJson<double>(json['baseLat']),
      baseLon: serializer.fromJson<double>(json['baseLon']),
      defaultRadiusKm: serializer.fromJson<int>(json['defaultRadiusKm']),
      travelFeeEurosPerBracket:
          serializer.fromJson<int>(json['travelFeeEurosPerBracket']),
      bracketKm: serializer.fromJson<int>(json['bracketKm']),
      themeMode: serializer.fromJson<String>(json['themeMode']),
      markerDefaultColor:
          serializer.fromJson<String>(json['markerDefaultColor']),
      markerWaitingColor:
          serializer.fromJson<String>(json['markerWaitingColor']),
      markerScheduledColor:
          serializer.fromJson<String>(json['markerScheduledColor']),
      markerDoneColor: serializer.fromJson<String>(json['markerDoneColor']),
      markerNoAnimalsColor:
          serializer.fromJson<String>(json['markerNoAnimalsColor']),
      markerBannedColor: serializer.fromJson<String>(json['markerBannedColor']),
      seasonStartedAt: serializer.fromJson<int>(json['seasonStartedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'baseAddressLabel': serializer.toJson<String>(baseAddressLabel),
      'baseLat': serializer.toJson<double>(baseLat),
      'baseLon': serializer.toJson<double>(baseLon),
      'defaultRadiusKm': serializer.toJson<int>(defaultRadiusKm),
      'travelFeeEurosPerBracket':
          serializer.toJson<int>(travelFeeEurosPerBracket),
      'bracketKm': serializer.toJson<int>(bracketKm),
      'themeMode': serializer.toJson<String>(themeMode),
      'markerDefaultColor': serializer.toJson<String>(markerDefaultColor),
      'markerWaitingColor': serializer.toJson<String>(markerWaitingColor),
      'markerScheduledColor': serializer.toJson<String>(markerScheduledColor),
      'markerDoneColor': serializer.toJson<String>(markerDoneColor),
      'markerNoAnimalsColor': serializer.toJson<String>(markerNoAnimalsColor),
      'markerBannedColor': serializer.toJson<String>(markerBannedColor),
      'seasonStartedAt': serializer.toJson<int>(seasonStartedAt),
    };
  }

  SettingsRow copyWith(
          {int? id,
          String? baseAddressLabel,
          double? baseLat,
          double? baseLon,
          int? defaultRadiusKm,
          int? travelFeeEurosPerBracket,
          int? bracketKm,
          String? themeMode,
          String? markerDefaultColor,
          String? markerWaitingColor,
          String? markerScheduledColor,
          String? markerDoneColor,
          String? markerNoAnimalsColor,
          String? markerBannedColor,
          int? seasonStartedAt}) =>
      SettingsRow(
        id: id ?? this.id,
        baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
        baseLat: baseLat ?? this.baseLat,
        baseLon: baseLon ?? this.baseLon,
        defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
        travelFeeEurosPerBracket:
            travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
        bracketKm: bracketKm ?? this.bracketKm,
        themeMode: themeMode ?? this.themeMode,
        markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
        markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
        markerScheduledColor: markerScheduledColor ?? this.markerScheduledColor,
        markerDoneColor: markerDoneColor ?? this.markerDoneColor,
        markerNoAnimalsColor: markerNoAnimalsColor ?? this.markerNoAnimalsColor,
        markerBannedColor: markerBannedColor ?? this.markerBannedColor,
        seasonStartedAt: seasonStartedAt ?? this.seasonStartedAt,
      );
  SettingsRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      baseAddressLabel: data.baseAddressLabel.present
          ? data.baseAddressLabel.value
          : this.baseAddressLabel,
      baseLat: data.baseLat.present ? data.baseLat.value : this.baseLat,
      baseLon: data.baseLon.present ? data.baseLon.value : this.baseLon,
      defaultRadiusKm: data.defaultRadiusKm.present
          ? data.defaultRadiusKm.value
          : this.defaultRadiusKm,
      travelFeeEurosPerBracket: data.travelFeeEurosPerBracket.present
          ? data.travelFeeEurosPerBracket.value
          : this.travelFeeEurosPerBracket,
      bracketKm: data.bracketKm.present ? data.bracketKm.value : this.bracketKm,
      themeMode: data.themeMode.present ? data.themeMode.value : this.themeMode,
      markerDefaultColor: data.markerDefaultColor.present
          ? data.markerDefaultColor.value
          : this.markerDefaultColor,
      markerWaitingColor: data.markerWaitingColor.present
          ? data.markerWaitingColor.value
          : this.markerWaitingColor,
      markerScheduledColor: data.markerScheduledColor.present
          ? data.markerScheduledColor.value
          : this.markerScheduledColor,
      markerDoneColor: data.markerDoneColor.present
          ? data.markerDoneColor.value
          : this.markerDoneColor,
      markerNoAnimalsColor: data.markerNoAnimalsColor.present
          ? data.markerNoAnimalsColor.value
          : this.markerNoAnimalsColor,
      markerBannedColor: data.markerBannedColor.present
          ? data.markerBannedColor.value
          : this.markerBannedColor,
      seasonStartedAt: data.seasonStartedAt.present
          ? data.seasonStartedAt.value
          : this.seasonStartedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('baseAddressLabel: $baseAddressLabel, ')
          ..write('baseLat: $baseLat, ')
          ..write('baseLon: $baseLon, ')
          ..write('defaultRadiusKm: $defaultRadiusKm, ')
          ..write('travelFeeEurosPerBracket: $travelFeeEurosPerBracket, ')
          ..write('bracketKm: $bracketKm, ')
          ..write('themeMode: $themeMode, ')
          ..write('markerDefaultColor: $markerDefaultColor, ')
          ..write('markerWaitingColor: $markerWaitingColor, ')
          ..write('markerScheduledColor: $markerScheduledColor, ')
          ..write('markerDoneColor: $markerDoneColor, ')
          ..write('markerNoAnimalsColor: $markerNoAnimalsColor, ')
          ..write('markerBannedColor: $markerBannedColor, ')
          ..write('seasonStartedAt: $seasonStartedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      baseAddressLabel,
      baseLat,
      baseLon,
      defaultRadiusKm,
      travelFeeEurosPerBracket,
      bracketKm,
      themeMode,
      markerDefaultColor,
      markerWaitingColor,
      markerScheduledColor,
      markerDoneColor,
      markerNoAnimalsColor,
      markerBannedColor,
      seasonStartedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.baseAddressLabel == this.baseAddressLabel &&
          other.baseLat == this.baseLat &&
          other.baseLon == this.baseLon &&
          other.defaultRadiusKm == this.defaultRadiusKm &&
          other.travelFeeEurosPerBracket == this.travelFeeEurosPerBracket &&
          other.bracketKm == this.bracketKm &&
          other.themeMode == this.themeMode &&
          other.markerDefaultColor == this.markerDefaultColor &&
          other.markerWaitingColor == this.markerWaitingColor &&
          other.markerScheduledColor == this.markerScheduledColor &&
          other.markerDoneColor == this.markerDoneColor &&
          other.markerNoAnimalsColor == this.markerNoAnimalsColor &&
          other.markerBannedColor == this.markerBannedColor &&
          other.seasonStartedAt == this.seasonStartedAt);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> baseAddressLabel;
  final Value<double> baseLat;
  final Value<double> baseLon;
  final Value<int> defaultRadiusKm;
  final Value<int> travelFeeEurosPerBracket;
  final Value<int> bracketKm;
  final Value<String> themeMode;
  final Value<String> markerDefaultColor;
  final Value<String> markerWaitingColor;
  final Value<String> markerScheduledColor;
  final Value<String> markerDoneColor;
  final Value<String> markerNoAnimalsColor;
  final Value<String> markerBannedColor;
  final Value<int> seasonStartedAt;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.baseAddressLabel = const Value.absent(),
    this.baseLat = const Value.absent(),
    this.baseLon = const Value.absent(),
    this.defaultRadiusKm = const Value.absent(),
    this.travelFeeEurosPerBracket = const Value.absent(),
    this.bracketKm = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.markerDefaultColor = const Value.absent(),
    this.markerWaitingColor = const Value.absent(),
    this.markerScheduledColor = const Value.absent(),
    this.markerDoneColor = const Value.absent(),
    this.markerNoAnimalsColor = const Value.absent(),
    this.markerBannedColor = const Value.absent(),
    this.seasonStartedAt = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String baseAddressLabel,
    required double baseLat,
    required double baseLon,
    this.defaultRadiusKm = const Value.absent(),
    this.travelFeeEurosPerBracket = const Value.absent(),
    this.bracketKm = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.markerDefaultColor = const Value.absent(),
    this.markerWaitingColor = const Value.absent(),
    this.markerScheduledColor = const Value.absent(),
    this.markerDoneColor = const Value.absent(),
    this.markerNoAnimalsColor = const Value.absent(),
    this.markerBannedColor = const Value.absent(),
    this.seasonStartedAt = const Value.absent(),
  })  : baseAddressLabel = Value(baseAddressLabel),
        baseLat = Value(baseLat),
        baseLon = Value(baseLon);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<String>? baseAddressLabel,
    Expression<double>? baseLat,
    Expression<double>? baseLon,
    Expression<int>? defaultRadiusKm,
    Expression<int>? travelFeeEurosPerBracket,
    Expression<int>? bracketKm,
    Expression<String>? themeMode,
    Expression<String>? markerDefaultColor,
    Expression<String>? markerWaitingColor,
    Expression<String>? markerScheduledColor,
    Expression<String>? markerDoneColor,
    Expression<String>? markerNoAnimalsColor,
    Expression<String>? markerBannedColor,
    Expression<int>? seasonStartedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseAddressLabel != null) 'base_address_label': baseAddressLabel,
      if (baseLat != null) 'base_lat': baseLat,
      if (baseLon != null) 'base_lon': baseLon,
      if (defaultRadiusKm != null) 'default_radius_km': defaultRadiusKm,
      if (travelFeeEurosPerBracket != null)
        'travel_fee_euros_per_bracket': travelFeeEurosPerBracket,
      if (bracketKm != null) 'bracket_km': bracketKm,
      if (themeMode != null) 'theme_mode': themeMode,
      if (markerDefaultColor != null)
        'marker_default_color': markerDefaultColor,
      if (markerWaitingColor != null)
        'marker_waiting_color': markerWaitingColor,
      if (markerScheduledColor != null)
        'marker_scheduled_color': markerScheduledColor,
      if (markerDoneColor != null) 'marker_done_color': markerDoneColor,
      if (markerNoAnimalsColor != null)
        'marker_no_animals_color': markerNoAnimalsColor,
      if (markerBannedColor != null) 'marker_banned_color': markerBannedColor,
      if (seasonStartedAt != null) 'season_started_at': seasonStartedAt,
    });
  }

  SettingsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? baseAddressLabel,
      Value<double>? baseLat,
      Value<double>? baseLon,
      Value<int>? defaultRadiusKm,
      Value<int>? travelFeeEurosPerBracket,
      Value<int>? bracketKm,
      Value<String>? themeMode,
      Value<String>? markerDefaultColor,
      Value<String>? markerWaitingColor,
      Value<String>? markerScheduledColor,
      Value<String>? markerDoneColor,
      Value<String>? markerNoAnimalsColor,
      Value<String>? markerBannedColor,
      Value<int>? seasonStartedAt}) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
      baseLat: baseLat ?? this.baseLat,
      baseLon: baseLon ?? this.baseLon,
      defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
      travelFeeEurosPerBracket:
          travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
      bracketKm: bracketKm ?? this.bracketKm,
      themeMode: themeMode ?? this.themeMode,
      markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
      markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
      markerScheduledColor: markerScheduledColor ?? this.markerScheduledColor,
      markerDoneColor: markerDoneColor ?? this.markerDoneColor,
      markerNoAnimalsColor: markerNoAnimalsColor ?? this.markerNoAnimalsColor,
      markerBannedColor: markerBannedColor ?? this.markerBannedColor,
      seasonStartedAt: seasonStartedAt ?? this.seasonStartedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (baseAddressLabel.present) {
      map['base_address_label'] = Variable<String>(baseAddressLabel.value);
    }
    if (baseLat.present) {
      map['base_lat'] = Variable<double>(baseLat.value);
    }
    if (baseLon.present) {
      map['base_lon'] = Variable<double>(baseLon.value);
    }
    if (defaultRadiusKm.present) {
      map['default_radius_km'] = Variable<int>(defaultRadiusKm.value);
    }
    if (travelFeeEurosPerBracket.present) {
      map['travel_fee_euros_per_bracket'] =
          Variable<int>(travelFeeEurosPerBracket.value);
    }
    if (bracketKm.present) {
      map['bracket_km'] = Variable<int>(bracketKm.value);
    }
    if (themeMode.present) {
      map['theme_mode'] = Variable<String>(themeMode.value);
    }
    if (markerDefaultColor.present) {
      map['marker_default_color'] = Variable<String>(markerDefaultColor.value);
    }
    if (markerWaitingColor.present) {
      map['marker_waiting_color'] = Variable<String>(markerWaitingColor.value);
    }
    if (markerScheduledColor.present) {
      map['marker_scheduled_color'] =
          Variable<String>(markerScheduledColor.value);
    }
    if (markerDoneColor.present) {
      map['marker_done_color'] = Variable<String>(markerDoneColor.value);
    }
    if (markerNoAnimalsColor.present) {
      map['marker_no_animals_color'] =
          Variable<String>(markerNoAnimalsColor.value);
    }
    if (markerBannedColor.present) {
      map['marker_banned_color'] = Variable<String>(markerBannedColor.value);
    }
    if (seasonStartedAt.present) {
      map['season_started_at'] = Variable<int>(seasonStartedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('baseAddressLabel: $baseAddressLabel, ')
          ..write('baseLat: $baseLat, ')
          ..write('baseLon: $baseLon, ')
          ..write('defaultRadiusKm: $defaultRadiusKm, ')
          ..write('travelFeeEurosPerBracket: $travelFeeEurosPerBracket, ')
          ..write('bracketKm: $bracketKm, ')
          ..write('themeMode: $themeMode, ')
          ..write('markerDefaultColor: $markerDefaultColor, ')
          ..write('markerWaitingColor: $markerWaitingColor, ')
          ..write('markerScheduledColor: $markerScheduledColor, ')
          ..write('markerDoneColor: $markerDoneColor, ')
          ..write('markerNoAnimalsColor: $markerNoAnimalsColor, ')
          ..write('markerBannedColor: $markerBannedColor, ')
          ..write('seasonStartedAt: $seasonStartedAt')
          ..write(')'))
        .toString();
  }
}

class $ClientsTableTable extends ClientsTable
    with TableInfo<$ClientsTableTable, ClientRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClientsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<String>, String> phones =
      GeneratedColumn<String>('phones', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<String>>($ClientsTableTable.$converterphones);
  static const VerificationMeta _addressLabelMeta =
      const VerificationMeta('addressLabel');
  @override
  late final GeneratedColumn<String> addressLabel = GeneratedColumn<String>(
      'address_label', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _postcodeMeta =
      const VerificationMeta('postcode');
  @override
  late final GeneratedColumn<String> postcode = GeneratedColumn<String>(
      'postcode', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cityMeta = const VerificationMeta('city');
  @override
  late final GeneratedColumn<String> city = GeneratedColumn<String>(
      'city', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latMeta = const VerificationMeta('lat');
  @override
  late final GeneratedColumn<double> lat = GeneratedColumn<double>(
      'lat', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _lonMeta = const VerificationMeta('lon');
  @override
  late final GeneratedColumn<double> lon = GeneratedColumn<double>(
      'lon', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<AnimalCount>, String>
      animals = GeneratedColumn<String>('animals', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<AnimalCount>>(
              $ClientsTableTable.$converteranimals);
  static const VerificationMeta _markerColorHexMeta =
      const VerificationMeta('markerColorHex');
  @override
  late final GeneratedColumn<String> markerColorHex = GeneratedColumn<String>(
      'marker_color_hex', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _isWaitingMeta =
      const VerificationMeta('isWaiting');
  @override
  late final GeneratedColumn<bool> isWaiting = GeneratedColumn<bool>(
      'is_waiting', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_waiting" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _lastInterventionDateMeta =
      const VerificationMeta('lastInterventionDate');
  @override
  late final GeneratedColumn<int> lastInterventionDate = GeneratedColumn<int>(
      'last_intervention_date', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _needsDistanceRecomputeMeta =
      const VerificationMeta('needsDistanceRecompute');
  @override
  late final GeneratedColumn<bool> needsDistanceRecompute =
      GeneratedColumn<bool>('needs_distance_recompute', aliasedName, false,
          type: DriftSqlType.bool,
          requiredDuringInsert: false,
          defaultConstraints: GeneratedColumn.constraintIsAlways(
              'CHECK ("needs_distance_recompute" IN (0, 1))'),
          defaultValue: const Constant(false));
  static const VerificationMeta _isBannedMeta =
      const VerificationMeta('isBanned');
  @override
  late final GeneratedColumn<bool> isBanned = GeneratedColumn<bool>(
      'is_banned', aliasedName, false,
      type: DriftSqlType.bool,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('CHECK ("is_banned" IN (0, 1))'),
      defaultValue: const Constant(false));
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        name,
        phones,
        addressLabel,
        postcode,
        city,
        lat,
        lon,
        animals,
        markerColorHex,
        isWaiting,
        lastInterventionDate,
        needsDistanceRecompute,
        isBanned,
        createdAt,
        updatedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clients';
  @override
  VerificationContext validateIntegrity(Insertable<ClientRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address_label')) {
      context.handle(
          _addressLabelMeta,
          addressLabel.isAcceptableOrUnknown(
              data['address_label']!, _addressLabelMeta));
    } else if (isInserting) {
      context.missing(_addressLabelMeta);
    }
    if (data.containsKey('postcode')) {
      context.handle(_postcodeMeta,
          postcode.isAcceptableOrUnknown(data['postcode']!, _postcodeMeta));
    } else if (isInserting) {
      context.missing(_postcodeMeta);
    }
    if (data.containsKey('city')) {
      context.handle(
          _cityMeta, city.isAcceptableOrUnknown(data['city']!, _cityMeta));
    } else if (isInserting) {
      context.missing(_cityMeta);
    }
    if (data.containsKey('lat')) {
      context.handle(
          _latMeta, lat.isAcceptableOrUnknown(data['lat']!, _latMeta));
    } else if (isInserting) {
      context.missing(_latMeta);
    }
    if (data.containsKey('lon')) {
      context.handle(
          _lonMeta, lon.isAcceptableOrUnknown(data['lon']!, _lonMeta));
    } else if (isInserting) {
      context.missing(_lonMeta);
    }
    if (data.containsKey('marker_color_hex')) {
      context.handle(
          _markerColorHexMeta,
          markerColorHex.isAcceptableOrUnknown(
              data['marker_color_hex']!, _markerColorHexMeta));
    }
    if (data.containsKey('is_waiting')) {
      context.handle(_isWaitingMeta,
          isWaiting.isAcceptableOrUnknown(data['is_waiting']!, _isWaitingMeta));
    }
    if (data.containsKey('last_intervention_date')) {
      context.handle(
          _lastInterventionDateMeta,
          lastInterventionDate.isAcceptableOrUnknown(
              data['last_intervention_date']!, _lastInterventionDateMeta));
    }
    if (data.containsKey('needs_distance_recompute')) {
      context.handle(
          _needsDistanceRecomputeMeta,
          needsDistanceRecompute.isAcceptableOrUnknown(
              data['needs_distance_recompute']!, _needsDistanceRecomputeMeta));
    }
    if (data.containsKey('is_banned')) {
      context.handle(_isBannedMeta,
          isBanned.isAcceptableOrUnknown(data['is_banned']!, _isBannedMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ClientRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ClientRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      phones: $ClientsTableTable.$converterphones.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phones'])!),
      addressLabel: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}address_label'])!,
      postcode: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}postcode'])!,
      city: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}city'])!,
      lat: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lat'])!,
      lon: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}lon'])!,
      animals: $ClientsTableTable.$converteranimals.fromSql(attachedDatabase
          .typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}animals'])!),
      markerColorHex: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}marker_color_hex']),
      isWaiting: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_waiting'])!,
      lastInterventionDate: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}last_intervention_date']),
      needsDistanceRecompute: attachedDatabase.typeMapping.read(
          DriftSqlType.bool,
          data['${effectivePrefix}needs_distance_recompute'])!,
      isBanned: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_banned'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ClientsTableTable createAlias(String alias) {
    return $ClientsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<String>, String> $converterphones =
      const PhoneListConverter();
  static TypeConverter<List<AnimalCount>, String> $converteranimals =
      const AnimalCountListConverter();
}

class ClientRow extends DataClass implements Insertable<ClientRow> {
  final int id;
  final String name;
  final List<String> phones;
  final String addressLabel;
  final String postcode;
  final String city;
  final double lat;
  final double lon;
  final List<AnimalCount> animals;
  final String? markerColorHex;
  final bool isWaiting;
  final int? lastInterventionDate;
  final bool needsDistanceRecompute;
  final bool isBanned;
  final int createdAt;
  final int updatedAt;
  const ClientRow(
      {required this.id,
      required this.name,
      required this.phones,
      required this.addressLabel,
      required this.postcode,
      required this.city,
      required this.lat,
      required this.lon,
      required this.animals,
      this.markerColorHex,
      required this.isWaiting,
      this.lastInterventionDate,
      required this.needsDistanceRecompute,
      required this.isBanned,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    {
      map['phones'] =
          Variable<String>($ClientsTableTable.$converterphones.toSql(phones));
    }
    map['address_label'] = Variable<String>(addressLabel);
    map['postcode'] = Variable<String>(postcode);
    map['city'] = Variable<String>(city);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    {
      map['animals'] =
          Variable<String>($ClientsTableTable.$converteranimals.toSql(animals));
    }
    if (!nullToAbsent || markerColorHex != null) {
      map['marker_color_hex'] = Variable<String>(markerColorHex);
    }
    map['is_waiting'] = Variable<bool>(isWaiting);
    if (!nullToAbsent || lastInterventionDate != null) {
      map['last_intervention_date'] = Variable<int>(lastInterventionDate);
    }
    map['needs_distance_recompute'] = Variable<bool>(needsDistanceRecompute);
    map['is_banned'] = Variable<bool>(isBanned);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ClientsTableCompanion toCompanion(bool nullToAbsent) {
    return ClientsTableCompanion(
      id: Value(id),
      name: Value(name),
      phones: Value(phones),
      addressLabel: Value(addressLabel),
      postcode: Value(postcode),
      city: Value(city),
      lat: Value(lat),
      lon: Value(lon),
      animals: Value(animals),
      markerColorHex: markerColorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(markerColorHex),
      isWaiting: Value(isWaiting),
      lastInterventionDate: lastInterventionDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastInterventionDate),
      needsDistanceRecompute: Value(needsDistanceRecompute),
      isBanned: Value(isBanned),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ClientRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ClientRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      phones: serializer.fromJson<List<String>>(json['phones']),
      addressLabel: serializer.fromJson<String>(json['addressLabel']),
      postcode: serializer.fromJson<String>(json['postcode']),
      city: serializer.fromJson<String>(json['city']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      animals: serializer.fromJson<List<AnimalCount>>(json['animals']),
      markerColorHex: serializer.fromJson<String?>(json['markerColorHex']),
      isWaiting: serializer.fromJson<bool>(json['isWaiting']),
      lastInterventionDate:
          serializer.fromJson<int?>(json['lastInterventionDate']),
      needsDistanceRecompute:
          serializer.fromJson<bool>(json['needsDistanceRecompute']),
      isBanned: serializer.fromJson<bool>(json['isBanned']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'phones': serializer.toJson<List<String>>(phones),
      'addressLabel': serializer.toJson<String>(addressLabel),
      'postcode': serializer.toJson<String>(postcode),
      'city': serializer.toJson<String>(city),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'animals': serializer.toJson<List<AnimalCount>>(animals),
      'markerColorHex': serializer.toJson<String?>(markerColorHex),
      'isWaiting': serializer.toJson<bool>(isWaiting),
      'lastInterventionDate': serializer.toJson<int?>(lastInterventionDate),
      'needsDistanceRecompute': serializer.toJson<bool>(needsDistanceRecompute),
      'isBanned': serializer.toJson<bool>(isBanned),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ClientRow copyWith(
          {int? id,
          String? name,
          List<String>? phones,
          String? addressLabel,
          String? postcode,
          String? city,
          double? lat,
          double? lon,
          List<AnimalCount>? animals,
          Value<String?> markerColorHex = const Value.absent(),
          bool? isWaiting,
          Value<int?> lastInterventionDate = const Value.absent(),
          bool? needsDistanceRecompute,
          bool? isBanned,
          int? createdAt,
          int? updatedAt}) =>
      ClientRow(
        id: id ?? this.id,
        name: name ?? this.name,
        phones: phones ?? this.phones,
        addressLabel: addressLabel ?? this.addressLabel,
        postcode: postcode ?? this.postcode,
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        animals: animals ?? this.animals,
        markerColorHex:
            markerColorHex.present ? markerColorHex.value : this.markerColorHex,
        isWaiting: isWaiting ?? this.isWaiting,
        lastInterventionDate: lastInterventionDate.present
            ? lastInterventionDate.value
            : this.lastInterventionDate,
        needsDistanceRecompute:
            needsDistanceRecompute ?? this.needsDistanceRecompute,
        isBanned: isBanned ?? this.isBanned,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ClientRow copyWithCompanion(ClientsTableCompanion data) {
    return ClientRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      phones: data.phones.present ? data.phones.value : this.phones,
      addressLabel: data.addressLabel.present
          ? data.addressLabel.value
          : this.addressLabel,
      postcode: data.postcode.present ? data.postcode.value : this.postcode,
      city: data.city.present ? data.city.value : this.city,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      animals: data.animals.present ? data.animals.value : this.animals,
      markerColorHex: data.markerColorHex.present
          ? data.markerColorHex.value
          : this.markerColorHex,
      isWaiting: data.isWaiting.present ? data.isWaiting.value : this.isWaiting,
      lastInterventionDate: data.lastInterventionDate.present
          ? data.lastInterventionDate.value
          : this.lastInterventionDate,
      needsDistanceRecompute: data.needsDistanceRecompute.present
          ? data.needsDistanceRecompute.value
          : this.needsDistanceRecompute,
      isBanned: data.isBanned.present ? data.isBanned.value : this.isBanned,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ClientRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phones: $phones, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('postcode: $postcode, ')
          ..write('city: $city, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('animals: $animals, ')
          ..write('markerColorHex: $markerColorHex, ')
          ..write('isWaiting: $isWaiting, ')
          ..write('lastInterventionDate: $lastInterventionDate, ')
          ..write('needsDistanceRecompute: $needsDistanceRecompute, ')
          ..write('isBanned: $isBanned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      name,
      phones,
      addressLabel,
      postcode,
      city,
      lat,
      lon,
      animals,
      markerColorHex,
      isWaiting,
      lastInterventionDate,
      needsDistanceRecompute,
      isBanned,
      createdAt,
      updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClientRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.phones == this.phones &&
          other.addressLabel == this.addressLabel &&
          other.postcode == this.postcode &&
          other.city == this.city &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.animals == this.animals &&
          other.markerColorHex == this.markerColorHex &&
          other.isWaiting == this.isWaiting &&
          other.lastInterventionDate == this.lastInterventionDate &&
          other.needsDistanceRecompute == this.needsDistanceRecompute &&
          other.isBanned == this.isBanned &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClientsTableCompanion extends UpdateCompanion<ClientRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<List<String>> phones;
  final Value<String> addressLabel;
  final Value<String> postcode;
  final Value<String> city;
  final Value<double> lat;
  final Value<double> lon;
  final Value<List<AnimalCount>> animals;
  final Value<String?> markerColorHex;
  final Value<bool> isWaiting;
  final Value<int?> lastInterventionDate;
  final Value<bool> needsDistanceRecompute;
  final Value<bool> isBanned;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ClientsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phones = const Value.absent(),
    this.addressLabel = const Value.absent(),
    this.postcode = const Value.absent(),
    this.city = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.animals = const Value.absent(),
    this.markerColorHex = const Value.absent(),
    this.isWaiting = const Value.absent(),
    this.lastInterventionDate = const Value.absent(),
    this.needsDistanceRecompute = const Value.absent(),
    this.isBanned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ClientsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phones = const Value.absent(),
    required String addressLabel,
    required String postcode,
    required String city,
    required double lat,
    required double lon,
    this.animals = const Value.absent(),
    this.markerColorHex = const Value.absent(),
    this.isWaiting = const Value.absent(),
    this.lastInterventionDate = const Value.absent(),
    this.needsDistanceRecompute = const Value.absent(),
    this.isBanned = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  })  : name = Value(name),
        addressLabel = Value(addressLabel),
        postcode = Value(postcode),
        city = Value(city),
        lat = Value(lat),
        lon = Value(lon),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ClientRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? phones,
    Expression<String>? addressLabel,
    Expression<String>? postcode,
    Expression<String>? city,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<String>? animals,
    Expression<String>? markerColorHex,
    Expression<bool>? isWaiting,
    Expression<int>? lastInterventionDate,
    Expression<bool>? needsDistanceRecompute,
    Expression<bool>? isBanned,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phones != null) 'phones': phones,
      if (addressLabel != null) 'address_label': addressLabel,
      if (postcode != null) 'postcode': postcode,
      if (city != null) 'city': city,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (animals != null) 'animals': animals,
      if (markerColorHex != null) 'marker_color_hex': markerColorHex,
      if (isWaiting != null) 'is_waiting': isWaiting,
      if (lastInterventionDate != null)
        'last_intervention_date': lastInterventionDate,
      if (needsDistanceRecompute != null)
        'needs_distance_recompute': needsDistanceRecompute,
      if (isBanned != null) 'is_banned': isBanned,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ClientsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<List<String>>? phones,
      Value<String>? addressLabel,
      Value<String>? postcode,
      Value<String>? city,
      Value<double>? lat,
      Value<double>? lon,
      Value<List<AnimalCount>>? animals,
      Value<String?>? markerColorHex,
      Value<bool>? isWaiting,
      Value<int?>? lastInterventionDate,
      Value<bool>? needsDistanceRecompute,
      Value<bool>? isBanned,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return ClientsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phones: phones ?? this.phones,
      addressLabel: addressLabel ?? this.addressLabel,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      animals: animals ?? this.animals,
      markerColorHex: markerColorHex ?? this.markerColorHex,
      isWaiting: isWaiting ?? this.isWaiting,
      lastInterventionDate: lastInterventionDate ?? this.lastInterventionDate,
      needsDistanceRecompute:
          needsDistanceRecompute ?? this.needsDistanceRecompute,
      isBanned: isBanned ?? this.isBanned,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (phones.present) {
      map['phones'] = Variable<String>(
          $ClientsTableTable.$converterphones.toSql(phones.value));
    }
    if (addressLabel.present) {
      map['address_label'] = Variable<String>(addressLabel.value);
    }
    if (postcode.present) {
      map['postcode'] = Variable<String>(postcode.value);
    }
    if (city.present) {
      map['city'] = Variable<String>(city.value);
    }
    if (lat.present) {
      map['lat'] = Variable<double>(lat.value);
    }
    if (lon.present) {
      map['lon'] = Variable<double>(lon.value);
    }
    if (animals.present) {
      map['animals'] = Variable<String>(
          $ClientsTableTable.$converteranimals.toSql(animals.value));
    }
    if (markerColorHex.present) {
      map['marker_color_hex'] = Variable<String>(markerColorHex.value);
    }
    if (isWaiting.present) {
      map['is_waiting'] = Variable<bool>(isWaiting.value);
    }
    if (lastInterventionDate.present) {
      map['last_intervention_date'] = Variable<int>(lastInterventionDate.value);
    }
    if (needsDistanceRecompute.present) {
      map['needs_distance_recompute'] =
          Variable<bool>(needsDistanceRecompute.value);
    }
    if (isBanned.present) {
      map['is_banned'] = Variable<bool>(isBanned.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClientsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('phones: $phones, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('postcode: $postcode, ')
          ..write('city: $city, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('animals: $animals, ')
          ..write('markerColorHex: $markerColorHex, ')
          ..write('isWaiting: $isWaiting, ')
          ..write('lastInterventionDate: $lastInterventionDate, ')
          ..write('needsDistanceRecompute: $needsDistanceRecompute, ')
          ..write('isBanned: $isBanned, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $DistanceMatrixTableTable extends DistanceMatrixTable
    with TableInfo<$DistanceMatrixTableTable, DistanceMatrixRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DistanceMatrixTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromIdMeta = const VerificationMeta('fromId');
  @override
  late final GeneratedColumn<int> fromId = GeneratedColumn<int>(
      'from_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _toIdMeta = const VerificationMeta('toId');
  @override
  late final GeneratedColumn<int> toId = GeneratedColumn<int>(
      'to_id', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _distanceMetersMeta =
      const VerificationMeta('distanceMeters');
  @override
  late final GeneratedColumn<int> distanceMeters = GeneratedColumn<int>(
      'distance_meters', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _computedAtMeta =
      const VerificationMeta('computedAt');
  @override
  late final GeneratedColumn<int> computedAt = GeneratedColumn<int>(
      'computed_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [fromId, toId, distanceMeters, durationSeconds, computedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'distance_matrix';
  @override
  VerificationContext validateIntegrity(Insertable<DistanceMatrixRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_id')) {
      context.handle(_fromIdMeta,
          fromId.isAcceptableOrUnknown(data['from_id']!, _fromIdMeta));
    } else if (isInserting) {
      context.missing(_fromIdMeta);
    }
    if (data.containsKey('to_id')) {
      context.handle(
          _toIdMeta, toId.isAcceptableOrUnknown(data['to_id']!, _toIdMeta));
    } else if (isInserting) {
      context.missing(_toIdMeta);
    }
    if (data.containsKey('distance_meters')) {
      context.handle(
          _distanceMetersMeta,
          distanceMeters.isAcceptableOrUnknown(
              data['distance_meters']!, _distanceMetersMeta));
    } else if (isInserting) {
      context.missing(_distanceMetersMeta);
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
          _computedAtMeta,
          computedAt.isAcceptableOrUnknown(
              data['computed_at']!, _computedAtMeta));
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromId, toId};
  @override
  DistanceMatrixRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DistanceMatrixRow(
      fromId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}from_id'])!,
      toId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}to_id'])!,
      distanceMeters: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}distance_meters'])!,
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      computedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}computed_at'])!,
    );
  }

  @override
  $DistanceMatrixTableTable createAlias(String alias) {
    return $DistanceMatrixTableTable(attachedDatabase, alias);
  }
}

class DistanceMatrixRow extends DataClass
    implements Insertable<DistanceMatrixRow> {
  final int fromId;
  final int toId;
  final int distanceMeters;
  final int durationSeconds;
  final int computedAt;
  const DistanceMatrixRow(
      {required this.fromId,
      required this.toId,
      required this.distanceMeters,
      required this.durationSeconds,
      required this.computedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_id'] = Variable<int>(fromId);
    map['to_id'] = Variable<int>(toId);
    map['distance_meters'] = Variable<int>(distanceMeters);
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['computed_at'] = Variable<int>(computedAt);
    return map;
  }

  DistanceMatrixTableCompanion toCompanion(bool nullToAbsent) {
    return DistanceMatrixTableCompanion(
      fromId: Value(fromId),
      toId: Value(toId),
      distanceMeters: Value(distanceMeters),
      durationSeconds: Value(durationSeconds),
      computedAt: Value(computedAt),
    );
  }

  factory DistanceMatrixRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DistanceMatrixRow(
      fromId: serializer.fromJson<int>(json['fromId']),
      toId: serializer.fromJson<int>(json['toId']),
      distanceMeters: serializer.fromJson<int>(json['distanceMeters']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      computedAt: serializer.fromJson<int>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromId': serializer.toJson<int>(fromId),
      'toId': serializer.toJson<int>(toId),
      'distanceMeters': serializer.toJson<int>(distanceMeters),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'computedAt': serializer.toJson<int>(computedAt),
    };
  }

  DistanceMatrixRow copyWith(
          {int? fromId,
          int? toId,
          int? distanceMeters,
          int? durationSeconds,
          int? computedAt}) =>
      DistanceMatrixRow(
        fromId: fromId ?? this.fromId,
        toId: toId ?? this.toId,
        distanceMeters: distanceMeters ?? this.distanceMeters,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        computedAt: computedAt ?? this.computedAt,
      );
  DistanceMatrixRow copyWithCompanion(DistanceMatrixTableCompanion data) {
    return DistanceMatrixRow(
      fromId: data.fromId.present ? data.fromId.value : this.fromId,
      toId: data.toId.present ? data.toId.value : this.toId,
      distanceMeters: data.distanceMeters.present
          ? data.distanceMeters.value
          : this.distanceMeters,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      computedAt:
          data.computedAt.present ? data.computedAt.value : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DistanceMatrixRow(')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(fromId, toId, distanceMeters, durationSeconds, computedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DistanceMatrixRow &&
          other.fromId == this.fromId &&
          other.toId == this.toId &&
          other.distanceMeters == this.distanceMeters &&
          other.durationSeconds == this.durationSeconds &&
          other.computedAt == this.computedAt);
}

class DistanceMatrixTableCompanion extends UpdateCompanion<DistanceMatrixRow> {
  final Value<int> fromId;
  final Value<int> toId;
  final Value<int> distanceMeters;
  final Value<int> durationSeconds;
  final Value<int> computedAt;
  final Value<int> rowid;
  const DistanceMatrixTableCompanion({
    this.fromId = const Value.absent(),
    this.toId = const Value.absent(),
    this.distanceMeters = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DistanceMatrixTableCompanion.insert({
    required int fromId,
    required int toId,
    required int distanceMeters,
    required int durationSeconds,
    required int computedAt,
    this.rowid = const Value.absent(),
  })  : fromId = Value(fromId),
        toId = Value(toId),
        distanceMeters = Value(distanceMeters),
        durationSeconds = Value(durationSeconds),
        computedAt = Value(computedAt);
  static Insertable<DistanceMatrixRow> custom({
    Expression<int>? fromId,
    Expression<int>? toId,
    Expression<int>? distanceMeters,
    Expression<int>? durationSeconds,
    Expression<int>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromId != null) 'from_id': fromId,
      if (toId != null) 'to_id': toId,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DistanceMatrixTableCompanion copyWith(
      {Value<int>? fromId,
      Value<int>? toId,
      Value<int>? distanceMeters,
      Value<int>? durationSeconds,
      Value<int>? computedAt,
      Value<int>? rowid}) {
    return DistanceMatrixTableCompanion(
      fromId: fromId ?? this.fromId,
      toId: toId ?? this.toId,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      computedAt: computedAt ?? this.computedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromId.present) {
      map['from_id'] = Variable<int>(fromId.value);
    }
    if (toId.present) {
      map['to_id'] = Variable<int>(toId.value);
    }
    if (distanceMeters.present) {
      map['distance_meters'] = Variable<int>(distanceMeters.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<int>(computedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DistanceMatrixTableCompanion(')
          ..write('fromId: $fromId, ')
          ..write('toId: $toId, ')
          ..write('distanceMeters: $distanceMeters, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SpeciesTableTable extends SpeciesTable
    with TableInfo<$SpeciesTableTable, SpeciesRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SpeciesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _iconKeyMeta =
      const VerificationMeta('iconKey');
  @override
  late final GeneratedColumn<String> iconKey = GeneratedColumn<String>(
      'icon_key', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, iconKey, archivedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'species';
  @override
  VerificationContext validateIntegrity(Insertable<SpeciesRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon_key')) {
      context.handle(_iconKeyMeta,
          iconKey.isAcceptableOrUnknown(data['icon_key']!, _iconKeyMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SpeciesRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SpeciesRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      iconKey: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}icon_key']),
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}archived_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $SpeciesTableTable createAlias(String alias) {
    return $SpeciesTableTable(attachedDatabase, alias);
  }
}

class SpeciesRow extends DataClass implements Insertable<SpeciesRow> {
  final int id;
  final String name;
  final String? iconKey;
  final int? archivedAt;
  final int createdAt;
  const SpeciesRow(
      {required this.id,
      required this.name,
      this.iconKey,
      this.archivedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || iconKey != null) {
      map['icon_key'] = Variable<String>(iconKey);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  SpeciesTableCompanion toCompanion(bool nullToAbsent) {
    return SpeciesTableCompanion(
      id: Value(id),
      name: Value(name),
      iconKey: iconKey == null && nullToAbsent
          ? const Value.absent()
          : Value(iconKey),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory SpeciesRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SpeciesRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      iconKey: serializer.fromJson<String?>(json['iconKey']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'iconKey': serializer.toJson<String?>(iconKey),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  SpeciesRow copyWith(
          {int? id,
          String? name,
          Value<String?> iconKey = const Value.absent(),
          Value<int?> archivedAt = const Value.absent(),
          int? createdAt}) =>
      SpeciesRow(
        id: id ?? this.id,
        name: name ?? this.name,
        iconKey: iconKey.present ? iconKey.value : this.iconKey,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  SpeciesRow copyWithCompanion(SpeciesTableCompanion data) {
    return SpeciesRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      iconKey: data.iconKey.present ? data.iconKey.value : this.iconKey,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, iconKey, archivedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SpeciesRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.iconKey == this.iconKey &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class SpeciesTableCompanion extends UpdateCompanion<SpeciesRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> iconKey;
  final Value<int?> archivedAt;
  final Value<int> createdAt;
  const SpeciesTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.iconKey = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  SpeciesTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.iconKey = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required int createdAt,
  })  : name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<SpeciesRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? iconKey,
    Expression<int>? archivedAt,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (iconKey != null) 'icon_key': iconKey,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  SpeciesTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<String?>? iconKey,
      Value<int?>? archivedAt,
      Value<int>? createdAt}) {
    return SpeciesTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (iconKey.present) {
      map['icon_key'] = Variable<String>(iconKey.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SpeciesTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('iconKey: $iconKey, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AnimalCategoriesTableTable extends AnimalCategoriesTable
    with TableInfo<$AnimalCategoriesTableTable, AnimalCategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AnimalCategoriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _speciesIdMeta =
      const VerificationMeta('speciesId');
  @override
  late final GeneratedColumn<int> speciesId = GeneratedColumn<int>(
      'species_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES species (id) ON DELETE CASCADE'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, speciesId, name, archivedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'animal_categories';
  @override
  VerificationContext validateIntegrity(Insertable<AnimalCategoryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('species_id')) {
      context.handle(_speciesIdMeta,
          speciesId.isAcceptableOrUnknown(data['species_id']!, _speciesIdMeta));
    } else if (isInserting) {
      context.missing(_speciesIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AnimalCategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AnimalCategoryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      speciesId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}species_id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}archived_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $AnimalCategoriesTableTable createAlias(String alias) {
    return $AnimalCategoriesTableTable(attachedDatabase, alias);
  }
}

class AnimalCategoryRow extends DataClass
    implements Insertable<AnimalCategoryRow> {
  final int id;
  final int speciesId;
  final String name;
  final int? archivedAt;
  final int createdAt;
  const AnimalCategoryRow(
      {required this.id,
      required this.speciesId,
      required this.name,
      this.archivedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['species_id'] = Variable<int>(speciesId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  AnimalCategoriesTableCompanion toCompanion(bool nullToAbsent) {
    return AnimalCategoriesTableCompanion(
      id: Value(id),
      speciesId: Value(speciesId),
      name: Value(name),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory AnimalCategoryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AnimalCategoryRow(
      id: serializer.fromJson<int>(json['id']),
      speciesId: serializer.fromJson<int>(json['speciesId']),
      name: serializer.fromJson<String>(json['name']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'speciesId': serializer.toJson<int>(speciesId),
      'name': serializer.toJson<String>(name),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  AnimalCategoryRow copyWith(
          {int? id,
          int? speciesId,
          String? name,
          Value<int?> archivedAt = const Value.absent(),
          int? createdAt}) =>
      AnimalCategoryRow(
        id: id ?? this.id,
        speciesId: speciesId ?? this.speciesId,
        name: name ?? this.name,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  AnimalCategoryRow copyWithCompanion(AnimalCategoriesTableCompanion data) {
    return AnimalCategoryRow(
      id: data.id.present ? data.id.value : this.id,
      speciesId: data.speciesId.present ? data.speciesId.value : this.speciesId,
      name: data.name.present ? data.name.value : this.name,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AnimalCategoryRow(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('name: $name, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, speciesId, name, archivedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AnimalCategoryRow &&
          other.id == this.id &&
          other.speciesId == this.speciesId &&
          other.name == this.name &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class AnimalCategoriesTableCompanion
    extends UpdateCompanion<AnimalCategoryRow> {
  final Value<int> id;
  final Value<int> speciesId;
  final Value<String> name;
  final Value<int?> archivedAt;
  final Value<int> createdAt;
  const AnimalCategoriesTableCompanion({
    this.id = const Value.absent(),
    this.speciesId = const Value.absent(),
    this.name = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AnimalCategoriesTableCompanion.insert({
    this.id = const Value.absent(),
    required int speciesId,
    required String name,
    this.archivedAt = const Value.absent(),
    required int createdAt,
  })  : speciesId = Value(speciesId),
        name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<AnimalCategoryRow> custom({
    Expression<int>? id,
    Expression<int>? speciesId,
    Expression<String>? name,
    Expression<int>? archivedAt,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (speciesId != null) 'species_id': speciesId,
      if (name != null) 'name': name,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AnimalCategoriesTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? speciesId,
      Value<String>? name,
      Value<int?>? archivedAt,
      Value<int>? createdAt}) {
    return AnimalCategoriesTableCompanion(
      id: id ?? this.id,
      speciesId: speciesId ?? this.speciesId,
      name: name ?? this.name,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (speciesId.present) {
      map['species_id'] = Variable<int>(speciesId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AnimalCategoriesTableCompanion(')
          ..write('id: $id, ')
          ..write('speciesId: $speciesId, ')
          ..write('name: $name, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ToursTableTable extends ToursTable
    with TableInfo<$ToursTableTable, TourRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ToursTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _plannedDateMeta =
      const VerificationMeta('plannedDate');
  @override
  late final GeneratedColumn<int> plannedDate = GeneratedColumn<int>(
      'planned_date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _startTimeMinutesMeta =
      const VerificationMeta('startTimeMinutes');
  @override
  late final GeneratedColumn<int> startTimeMinutes = GeneratedColumn<int>(
      'start_time_minutes', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _totalDistanceMetersMeta =
      const VerificationMeta('totalDistanceMeters');
  @override
  late final GeneratedColumn<int> totalDistanceMeters = GeneratedColumn<int>(
      'total_distance_meters', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalDriveSecondsMeta =
      const VerificationMeta('totalDriveSeconds');
  @override
  late final GeneratedColumn<int> totalDriveSeconds = GeneratedColumn<int>(
      'total_drive_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _totalTravelFeeCentsMeta =
      const VerificationMeta('totalTravelFeeCents');
  @override
  late final GeneratedColumn<int> totalTravelFeeCents = GeneratedColumn<int>(
      'total_travel_fee_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
      'notes', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _routeGeometryMeta =
      const VerificationMeta('routeGeometry');
  @override
  late final GeneratedColumn<String> routeGeometry = GeneratedColumn<String>(
      'route_geometry', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        plannedDate,
        startTimeMinutes,
        status,
        totalDistanceMeters,
        totalDriveSeconds,
        totalTravelFeeCents,
        notes,
        completedAt,
        createdAt,
        routeGeometry
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tours';
  @override
  VerificationContext validateIntegrity(Insertable<TourRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('planned_date')) {
      context.handle(
          _plannedDateMeta,
          plannedDate.isAcceptableOrUnknown(
              data['planned_date']!, _plannedDateMeta));
    } else if (isInserting) {
      context.missing(_plannedDateMeta);
    }
    if (data.containsKey('start_time_minutes')) {
      context.handle(
          _startTimeMinutesMeta,
          startTimeMinutes.isAcceptableOrUnknown(
              data['start_time_minutes']!, _startTimeMinutesMeta));
    } else if (isInserting) {
      context.missing(_startTimeMinutesMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('total_distance_meters')) {
      context.handle(
          _totalDistanceMetersMeta,
          totalDistanceMeters.isAcceptableOrUnknown(
              data['total_distance_meters']!, _totalDistanceMetersMeta));
    } else if (isInserting) {
      context.missing(_totalDistanceMetersMeta);
    }
    if (data.containsKey('total_drive_seconds')) {
      context.handle(
          _totalDriveSecondsMeta,
          totalDriveSeconds.isAcceptableOrUnknown(
              data['total_drive_seconds']!, _totalDriveSecondsMeta));
    } else if (isInserting) {
      context.missing(_totalDriveSecondsMeta);
    }
    if (data.containsKey('total_travel_fee_cents')) {
      context.handle(
          _totalTravelFeeCentsMeta,
          totalTravelFeeCents.isAcceptableOrUnknown(
              data['total_travel_fee_cents']!, _totalTravelFeeCentsMeta));
    } else if (isInserting) {
      context.missing(_totalTravelFeeCentsMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
          _notesMeta, notes.isAcceptableOrUnknown(data['notes']!, _notesMeta));
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('route_geometry')) {
      context.handle(
          _routeGeometryMeta,
          routeGeometry.isAcceptableOrUnknown(
              data['route_geometry']!, _routeGeometryMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TourRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TourRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      plannedDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}planned_date'])!,
      startTimeMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}start_time_minutes'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
      totalDistanceMeters: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_distance_meters'])!,
      totalDriveSeconds: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_drive_seconds'])!,
      totalTravelFeeCents: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}total_travel_fee_cents'])!,
      notes: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}notes']),
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      routeGeometry: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}route_geometry']),
    );
  }

  @override
  $ToursTableTable createAlias(String alias) {
    return $ToursTableTable(attachedDatabase, alias);
  }
}

class TourRow extends DataClass implements Insertable<TourRow> {
  final int id;
  final int plannedDate;
  final int startTimeMinutes;
  final String status;
  final int totalDistanceMeters;
  final int totalDriveSeconds;
  final int totalTravelFeeCents;
  final String? notes;
  final int? completedAt;
  final int createdAt;

  /// Polyline ORS de la tournée — JSON `[[lat, lon], ...]`. Nullable :
  /// les tournées créées sans réseau (ou avant cette feature) tombent en
  /// fallback "lignes droites" côté UI.
  final String? routeGeometry;
  const TourRow(
      {required this.id,
      required this.plannedDate,
      required this.startTimeMinutes,
      required this.status,
      required this.totalDistanceMeters,
      required this.totalDriveSeconds,
      required this.totalTravelFeeCents,
      this.notes,
      this.completedAt,
      required this.createdAt,
      this.routeGeometry});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['planned_date'] = Variable<int>(plannedDate);
    map['start_time_minutes'] = Variable<int>(startTimeMinutes);
    map['status'] = Variable<String>(status);
    map['total_distance_meters'] = Variable<int>(totalDistanceMeters);
    map['total_drive_seconds'] = Variable<int>(totalDriveSeconds);
    map['total_travel_fee_cents'] = Variable<int>(totalTravelFeeCents);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    if (!nullToAbsent || routeGeometry != null) {
      map['route_geometry'] = Variable<String>(routeGeometry);
    }
    return map;
  }

  ToursTableCompanion toCompanion(bool nullToAbsent) {
    return ToursTableCompanion(
      id: Value(id),
      plannedDate: Value(plannedDate),
      startTimeMinutes: Value(startTimeMinutes),
      status: Value(status),
      totalDistanceMeters: Value(totalDistanceMeters),
      totalDriveSeconds: Value(totalDriveSeconds),
      totalTravelFeeCents: Value(totalTravelFeeCents),
      notes:
          notes == null && nullToAbsent ? const Value.absent() : Value(notes),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
      routeGeometry: routeGeometry == null && nullToAbsent
          ? const Value.absent()
          : Value(routeGeometry),
    );
  }

  factory TourRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TourRow(
      id: serializer.fromJson<int>(json['id']),
      plannedDate: serializer.fromJson<int>(json['plannedDate']),
      startTimeMinutes: serializer.fromJson<int>(json['startTimeMinutes']),
      status: serializer.fromJson<String>(json['status']),
      totalDistanceMeters:
          serializer.fromJson<int>(json['totalDistanceMeters']),
      totalDriveSeconds: serializer.fromJson<int>(json['totalDriveSeconds']),
      totalTravelFeeCents:
          serializer.fromJson<int>(json['totalTravelFeeCents']),
      notes: serializer.fromJson<String?>(json['notes']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      routeGeometry: serializer.fromJson<String?>(json['routeGeometry']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'plannedDate': serializer.toJson<int>(plannedDate),
      'startTimeMinutes': serializer.toJson<int>(startTimeMinutes),
      'status': serializer.toJson<String>(status),
      'totalDistanceMeters': serializer.toJson<int>(totalDistanceMeters),
      'totalDriveSeconds': serializer.toJson<int>(totalDriveSeconds),
      'totalTravelFeeCents': serializer.toJson<int>(totalTravelFeeCents),
      'notes': serializer.toJson<String?>(notes),
      'completedAt': serializer.toJson<int?>(completedAt),
      'createdAt': serializer.toJson<int>(createdAt),
      'routeGeometry': serializer.toJson<String?>(routeGeometry),
    };
  }

  TourRow copyWith(
          {int? id,
          int? plannedDate,
          int? startTimeMinutes,
          String? status,
          int? totalDistanceMeters,
          int? totalDriveSeconds,
          int? totalTravelFeeCents,
          Value<String?> notes = const Value.absent(),
          Value<int?> completedAt = const Value.absent(),
          int? createdAt,
          Value<String?> routeGeometry = const Value.absent()}) =>
      TourRow(
        id: id ?? this.id,
        plannedDate: plannedDate ?? this.plannedDate,
        startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
        status: status ?? this.status,
        totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
        totalDriveSeconds: totalDriveSeconds ?? this.totalDriveSeconds,
        totalTravelFeeCents: totalTravelFeeCents ?? this.totalTravelFeeCents,
        notes: notes.present ? notes.value : this.notes,
        completedAt: completedAt.present ? completedAt.value : this.completedAt,
        createdAt: createdAt ?? this.createdAt,
        routeGeometry:
            routeGeometry.present ? routeGeometry.value : this.routeGeometry,
      );
  TourRow copyWithCompanion(ToursTableCompanion data) {
    return TourRow(
      id: data.id.present ? data.id.value : this.id,
      plannedDate:
          data.plannedDate.present ? data.plannedDate.value : this.plannedDate,
      startTimeMinutes: data.startTimeMinutes.present
          ? data.startTimeMinutes.value
          : this.startTimeMinutes,
      status: data.status.present ? data.status.value : this.status,
      totalDistanceMeters: data.totalDistanceMeters.present
          ? data.totalDistanceMeters.value
          : this.totalDistanceMeters,
      totalDriveSeconds: data.totalDriveSeconds.present
          ? data.totalDriveSeconds.value
          : this.totalDriveSeconds,
      totalTravelFeeCents: data.totalTravelFeeCents.present
          ? data.totalTravelFeeCents.value
          : this.totalTravelFeeCents,
      notes: data.notes.present ? data.notes.value : this.notes,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      routeGeometry: data.routeGeometry.present
          ? data.routeGeometry.value
          : this.routeGeometry,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TourRow(')
          ..write('id: $id, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('status: $status, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('totalDriveSeconds: $totalDriveSeconds, ')
          ..write('totalTravelFeeCents: $totalTravelFeeCents, ')
          ..write('notes: $notes, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('routeGeometry: $routeGeometry')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      plannedDate,
      startTimeMinutes,
      status,
      totalDistanceMeters,
      totalDriveSeconds,
      totalTravelFeeCents,
      notes,
      completedAt,
      createdAt,
      routeGeometry);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TourRow &&
          other.id == this.id &&
          other.plannedDate == this.plannedDate &&
          other.startTimeMinutes == this.startTimeMinutes &&
          other.status == this.status &&
          other.totalDistanceMeters == this.totalDistanceMeters &&
          other.totalDriveSeconds == this.totalDriveSeconds &&
          other.totalTravelFeeCents == this.totalTravelFeeCents &&
          other.notes == this.notes &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt &&
          other.routeGeometry == this.routeGeometry);
}

class ToursTableCompanion extends UpdateCompanion<TourRow> {
  final Value<int> id;
  final Value<int> plannedDate;
  final Value<int> startTimeMinutes;
  final Value<String> status;
  final Value<int> totalDistanceMeters;
  final Value<int> totalDriveSeconds;
  final Value<int> totalTravelFeeCents;
  final Value<String?> notes;
  final Value<int?> completedAt;
  final Value<int> createdAt;
  final Value<String?> routeGeometry;
  const ToursTableCompanion({
    this.id = const Value.absent(),
    this.plannedDate = const Value.absent(),
    this.startTimeMinutes = const Value.absent(),
    this.status = const Value.absent(),
    this.totalDistanceMeters = const Value.absent(),
    this.totalDriveSeconds = const Value.absent(),
    this.totalTravelFeeCents = const Value.absent(),
    this.notes = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.routeGeometry = const Value.absent(),
  });
  ToursTableCompanion.insert({
    this.id = const Value.absent(),
    required int plannedDate,
    required int startTimeMinutes,
    required String status,
    required int totalDistanceMeters,
    required int totalDriveSeconds,
    required int totalTravelFeeCents,
    this.notes = const Value.absent(),
    this.completedAt = const Value.absent(),
    required int createdAt,
    this.routeGeometry = const Value.absent(),
  })  : plannedDate = Value(plannedDate),
        startTimeMinutes = Value(startTimeMinutes),
        status = Value(status),
        totalDistanceMeters = Value(totalDistanceMeters),
        totalDriveSeconds = Value(totalDriveSeconds),
        totalTravelFeeCents = Value(totalTravelFeeCents),
        createdAt = Value(createdAt);
  static Insertable<TourRow> custom({
    Expression<int>? id,
    Expression<int>? plannedDate,
    Expression<int>? startTimeMinutes,
    Expression<String>? status,
    Expression<int>? totalDistanceMeters,
    Expression<int>? totalDriveSeconds,
    Expression<int>? totalTravelFeeCents,
    Expression<String>? notes,
    Expression<int>? completedAt,
    Expression<int>? createdAt,
    Expression<String>? routeGeometry,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (plannedDate != null) 'planned_date': plannedDate,
      if (startTimeMinutes != null) 'start_time_minutes': startTimeMinutes,
      if (status != null) 'status': status,
      if (totalDistanceMeters != null)
        'total_distance_meters': totalDistanceMeters,
      if (totalDriveSeconds != null) 'total_drive_seconds': totalDriveSeconds,
      if (totalTravelFeeCents != null)
        'total_travel_fee_cents': totalTravelFeeCents,
      if (notes != null) 'notes': notes,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (routeGeometry != null) 'route_geometry': routeGeometry,
    });
  }

  ToursTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? plannedDate,
      Value<int>? startTimeMinutes,
      Value<String>? status,
      Value<int>? totalDistanceMeters,
      Value<int>? totalDriveSeconds,
      Value<int>? totalTravelFeeCents,
      Value<String?>? notes,
      Value<int?>? completedAt,
      Value<int>? createdAt,
      Value<String?>? routeGeometry}) {
    return ToursTableCompanion(
      id: id ?? this.id,
      plannedDate: plannedDate ?? this.plannedDate,
      startTimeMinutes: startTimeMinutes ?? this.startTimeMinutes,
      status: status ?? this.status,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalDriveSeconds: totalDriveSeconds ?? this.totalDriveSeconds,
      totalTravelFeeCents: totalTravelFeeCents ?? this.totalTravelFeeCents,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      routeGeometry: routeGeometry ?? this.routeGeometry,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (plannedDate.present) {
      map['planned_date'] = Variable<int>(plannedDate.value);
    }
    if (startTimeMinutes.present) {
      map['start_time_minutes'] = Variable<int>(startTimeMinutes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (totalDistanceMeters.present) {
      map['total_distance_meters'] = Variable<int>(totalDistanceMeters.value);
    }
    if (totalDriveSeconds.present) {
      map['total_drive_seconds'] = Variable<int>(totalDriveSeconds.value);
    }
    if (totalTravelFeeCents.present) {
      map['total_travel_fee_cents'] = Variable<int>(totalTravelFeeCents.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (routeGeometry.present) {
      map['route_geometry'] = Variable<String>(routeGeometry.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ToursTableCompanion(')
          ..write('id: $id, ')
          ..write('plannedDate: $plannedDate, ')
          ..write('startTimeMinutes: $startTimeMinutes, ')
          ..write('status: $status, ')
          ..write('totalDistanceMeters: $totalDistanceMeters, ')
          ..write('totalDriveSeconds: $totalDriveSeconds, ')
          ..write('totalTravelFeeCents: $totalTravelFeeCents, ')
          ..write('notes: $notes, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('routeGeometry: $routeGeometry')
          ..write(')'))
        .toString();
  }
}

class $TourStopsTableTable extends TourStopsTable
    with TableInfo<$TourStopsTableTable, TourStopRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TourStopsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _tourIdMeta = const VerificationMeta('tourId');
  @override
  late final GeneratedColumn<int> tourId = GeneratedColumn<int>(
      'tour_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES tours (id) ON DELETE CASCADE'));
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
      'client_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES clients (id) ON DELETE SET NULL'));
  static const VerificationMeta _clientNameSnapshotMeta =
      const VerificationMeta('clientNameSnapshot');
  @override
  late final GeneratedColumn<String> clientNameSnapshot =
      GeneratedColumn<String>('client_name_snapshot', aliasedName, false,
          type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _orderIndexMeta =
      const VerificationMeta('orderIndex');
  @override
  late final GeneratedColumn<int> orderIndex = GeneratedColumn<int>(
      'order_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _estimatedArrivalMinutesMeta =
      const VerificationMeta('estimatedArrivalMinutes');
  @override
  late final GeneratedColumn<int> estimatedArrivalMinutes =
      GeneratedColumn<int>('estimated_arrival_minutes', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _estimatedDepartureMinutesMeta =
      const VerificationMeta('estimatedDepartureMinutes');
  @override
  late final GeneratedColumn<int> estimatedDepartureMinutes =
      GeneratedColumn<int>('estimated_departure_minutes', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<TourStopPrestation>, String>
      plannedPrestations = GeneratedColumn<String>(
              'planned_prestations', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<TourStopPrestation>>(
              $TourStopsTableTable.$converterplannedPrestations);
  @override
  late final GeneratedColumnWithTypeConverter<List<TourStopPrestation>?, String>
      actualPrestations = GeneratedColumn<String>(
              'actual_prestations', aliasedName, true,
              type: DriftSqlType.string, requiredDuringInsert: false)
          .withConverter<List<TourStopPrestation>?>(
              $TourStopsTableTable.$converteractualPrestationsn);
  static const VerificationMeta _interventionNoteMeta =
      const VerificationMeta('interventionNote');
  @override
  late final GeneratedColumn<String> interventionNote = GeneratedColumn<String>(
      'intervention_note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _feeShareCentsMeta =
      const VerificationMeta('feeShareCents');
  @override
  late final GeneratedColumn<int> feeShareCents = GeneratedColumn<int>(
      'fee_share_cents', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        tourId,
        clientId,
        clientNameSnapshot,
        orderIndex,
        estimatedArrivalMinutes,
        estimatedDepartureMinutes,
        plannedPrestations,
        actualPrestations,
        interventionNote,
        feeShareCents
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tour_stops';
  @override
  VerificationContext validateIntegrity(Insertable<TourStopRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('tour_id')) {
      context.handle(_tourIdMeta,
          tourId.isAcceptableOrUnknown(data['tour_id']!, _tourIdMeta));
    } else if (isInserting) {
      context.missing(_tourIdMeta);
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    }
    if (data.containsKey('client_name_snapshot')) {
      context.handle(
          _clientNameSnapshotMeta,
          clientNameSnapshot.isAcceptableOrUnknown(
              data['client_name_snapshot']!, _clientNameSnapshotMeta));
    } else if (isInserting) {
      context.missing(_clientNameSnapshotMeta);
    }
    if (data.containsKey('order_index')) {
      context.handle(
          _orderIndexMeta,
          orderIndex.isAcceptableOrUnknown(
              data['order_index']!, _orderIndexMeta));
    } else if (isInserting) {
      context.missing(_orderIndexMeta);
    }
    if (data.containsKey('estimated_arrival_minutes')) {
      context.handle(
          _estimatedArrivalMinutesMeta,
          estimatedArrivalMinutes.isAcceptableOrUnknown(
              data['estimated_arrival_minutes']!,
              _estimatedArrivalMinutesMeta));
    } else if (isInserting) {
      context.missing(_estimatedArrivalMinutesMeta);
    }
    if (data.containsKey('estimated_departure_minutes')) {
      context.handle(
          _estimatedDepartureMinutesMeta,
          estimatedDepartureMinutes.isAcceptableOrUnknown(
              data['estimated_departure_minutes']!,
              _estimatedDepartureMinutesMeta));
    } else if (isInserting) {
      context.missing(_estimatedDepartureMinutesMeta);
    }
    if (data.containsKey('intervention_note')) {
      context.handle(
          _interventionNoteMeta,
          interventionNote.isAcceptableOrUnknown(
              data['intervention_note']!, _interventionNoteMeta));
    }
    if (data.containsKey('fee_share_cents')) {
      context.handle(
          _feeShareCentsMeta,
          feeShareCents.isAcceptableOrUnknown(
              data['fee_share_cents']!, _feeShareCentsMeta));
    } else if (isInserting) {
      context.missing(_feeShareCentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TourStopRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TourStopRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      tourId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}tour_id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}client_id']),
      clientNameSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}client_name_snapshot'])!,
      orderIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}order_index'])!,
      estimatedArrivalMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}estimated_arrival_minutes'])!,
      estimatedDepartureMinutes: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}estimated_departure_minutes'])!,
      plannedPrestations: $TourStopsTableTable.$converterplannedPrestations
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}planned_prestations'])!),
      actualPrestations: $TourStopsTableTable.$converteractualPrestationsn
          .fromSql(attachedDatabase.typeMapping.read(DriftSqlType.string,
              data['${effectivePrefix}actual_prestations'])),
      interventionNote: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}intervention_note']),
      feeShareCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fee_share_cents'])!,
    );
  }

  @override
  $TourStopsTableTable createAlias(String alias) {
    return $TourStopsTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<TourStopPrestation>, String>
      $converterplannedPrestations = const TourStopPrestationListConverter();
  static TypeConverter<List<TourStopPrestation>, String>
      $converteractualPrestations = const TourStopPrestationListConverter();
  static TypeConverter<List<TourStopPrestation>?, String?>
      $converteractualPrestationsn =
      NullAwareTypeConverter.wrap($converteractualPrestations);
}

class TourStopRow extends DataClass implements Insertable<TourStopRow> {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final List<TourStopPrestation> plannedPrestations;
  final List<TourStopPrestation>? actualPrestations;
  final String? interventionNote;
  final int feeShareCents;
  const TourStopRow(
      {required this.id,
      required this.tourId,
      this.clientId,
      required this.clientNameSnapshot,
      required this.orderIndex,
      required this.estimatedArrivalMinutes,
      required this.estimatedDepartureMinutes,
      required this.plannedPrestations,
      this.actualPrestations,
      this.interventionNote,
      required this.feeShareCents});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['tour_id'] = Variable<int>(tourId);
    if (!nullToAbsent || clientId != null) {
      map['client_id'] = Variable<int>(clientId);
    }
    map['client_name_snapshot'] = Variable<String>(clientNameSnapshot);
    map['order_index'] = Variable<int>(orderIndex);
    map['estimated_arrival_minutes'] = Variable<int>(estimatedArrivalMinutes);
    map['estimated_departure_minutes'] =
        Variable<int>(estimatedDepartureMinutes);
    {
      map['planned_prestations'] = Variable<String>($TourStopsTableTable
          .$converterplannedPrestations
          .toSql(plannedPrestations));
    }
    if (!nullToAbsent || actualPrestations != null) {
      map['actual_prestations'] = Variable<String>($TourStopsTableTable
          .$converteractualPrestationsn
          .toSql(actualPrestations));
    }
    if (!nullToAbsent || interventionNote != null) {
      map['intervention_note'] = Variable<String>(interventionNote);
    }
    map['fee_share_cents'] = Variable<int>(feeShareCents);
    return map;
  }

  TourStopsTableCompanion toCompanion(bool nullToAbsent) {
    return TourStopsTableCompanion(
      id: Value(id),
      tourId: Value(tourId),
      clientId: clientId == null && nullToAbsent
          ? const Value.absent()
          : Value(clientId),
      clientNameSnapshot: Value(clientNameSnapshot),
      orderIndex: Value(orderIndex),
      estimatedArrivalMinutes: Value(estimatedArrivalMinutes),
      estimatedDepartureMinutes: Value(estimatedDepartureMinutes),
      plannedPrestations: Value(plannedPrestations),
      actualPrestations: actualPrestations == null && nullToAbsent
          ? const Value.absent()
          : Value(actualPrestations),
      interventionNote: interventionNote == null && nullToAbsent
          ? const Value.absent()
          : Value(interventionNote),
      feeShareCents: Value(feeShareCents),
    );
  }

  factory TourStopRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TourStopRow(
      id: serializer.fromJson<int>(json['id']),
      tourId: serializer.fromJson<int>(json['tourId']),
      clientId: serializer.fromJson<int?>(json['clientId']),
      clientNameSnapshot:
          serializer.fromJson<String>(json['clientNameSnapshot']),
      orderIndex: serializer.fromJson<int>(json['orderIndex']),
      estimatedArrivalMinutes:
          serializer.fromJson<int>(json['estimatedArrivalMinutes']),
      estimatedDepartureMinutes:
          serializer.fromJson<int>(json['estimatedDepartureMinutes']),
      plannedPrestations: serializer
          .fromJson<List<TourStopPrestation>>(json['plannedPrestations']),
      actualPrestations: serializer
          .fromJson<List<TourStopPrestation>?>(json['actualPrestations']),
      interventionNote: serializer.fromJson<String?>(json['interventionNote']),
      feeShareCents: serializer.fromJson<int>(json['feeShareCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'tourId': serializer.toJson<int>(tourId),
      'clientId': serializer.toJson<int?>(clientId),
      'clientNameSnapshot': serializer.toJson<String>(clientNameSnapshot),
      'orderIndex': serializer.toJson<int>(orderIndex),
      'estimatedArrivalMinutes':
          serializer.toJson<int>(estimatedArrivalMinutes),
      'estimatedDepartureMinutes':
          serializer.toJson<int>(estimatedDepartureMinutes),
      'plannedPrestations':
          serializer.toJson<List<TourStopPrestation>>(plannedPrestations),
      'actualPrestations':
          serializer.toJson<List<TourStopPrestation>?>(actualPrestations),
      'interventionNote': serializer.toJson<String?>(interventionNote),
      'feeShareCents': serializer.toJson<int>(feeShareCents),
    };
  }

  TourStopRow copyWith(
          {int? id,
          int? tourId,
          Value<int?> clientId = const Value.absent(),
          String? clientNameSnapshot,
          int? orderIndex,
          int? estimatedArrivalMinutes,
          int? estimatedDepartureMinutes,
          List<TourStopPrestation>? plannedPrestations,
          Value<List<TourStopPrestation>?> actualPrestations =
              const Value.absent(),
          Value<String?> interventionNote = const Value.absent(),
          int? feeShareCents}) =>
      TourStopRow(
        id: id ?? this.id,
        tourId: tourId ?? this.tourId,
        clientId: clientId.present ? clientId.value : this.clientId,
        clientNameSnapshot: clientNameSnapshot ?? this.clientNameSnapshot,
        orderIndex: orderIndex ?? this.orderIndex,
        estimatedArrivalMinutes:
            estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
        estimatedDepartureMinutes:
            estimatedDepartureMinutes ?? this.estimatedDepartureMinutes,
        plannedPrestations: plannedPrestations ?? this.plannedPrestations,
        actualPrestations: actualPrestations.present
            ? actualPrestations.value
            : this.actualPrestations,
        interventionNote: interventionNote.present
            ? interventionNote.value
            : this.interventionNote,
        feeShareCents: feeShareCents ?? this.feeShareCents,
      );
  TourStopRow copyWithCompanion(TourStopsTableCompanion data) {
    return TourStopRow(
      id: data.id.present ? data.id.value : this.id,
      tourId: data.tourId.present ? data.tourId.value : this.tourId,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      clientNameSnapshot: data.clientNameSnapshot.present
          ? data.clientNameSnapshot.value
          : this.clientNameSnapshot,
      orderIndex:
          data.orderIndex.present ? data.orderIndex.value : this.orderIndex,
      estimatedArrivalMinutes: data.estimatedArrivalMinutes.present
          ? data.estimatedArrivalMinutes.value
          : this.estimatedArrivalMinutes,
      estimatedDepartureMinutes: data.estimatedDepartureMinutes.present
          ? data.estimatedDepartureMinutes.value
          : this.estimatedDepartureMinutes,
      plannedPrestations: data.plannedPrestations.present
          ? data.plannedPrestations.value
          : this.plannedPrestations,
      actualPrestations: data.actualPrestations.present
          ? data.actualPrestations.value
          : this.actualPrestations,
      interventionNote: data.interventionNote.present
          ? data.interventionNote.value
          : this.interventionNote,
      feeShareCents: data.feeShareCents.present
          ? data.feeShareCents.value
          : this.feeShareCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TourStopRow(')
          ..write('id: $id, ')
          ..write('tourId: $tourId, ')
          ..write('clientId: $clientId, ')
          ..write('clientNameSnapshot: $clientNameSnapshot, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('estimatedArrivalMinutes: $estimatedArrivalMinutes, ')
          ..write('estimatedDepartureMinutes: $estimatedDepartureMinutes, ')
          ..write('plannedPrestations: $plannedPrestations, ')
          ..write('actualPrestations: $actualPrestations, ')
          ..write('interventionNote: $interventionNote, ')
          ..write('feeShareCents: $feeShareCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id,
      tourId,
      clientId,
      clientNameSnapshot,
      orderIndex,
      estimatedArrivalMinutes,
      estimatedDepartureMinutes,
      plannedPrestations,
      actualPrestations,
      interventionNote,
      feeShareCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TourStopRow &&
          other.id == this.id &&
          other.tourId == this.tourId &&
          other.clientId == this.clientId &&
          other.clientNameSnapshot == this.clientNameSnapshot &&
          other.orderIndex == this.orderIndex &&
          other.estimatedArrivalMinutes == this.estimatedArrivalMinutes &&
          other.estimatedDepartureMinutes == this.estimatedDepartureMinutes &&
          other.plannedPrestations == this.plannedPrestations &&
          other.actualPrestations == this.actualPrestations &&
          other.interventionNote == this.interventionNote &&
          other.feeShareCents == this.feeShareCents);
}

class TourStopsTableCompanion extends UpdateCompanion<TourStopRow> {
  final Value<int> id;
  final Value<int> tourId;
  final Value<int?> clientId;
  final Value<String> clientNameSnapshot;
  final Value<int> orderIndex;
  final Value<int> estimatedArrivalMinutes;
  final Value<int> estimatedDepartureMinutes;
  final Value<List<TourStopPrestation>> plannedPrestations;
  final Value<List<TourStopPrestation>?> actualPrestations;
  final Value<String?> interventionNote;
  final Value<int> feeShareCents;
  const TourStopsTableCompanion({
    this.id = const Value.absent(),
    this.tourId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientNameSnapshot = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.estimatedArrivalMinutes = const Value.absent(),
    this.estimatedDepartureMinutes = const Value.absent(),
    this.plannedPrestations = const Value.absent(),
    this.actualPrestations = const Value.absent(),
    this.interventionNote = const Value.absent(),
    this.feeShareCents = const Value.absent(),
  });
  TourStopsTableCompanion.insert({
    this.id = const Value.absent(),
    required int tourId,
    this.clientId = const Value.absent(),
    required String clientNameSnapshot,
    required int orderIndex,
    required int estimatedArrivalMinutes,
    required int estimatedDepartureMinutes,
    this.plannedPrestations = const Value.absent(),
    this.actualPrestations = const Value.absent(),
    this.interventionNote = const Value.absent(),
    required int feeShareCents,
  })  : tourId = Value(tourId),
        clientNameSnapshot = Value(clientNameSnapshot),
        orderIndex = Value(orderIndex),
        estimatedArrivalMinutes = Value(estimatedArrivalMinutes),
        estimatedDepartureMinutes = Value(estimatedDepartureMinutes),
        feeShareCents = Value(feeShareCents);
  static Insertable<TourStopRow> custom({
    Expression<int>? id,
    Expression<int>? tourId,
    Expression<int>? clientId,
    Expression<String>? clientNameSnapshot,
    Expression<int>? orderIndex,
    Expression<int>? estimatedArrivalMinutes,
    Expression<int>? estimatedDepartureMinutes,
    Expression<String>? plannedPrestations,
    Expression<String>? actualPrestations,
    Expression<String>? interventionNote,
    Expression<int>? feeShareCents,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (tourId != null) 'tour_id': tourId,
      if (clientId != null) 'client_id': clientId,
      if (clientNameSnapshot != null)
        'client_name_snapshot': clientNameSnapshot,
      if (orderIndex != null) 'order_index': orderIndex,
      if (estimatedArrivalMinutes != null)
        'estimated_arrival_minutes': estimatedArrivalMinutes,
      if (estimatedDepartureMinutes != null)
        'estimated_departure_minutes': estimatedDepartureMinutes,
      if (plannedPrestations != null) 'planned_prestations': plannedPrestations,
      if (actualPrestations != null) 'actual_prestations': actualPrestations,
      if (interventionNote != null) 'intervention_note': interventionNote,
      if (feeShareCents != null) 'fee_share_cents': feeShareCents,
    });
  }

  TourStopsTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? tourId,
      Value<int?>? clientId,
      Value<String>? clientNameSnapshot,
      Value<int>? orderIndex,
      Value<int>? estimatedArrivalMinutes,
      Value<int>? estimatedDepartureMinutes,
      Value<List<TourStopPrestation>>? plannedPrestations,
      Value<List<TourStopPrestation>?>? actualPrestations,
      Value<String?>? interventionNote,
      Value<int>? feeShareCents}) {
    return TourStopsTableCompanion(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      clientId: clientId ?? this.clientId,
      clientNameSnapshot: clientNameSnapshot ?? this.clientNameSnapshot,
      orderIndex: orderIndex ?? this.orderIndex,
      estimatedArrivalMinutes:
          estimatedArrivalMinutes ?? this.estimatedArrivalMinutes,
      estimatedDepartureMinutes:
          estimatedDepartureMinutes ?? this.estimatedDepartureMinutes,
      plannedPrestations: plannedPrestations ?? this.plannedPrestations,
      actualPrestations: actualPrestations ?? this.actualPrestations,
      interventionNote: interventionNote ?? this.interventionNote,
      feeShareCents: feeShareCents ?? this.feeShareCents,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (tourId.present) {
      map['tour_id'] = Variable<int>(tourId.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (clientNameSnapshot.present) {
      map['client_name_snapshot'] = Variable<String>(clientNameSnapshot.value);
    }
    if (orderIndex.present) {
      map['order_index'] = Variable<int>(orderIndex.value);
    }
    if (estimatedArrivalMinutes.present) {
      map['estimated_arrival_minutes'] =
          Variable<int>(estimatedArrivalMinutes.value);
    }
    if (estimatedDepartureMinutes.present) {
      map['estimated_departure_minutes'] =
          Variable<int>(estimatedDepartureMinutes.value);
    }
    if (plannedPrestations.present) {
      map['planned_prestations'] = Variable<String>($TourStopsTableTable
          .$converterplannedPrestations
          .toSql(plannedPrestations.value));
    }
    if (actualPrestations.present) {
      map['actual_prestations'] = Variable<String>($TourStopsTableTable
          .$converteractualPrestationsn
          .toSql(actualPrestations.value));
    }
    if (interventionNote.present) {
      map['intervention_note'] = Variable<String>(interventionNote.value);
    }
    if (feeShareCents.present) {
      map['fee_share_cents'] = Variable<int>(feeShareCents.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TourStopsTableCompanion(')
          ..write('id: $id, ')
          ..write('tourId: $tourId, ')
          ..write('clientId: $clientId, ')
          ..write('clientNameSnapshot: $clientNameSnapshot, ')
          ..write('orderIndex: $orderIndex, ')
          ..write('estimatedArrivalMinutes: $estimatedArrivalMinutes, ')
          ..write('estimatedDepartureMinutes: $estimatedDepartureMinutes, ')
          ..write('plannedPrestations: $plannedPrestations, ')
          ..write('actualPrestations: $actualPrestations, ')
          ..write('interventionNote: $interventionNote, ')
          ..write('feeShareCents: $feeShareCents')
          ..write(')'))
        .toString();
  }
}

class $ManualHistoryEntriesTableTable extends ManualHistoryEntriesTable
    with TableInfo<$ManualHistoryEntriesTableTable, ManualHistoryEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ManualHistoryEntriesTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _clientIdMeta =
      const VerificationMeta('clientId');
  @override
  late final GeneratedColumn<int> clientId = GeneratedColumn<int>(
      'client_id', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES clients (id) ON DELETE CASCADE'));
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<int> date = GeneratedColumn<int>(
      'date', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  late final GeneratedColumnWithTypeConverter<List<TourStopPrestation>, String>
      prestations = GeneratedColumn<String>('prestations', aliasedName, false,
              type: DriftSqlType.string,
              requiredDuringInsert: false,
              defaultValue: const Constant('[]'))
          .withConverter<List<TourStopPrestation>>(
              $ManualHistoryEntriesTableTable.$converterprestations);
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
      'note', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _updatedAtMeta =
      const VerificationMeta('updatedAt');
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
      'updated_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, clientId, date, prestations, note, createdAt, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_history_entries';
  @override
  VerificationContext validateIntegrity(
      Insertable<ManualHistoryEntryRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('client_id')) {
      context.handle(_clientIdMeta,
          clientId.isAcceptableOrUnknown(data['client_id']!, _clientIdMeta));
    } else if (isInserting) {
      context.missing(_clientIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
          _dateMeta, date.isAcceptableOrUnknown(data['date']!, _dateMeta));
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
          _noteMeta, note.isAcceptableOrUnknown(data['note']!, _noteMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(_updatedAtMeta,
          updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta));
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ManualHistoryEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualHistoryEntryRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      clientId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}client_id'])!,
      date: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}date'])!,
      prestations: $ManualHistoryEntriesTableTable.$converterprestations
          .fromSql(attachedDatabase.typeMapping.read(
              DriftSqlType.string, data['${effectivePrefix}prestations'])!),
      note: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}note']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
      updatedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}updated_at'])!,
    );
  }

  @override
  $ManualHistoryEntriesTableTable createAlias(String alias) {
    return $ManualHistoryEntriesTableTable(attachedDatabase, alias);
  }

  static TypeConverter<List<TourStopPrestation>, String> $converterprestations =
      const TourStopPrestationListConverter();
}

class ManualHistoryEntryRow extends DataClass
    implements Insertable<ManualHistoryEntryRow> {
  final int id;
  final int clientId;
  final int date;
  final List<TourStopPrestation> prestations;
  final String? note;
  final int createdAt;
  final int updatedAt;
  const ManualHistoryEntryRow(
      {required this.id,
      required this.clientId,
      required this.date,
      required this.prestations,
      this.note,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['client_id'] = Variable<int>(clientId);
    map['date'] = Variable<int>(date);
    {
      map['prestations'] = Variable<String>($ManualHistoryEntriesTableTable
          .$converterprestations
          .toSql(prestations));
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ManualHistoryEntriesTableCompanion toCompanion(bool nullToAbsent) {
    return ManualHistoryEntriesTableCompanion(
      id: Value(id),
      clientId: Value(clientId),
      date: Value(date),
      prestations: Value(prestations),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ManualHistoryEntryRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualHistoryEntryRow(
      id: serializer.fromJson<int>(json['id']),
      clientId: serializer.fromJson<int>(json['clientId']),
      date: serializer.fromJson<int>(json['date']),
      prestations:
          serializer.fromJson<List<TourStopPrestation>>(json['prestations']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'clientId': serializer.toJson<int>(clientId),
      'date': serializer.toJson<int>(date),
      'prestations': serializer.toJson<List<TourStopPrestation>>(prestations),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ManualHistoryEntryRow copyWith(
          {int? id,
          int? clientId,
          int? date,
          List<TourStopPrestation>? prestations,
          Value<String?> note = const Value.absent(),
          int? createdAt,
          int? updatedAt}) =>
      ManualHistoryEntryRow(
        id: id ?? this.id,
        clientId: clientId ?? this.clientId,
        date: date ?? this.date,
        prestations: prestations ?? this.prestations,
        note: note.present ? note.value : this.note,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  ManualHistoryEntryRow copyWithCompanion(
      ManualHistoryEntriesTableCompanion data) {
    return ManualHistoryEntryRow(
      id: data.id.present ? data.id.value : this.id,
      clientId: data.clientId.present ? data.clientId.value : this.clientId,
      date: data.date.present ? data.date.value : this.date,
      prestations:
          data.prestations.present ? data.prestations.value : this.prestations,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualHistoryEntryRow(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('date: $date, ')
          ..write('prestations: $prestations, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, clientId, date, prestations, note, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualHistoryEntryRow &&
          other.id == this.id &&
          other.clientId == this.clientId &&
          other.date == this.date &&
          other.prestations == this.prestations &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ManualHistoryEntriesTableCompanion
    extends UpdateCompanion<ManualHistoryEntryRow> {
  final Value<int> id;
  final Value<int> clientId;
  final Value<int> date;
  final Value<List<TourStopPrestation>> prestations;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ManualHistoryEntriesTableCompanion({
    this.id = const Value.absent(),
    this.clientId = const Value.absent(),
    this.date = const Value.absent(),
    this.prestations = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ManualHistoryEntriesTableCompanion.insert({
    this.id = const Value.absent(),
    required int clientId,
    required int date,
    this.prestations = const Value.absent(),
    this.note = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  })  : clientId = Value(clientId),
        date = Value(date),
        createdAt = Value(createdAt),
        updatedAt = Value(updatedAt);
  static Insertable<ManualHistoryEntryRow> custom({
    Expression<int>? id,
    Expression<int>? clientId,
    Expression<int>? date,
    Expression<String>? prestations,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (clientId != null) 'client_id': clientId,
      if (date != null) 'date': date,
      if (prestations != null) 'prestations': prestations,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ManualHistoryEntriesTableCompanion copyWith(
      {Value<int>? id,
      Value<int>? clientId,
      Value<int>? date,
      Value<List<TourStopPrestation>>? prestations,
      Value<String?>? note,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return ManualHistoryEntriesTableCompanion(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      date: date ?? this.date,
      prestations: prestations ?? this.prestations,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (clientId.present) {
      map['client_id'] = Variable<int>(clientId.value);
    }
    if (date.present) {
      map['date'] = Variable<int>(date.value);
    }
    if (prestations.present) {
      map['prestations'] = Variable<String>($ManualHistoryEntriesTableTable
          .$converterprestations
          .toSql(prestations.value));
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualHistoryEntriesTableCompanion(')
          ..write('id: $id, ')
          ..write('clientId: $clientId, ')
          ..write('date: $date, ')
          ..write('prestations: $prestations, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class $PrestationsTableTable extends PrestationsTable
    with TableInfo<$PrestationsTableTable, PrestationRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrestationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _priceCentsMeta =
      const VerificationMeta('priceCents');
  @override
  late final GeneratedColumn<int> priceCents = GeneratedColumn<int>(
      'price_cents', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _minutesMeta =
      const VerificationMeta('minutes');
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
      'minutes', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _categoryIdMeta =
      const VerificationMeta('categoryId');
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
      'category_id', aliasedName, true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES animal_categories (id) ON DELETE SET NULL'));
  static const VerificationMeta _archivedAtMeta =
      const VerificationMeta('archivedAt');
  @override
  late final GeneratedColumn<int> archivedAt = GeneratedColumn<int>(
      'archived_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
      'created_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, priceCents, minutes, categoryId, archivedAt, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prestations';
  @override
  VerificationContext validateIntegrity(Insertable<PrestationRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('price_cents')) {
      context.handle(
          _priceCentsMeta,
          priceCents.isAcceptableOrUnknown(
              data['price_cents']!, _priceCentsMeta));
    }
    if (data.containsKey('minutes')) {
      context.handle(_minutesMeta,
          minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
          _categoryIdMeta,
          categoryId.isAcceptableOrUnknown(
              data['category_id']!, _categoryIdMeta));
    }
    if (data.containsKey('archived_at')) {
      context.handle(
          _archivedAtMeta,
          archivedAt.isAcceptableOrUnknown(
              data['archived_at']!, _archivedAtMeta));
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PrestationRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrestationRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      priceCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}price_cents']),
      minutes: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}minutes']),
      categoryId: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}category_id']),
      archivedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}archived_at']),
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at'])!,
    );
  }

  @override
  $PrestationsTableTable createAlias(String alias) {
    return $PrestationsTableTable(attachedDatabase, alias);
  }
}

class PrestationRow extends DataClass implements Insertable<PrestationRow> {
  final int id;
  final String name;
  final int? priceCents;
  final int? minutes;
  final int? categoryId;
  final int? archivedAt;
  final int createdAt;
  const PrestationRow(
      {required this.id,
      required this.name,
      this.priceCents,
      this.minutes,
      this.categoryId,
      this.archivedAt,
      required this.createdAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || priceCents != null) {
      map['price_cents'] = Variable<int>(priceCents);
    }
    if (!nullToAbsent || minutes != null) {
      map['minutes'] = Variable<int>(minutes);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<int>(archivedAt);
    }
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  PrestationsTableCompanion toCompanion(bool nullToAbsent) {
    return PrestationsTableCompanion(
      id: Value(id),
      name: Value(name),
      priceCents: priceCents == null && nullToAbsent
          ? const Value.absent()
          : Value(priceCents),
      minutes: minutes == null && nullToAbsent
          ? const Value.absent()
          : Value(minutes),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      createdAt: Value(createdAt),
    );
  }

  factory PrestationRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrestationRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      priceCents: serializer.fromJson<int?>(json['priceCents']),
      minutes: serializer.fromJson<int?>(json['minutes']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      archivedAt: serializer.fromJson<int?>(json['archivedAt']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'priceCents': serializer.toJson<int?>(priceCents),
      'minutes': serializer.toJson<int?>(minutes),
      'categoryId': serializer.toJson<int?>(categoryId),
      'archivedAt': serializer.toJson<int?>(archivedAt),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  PrestationRow copyWith(
          {int? id,
          String? name,
          Value<int?> priceCents = const Value.absent(),
          Value<int?> minutes = const Value.absent(),
          Value<int?> categoryId = const Value.absent(),
          Value<int?> archivedAt = const Value.absent(),
          int? createdAt}) =>
      PrestationRow(
        id: id ?? this.id,
        name: name ?? this.name,
        priceCents: priceCents.present ? priceCents.value : this.priceCents,
        minutes: minutes.present ? minutes.value : this.minutes,
        categoryId: categoryId.present ? categoryId.value : this.categoryId,
        archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
        createdAt: createdAt ?? this.createdAt,
      );
  PrestationRow copyWithCompanion(PrestationsTableCompanion data) {
    return PrestationRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      priceCents:
          data.priceCents.present ? data.priceCents.value : this.priceCents,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
      categoryId:
          data.categoryId.present ? data.categoryId.value : this.categoryId,
      archivedAt:
          data.archivedAt.present ? data.archivedAt.value : this.archivedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrestationRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('priceCents: $priceCents, ')
          ..write('minutes: $minutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, name, priceCents, minutes, categoryId, archivedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrestationRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.priceCents == this.priceCents &&
          other.minutes == this.minutes &&
          other.categoryId == this.categoryId &&
          other.archivedAt == this.archivedAt &&
          other.createdAt == this.createdAt);
}

class PrestationsTableCompanion extends UpdateCompanion<PrestationRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int?> priceCents;
  final Value<int?> minutes;
  final Value<int?> categoryId;
  final Value<int?> archivedAt;
  final Value<int> createdAt;
  const PrestationsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.priceCents = const Value.absent(),
    this.minutes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  PrestationsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.priceCents = const Value.absent(),
    this.minutes = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.archivedAt = const Value.absent(),
    required int createdAt,
  })  : name = Value(name),
        createdAt = Value(createdAt);
  static Insertable<PrestationRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? priceCents,
    Expression<int>? minutes,
    Expression<int>? categoryId,
    Expression<int>? archivedAt,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (priceCents != null) 'price_cents': priceCents,
      if (minutes != null) 'minutes': minutes,
      if (categoryId != null) 'category_id': categoryId,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  PrestationsTableCompanion copyWith(
      {Value<int>? id,
      Value<String>? name,
      Value<int?>? priceCents,
      Value<int?>? minutes,
      Value<int?>? categoryId,
      Value<int?>? archivedAt,
      Value<int>? createdAt}) {
    return PrestationsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      minutes: minutes ?? this.minutes,
      categoryId: categoryId ?? this.categoryId,
      archivedAt: archivedAt ?? this.archivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (priceCents.present) {
      map['price_cents'] = Variable<int>(priceCents.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<int>(archivedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrestationsTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('priceCents: $priceCents, ')
          ..write('minutes: $minutes, ')
          ..write('categoryId: $categoryId, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final $ClientsTableTable clientsTable = $ClientsTableTable(this);
  late final $DistanceMatrixTableTable distanceMatrixTable =
      $DistanceMatrixTableTable(this);
  late final $SpeciesTableTable speciesTable = $SpeciesTableTable(this);
  late final $AnimalCategoriesTableTable animalCategoriesTable =
      $AnimalCategoriesTableTable(this);
  late final $ToursTableTable toursTable = $ToursTableTable(this);
  late final $TourStopsTableTable tourStopsTable = $TourStopsTableTable(this);
  late final $ManualHistoryEntriesTableTable manualHistoryEntriesTable =
      $ManualHistoryEntriesTableTable(this);
  late final $PrestationsTableTable prestationsTable =
      $PrestationsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        settingsTable,
        clientsTable,
        distanceMatrixTable,
        speciesTable,
        animalCategoriesTable,
        toursTable,
        tourStopsTable,
        manualHistoryEntriesTable,
        prestationsTable
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
          WritePropagation(
            on: TableUpdateQuery.onTableName('species',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('animal_categories', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('tours',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('tour_stops', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('clients',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('tour_stops', kind: UpdateKind.update),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('clients',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('manual_history_entries', kind: UpdateKind.delete),
            ],
          ),
          WritePropagation(
            on: TableUpdateQuery.onTableName('animal_categories',
                limitUpdateKind: UpdateKind.delete),
            result: [
              TableUpdate('prestations', kind: UpdateKind.update),
            ],
          ),
        ],
      );
}

typedef $$SettingsTableTableCreateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<int> id,
  required String baseAddressLabel,
  required double baseLat,
  required double baseLon,
  Value<int> defaultRadiusKm,
  Value<int> travelFeeEurosPerBracket,
  Value<int> bracketKm,
  Value<String> themeMode,
  Value<String> markerDefaultColor,
  Value<String> markerWaitingColor,
  Value<String> markerScheduledColor,
  Value<String> markerDoneColor,
  Value<String> markerNoAnimalsColor,
  Value<String> markerBannedColor,
  Value<int> seasonStartedAt,
});
typedef $$SettingsTableTableUpdateCompanionBuilder = SettingsTableCompanion
    Function({
  Value<int> id,
  Value<String> baseAddressLabel,
  Value<double> baseLat,
  Value<double> baseLon,
  Value<int> defaultRadiusKm,
  Value<int> travelFeeEurosPerBracket,
  Value<int> bracketKm,
  Value<String> themeMode,
  Value<String> markerDefaultColor,
  Value<String> markerWaitingColor,
  Value<String> markerScheduledColor,
  Value<String> markerDoneColor,
  Value<String> markerNoAnimalsColor,
  Value<String> markerBannedColor,
  Value<int> seasonStartedAt,
});

class $$SettingsTableTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get baseAddressLabel => $composableBuilder(
      column: $table.baseAddressLabel,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseLat => $composableBuilder(
      column: $table.baseLat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get baseLon => $composableBuilder(
      column: $table.baseLon, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get defaultRadiusKm => $composableBuilder(
      column: $table.defaultRadiusKm,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get travelFeeEurosPerBracket => $composableBuilder(
      column: $table.travelFeeEurosPerBracket,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get bracketKm => $composableBuilder(
      column: $table.bracketKm, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get markerDefaultColor => $composableBuilder(
      column: $table.markerDefaultColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get markerWaitingColor => $composableBuilder(
      column: $table.markerWaitingColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get markerScheduledColor => $composableBuilder(
      column: $table.markerScheduledColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get markerDoneColor => $composableBuilder(
      column: $table.markerDoneColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get markerNoAnimalsColor => $composableBuilder(
      column: $table.markerNoAnimalsColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get markerBannedColor => $composableBuilder(
      column: $table.markerBannedColor,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seasonStartedAt => $composableBuilder(
      column: $table.seasonStartedAt,
      builder: (column) => ColumnFilters(column));
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get baseAddressLabel => $composableBuilder(
      column: $table.baseAddressLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseLat => $composableBuilder(
      column: $table.baseLat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get baseLon => $composableBuilder(
      column: $table.baseLon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get defaultRadiusKm => $composableBuilder(
      column: $table.defaultRadiusKm,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get travelFeeEurosPerBracket => $composableBuilder(
      column: $table.travelFeeEurosPerBracket,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get bracketKm => $composableBuilder(
      column: $table.bracketKm, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get themeMode => $composableBuilder(
      column: $table.themeMode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerDefaultColor => $composableBuilder(
      column: $table.markerDefaultColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerWaitingColor => $composableBuilder(
      column: $table.markerWaitingColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerScheduledColor => $composableBuilder(
      column: $table.markerScheduledColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerDoneColor => $composableBuilder(
      column: $table.markerDoneColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerNoAnimalsColor => $composableBuilder(
      column: $table.markerNoAnimalsColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerBannedColor => $composableBuilder(
      column: $table.markerBannedColor,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seasonStartedAt => $composableBuilder(
      column: $table.seasonStartedAt,
      builder: (column) => ColumnOrderings(column));
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get baseAddressLabel => $composableBuilder(
      column: $table.baseAddressLabel, builder: (column) => column);

  GeneratedColumn<double> get baseLat =>
      $composableBuilder(column: $table.baseLat, builder: (column) => column);

  GeneratedColumn<double> get baseLon =>
      $composableBuilder(column: $table.baseLon, builder: (column) => column);

  GeneratedColumn<int> get defaultRadiusKm => $composableBuilder(
      column: $table.defaultRadiusKm, builder: (column) => column);

  GeneratedColumn<int> get travelFeeEurosPerBracket => $composableBuilder(
      column: $table.travelFeeEurosPerBracket, builder: (column) => column);

  GeneratedColumn<int> get bracketKm =>
      $composableBuilder(column: $table.bracketKm, builder: (column) => column);

  GeneratedColumn<String> get themeMode =>
      $composableBuilder(column: $table.themeMode, builder: (column) => column);

  GeneratedColumn<String> get markerDefaultColor => $composableBuilder(
      column: $table.markerDefaultColor, builder: (column) => column);

  GeneratedColumn<String> get markerWaitingColor => $composableBuilder(
      column: $table.markerWaitingColor, builder: (column) => column);

  GeneratedColumn<String> get markerScheduledColor => $composableBuilder(
      column: $table.markerScheduledColor, builder: (column) => column);

  GeneratedColumn<String> get markerDoneColor => $composableBuilder(
      column: $table.markerDoneColor, builder: (column) => column);

  GeneratedColumn<String> get markerNoAnimalsColor => $composableBuilder(
      column: $table.markerNoAnimalsColor, builder: (column) => column);

  GeneratedColumn<String> get markerBannedColor => $composableBuilder(
      column: $table.markerBannedColor, builder: (column) => column);

  GeneratedColumn<int> get seasonStartedAt => $composableBuilder(
      column: $table.seasonStartedAt, builder: (column) => column);
}

class $$SettingsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsRow,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsRow,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>
    ),
    SettingsRow,
    PrefetchHooks Function()> {
  $$SettingsTableTableTableManager(_$AppDatabase db, $SettingsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> baseAddressLabel = const Value.absent(),
            Value<double> baseLat = const Value.absent(),
            Value<double> baseLon = const Value.absent(),
            Value<int> defaultRadiusKm = const Value.absent(),
            Value<int> travelFeeEurosPerBracket = const Value.absent(),
            Value<int> bracketKm = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> markerDefaultColor = const Value.absent(),
            Value<String> markerWaitingColor = const Value.absent(),
            Value<String> markerScheduledColor = const Value.absent(),
            Value<String> markerDoneColor = const Value.absent(),
            Value<String> markerNoAnimalsColor = const Value.absent(),
            Value<String> markerBannedColor = const Value.absent(),
            Value<int> seasonStartedAt = const Value.absent(),
          }) =>
              SettingsTableCompanion(
            id: id,
            baseAddressLabel: baseAddressLabel,
            baseLat: baseLat,
            baseLon: baseLon,
            defaultRadiusKm: defaultRadiusKm,
            travelFeeEurosPerBracket: travelFeeEurosPerBracket,
            bracketKm: bracketKm,
            themeMode: themeMode,
            markerDefaultColor: markerDefaultColor,
            markerWaitingColor: markerWaitingColor,
            markerScheduledColor: markerScheduledColor,
            markerDoneColor: markerDoneColor,
            markerNoAnimalsColor: markerNoAnimalsColor,
            markerBannedColor: markerBannedColor,
            seasonStartedAt: seasonStartedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String baseAddressLabel,
            required double baseLat,
            required double baseLon,
            Value<int> defaultRadiusKm = const Value.absent(),
            Value<int> travelFeeEurosPerBracket = const Value.absent(),
            Value<int> bracketKm = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> markerDefaultColor = const Value.absent(),
            Value<String> markerWaitingColor = const Value.absent(),
            Value<String> markerScheduledColor = const Value.absent(),
            Value<String> markerDoneColor = const Value.absent(),
            Value<String> markerNoAnimalsColor = const Value.absent(),
            Value<String> markerBannedColor = const Value.absent(),
            Value<int> seasonStartedAt = const Value.absent(),
          }) =>
              SettingsTableCompanion.insert(
            id: id,
            baseAddressLabel: baseAddressLabel,
            baseLat: baseLat,
            baseLon: baseLon,
            defaultRadiusKm: defaultRadiusKm,
            travelFeeEurosPerBracket: travelFeeEurosPerBracket,
            bracketKm: bracketKm,
            themeMode: themeMode,
            markerDefaultColor: markerDefaultColor,
            markerWaitingColor: markerWaitingColor,
            markerScheduledColor: markerScheduledColor,
            markerDoneColor: markerDoneColor,
            markerNoAnimalsColor: markerNoAnimalsColor,
            markerBannedColor: markerBannedColor,
            seasonStartedAt: seasonStartedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$SettingsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SettingsTableTable,
    SettingsRow,
    $$SettingsTableTableFilterComposer,
    $$SettingsTableTableOrderingComposer,
    $$SettingsTableTableAnnotationComposer,
    $$SettingsTableTableCreateCompanionBuilder,
    $$SettingsTableTableUpdateCompanionBuilder,
    (
      SettingsRow,
      BaseReferences<_$AppDatabase, $SettingsTableTable, SettingsRow>
    ),
    SettingsRow,
    PrefetchHooks Function()>;
typedef $$ClientsTableTableCreateCompanionBuilder = ClientsTableCompanion
    Function({
  Value<int> id,
  required String name,
  Value<List<String>> phones,
  required String addressLabel,
  required String postcode,
  required String city,
  required double lat,
  required double lon,
  Value<List<AnimalCount>> animals,
  Value<String?> markerColorHex,
  Value<bool> isWaiting,
  Value<int?> lastInterventionDate,
  Value<bool> needsDistanceRecompute,
  Value<bool> isBanned,
  required int createdAt,
  required int updatedAt,
});
typedef $$ClientsTableTableUpdateCompanionBuilder = ClientsTableCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<List<String>> phones,
  Value<String> addressLabel,
  Value<String> postcode,
  Value<String> city,
  Value<double> lat,
  Value<double> lon,
  Value<List<AnimalCount>> animals,
  Value<String?> markerColorHex,
  Value<bool> isWaiting,
  Value<int?> lastInterventionDate,
  Value<bool> needsDistanceRecompute,
  Value<bool> isBanned,
  Value<int> createdAt,
  Value<int> updatedAt,
});

final class $$ClientsTableTableReferences
    extends BaseReferences<_$AppDatabase, $ClientsTableTable, ClientRow> {
  $$ClientsTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TourStopsTableTable, List<TourStopRow>>
      _tourStopsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.tourStopsTable,
              aliasName: $_aliasNameGenerator(
                  db.clientsTable.id, db.tourStopsTable.clientId));

  $$TourStopsTableTableProcessedTableManager get tourStopsTableRefs {
    final manager = $$TourStopsTableTableTableManager($_db, $_db.tourStopsTable)
        .filter((f) => f.clientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tourStopsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }

  static MultiTypedResultKey<$ManualHistoryEntriesTableTable,
      List<ManualHistoryEntryRow>> _manualHistoryEntriesTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.manualHistoryEntriesTable,
          aliasName: $_aliasNameGenerator(
              db.clientsTable.id, db.manualHistoryEntriesTable.clientId));

  $$ManualHistoryEntriesTableTableProcessedTableManager
      get manualHistoryEntriesTableRefs {
    final manager = $$ManualHistoryEntriesTableTableTableManager(
            $_db, $_db.manualHistoryEntriesTable)
        .filter((f) => f.clientId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult
        .readTableOrNull(_manualHistoryEntriesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ClientsTableTableFilterComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<String>, List<String>, String>
      get phones => $composableBuilder(
          column: $table.phones,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get addressLabel => $composableBuilder(
      column: $table.addressLabel, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get postcode => $composableBuilder(
      column: $table.postcode, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<AnimalCount>, List<AnimalCount>, String>
      get animals => $composableBuilder(
          column: $table.animals,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get markerColorHex => $composableBuilder(
      column: $table.markerColorHex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWaiting => $composableBuilder(
      column: $table.isWaiting, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastInterventionDate => $composableBuilder(
      column: $table.lastInterventionDate,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get needsDistanceRecompute => $composableBuilder(
      column: $table.needsDistanceRecompute,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isBanned => $composableBuilder(
      column: $table.isBanned, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  Expression<bool> tourStopsTableRefs(
      Expression<bool> Function($$TourStopsTableTableFilterComposer f) f) {
    final $$TourStopsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tourStopsTable,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TourStopsTableTableFilterComposer(
              $db: $db,
              $table: $db.tourStopsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<bool> manualHistoryEntriesTableRefs(
      Expression<bool> Function(
              $$ManualHistoryEntriesTableTableFilterComposer f)
          f) {
    final $$ManualHistoryEntriesTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.manualHistoryEntriesTable,
            getReferencedColumn: (t) => t.clientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ManualHistoryEntriesTableTableFilterComposer(
                  $db: $db,
                  $table: $db.manualHistoryEntriesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ClientsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get phones => $composableBuilder(
      column: $table.phones, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get addressLabel => $composableBuilder(
      column: $table.addressLabel,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get postcode => $composableBuilder(
      column: $table.postcode, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get city => $composableBuilder(
      column: $table.city, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lat => $composableBuilder(
      column: $table.lat, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get lon => $composableBuilder(
      column: $table.lon, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get animals => $composableBuilder(
      column: $table.animals, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerColorHex => $composableBuilder(
      column: $table.markerColorHex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWaiting => $composableBuilder(
      column: $table.isWaiting, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastInterventionDate => $composableBuilder(
      column: $table.lastInterventionDate,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get needsDistanceRecompute => $composableBuilder(
      column: $table.needsDistanceRecompute,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isBanned => $composableBuilder(
      column: $table.isBanned, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));
}

class $$ClientsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ClientsTableTable> {
  $$ClientsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<String>, String> get phones =>
      $composableBuilder(column: $table.phones, builder: (column) => column);

  GeneratedColumn<String> get addressLabel => $composableBuilder(
      column: $table.addressLabel, builder: (column) => column);

  GeneratedColumn<String> get postcode =>
      $composableBuilder(column: $table.postcode, builder: (column) => column);

  GeneratedColumn<String> get city =>
      $composableBuilder(column: $table.city, builder: (column) => column);

  GeneratedColumn<double> get lat =>
      $composableBuilder(column: $table.lat, builder: (column) => column);

  GeneratedColumn<double> get lon =>
      $composableBuilder(column: $table.lon, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<AnimalCount>, String> get animals =>
      $composableBuilder(column: $table.animals, builder: (column) => column);

  GeneratedColumn<String> get markerColorHex => $composableBuilder(
      column: $table.markerColorHex, builder: (column) => column);

  GeneratedColumn<bool> get isWaiting =>
      $composableBuilder(column: $table.isWaiting, builder: (column) => column);

  GeneratedColumn<int> get lastInterventionDate => $composableBuilder(
      column: $table.lastInterventionDate, builder: (column) => column);

  GeneratedColumn<bool> get needsDistanceRecompute => $composableBuilder(
      column: $table.needsDistanceRecompute, builder: (column) => column);

  GeneratedColumn<bool> get isBanned =>
      $composableBuilder(column: $table.isBanned, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> tourStopsTableRefs<T extends Object>(
      Expression<T> Function($$TourStopsTableTableAnnotationComposer a) f) {
    final $$TourStopsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tourStopsTable,
        getReferencedColumn: (t) => t.clientId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TourStopsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.tourStopsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }

  Expression<T> manualHistoryEntriesTableRefs<T extends Object>(
      Expression<T> Function(
              $$ManualHistoryEntriesTableTableAnnotationComposer a)
          f) {
    final $$ManualHistoryEntriesTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.manualHistoryEntriesTable,
            getReferencedColumn: (t) => t.clientId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$ManualHistoryEntriesTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.manualHistoryEntriesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$ClientsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ClientsTableTable,
    ClientRow,
    $$ClientsTableTableFilterComposer,
    $$ClientsTableTableOrderingComposer,
    $$ClientsTableTableAnnotationComposer,
    $$ClientsTableTableCreateCompanionBuilder,
    $$ClientsTableTableUpdateCompanionBuilder,
    (ClientRow, $$ClientsTableTableReferences),
    ClientRow,
    PrefetchHooks Function(
        {bool tourStopsTableRefs, bool manualHistoryEntriesTableRefs})> {
  $$ClientsTableTableTableManager(_$AppDatabase db, $ClientsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClientsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClientsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClientsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<List<String>> phones = const Value.absent(),
            Value<String> addressLabel = const Value.absent(),
            Value<String> postcode = const Value.absent(),
            Value<String> city = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<List<AnimalCount>> animals = const Value.absent(),
            Value<String?> markerColorHex = const Value.absent(),
            Value<bool> isWaiting = const Value.absent(),
            Value<int?> lastInterventionDate = const Value.absent(),
            Value<bool> needsDistanceRecompute = const Value.absent(),
            Value<bool> isBanned = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              ClientsTableCompanion(
            id: id,
            name: name,
            phones: phones,
            addressLabel: addressLabel,
            postcode: postcode,
            city: city,
            lat: lat,
            lon: lon,
            animals: animals,
            markerColorHex: markerColorHex,
            isWaiting: isWaiting,
            lastInterventionDate: lastInterventionDate,
            needsDistanceRecompute: needsDistanceRecompute,
            isBanned: isBanned,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<List<String>> phones = const Value.absent(),
            required String addressLabel,
            required String postcode,
            required String city,
            required double lat,
            required double lon,
            Value<List<AnimalCount>> animals = const Value.absent(),
            Value<String?> markerColorHex = const Value.absent(),
            Value<bool> isWaiting = const Value.absent(),
            Value<int?> lastInterventionDate = const Value.absent(),
            Value<bool> needsDistanceRecompute = const Value.absent(),
            Value<bool> isBanned = const Value.absent(),
            required int createdAt,
            required int updatedAt,
          }) =>
              ClientsTableCompanion.insert(
            id: id,
            name: name,
            phones: phones,
            addressLabel: addressLabel,
            postcode: postcode,
            city: city,
            lat: lat,
            lon: lon,
            animals: animals,
            markerColorHex: markerColorHex,
            isWaiting: isWaiting,
            lastInterventionDate: lastInterventionDate,
            needsDistanceRecompute: needsDistanceRecompute,
            isBanned: isBanned,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ClientsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {tourStopsTableRefs = false,
              manualHistoryEntriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tourStopsTableRefs) db.tourStopsTable,
                if (manualHistoryEntriesTableRefs) db.manualHistoryEntriesTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tourStopsTableRefs)
                    await $_getPrefetchedData<ClientRow, $ClientsTableTable,
                            TourStopRow>(
                        currentTable: table,
                        referencedTable: $$ClientsTableTableReferences
                            ._tourStopsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClientsTableTableReferences(db, table, p0)
                                .tourStopsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.clientId == item.id),
                        typedResults: items),
                  if (manualHistoryEntriesTableRefs)
                    await $_getPrefetchedData<ClientRow, $ClientsTableTable,
                            ManualHistoryEntryRow>(
                        currentTable: table,
                        referencedTable: $$ClientsTableTableReferences
                            ._manualHistoryEntriesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ClientsTableTableReferences(db, table, p0)
                                .manualHistoryEntriesTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.clientId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ClientsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ClientsTableTable,
    ClientRow,
    $$ClientsTableTableFilterComposer,
    $$ClientsTableTableOrderingComposer,
    $$ClientsTableTableAnnotationComposer,
    $$ClientsTableTableCreateCompanionBuilder,
    $$ClientsTableTableUpdateCompanionBuilder,
    (ClientRow, $$ClientsTableTableReferences),
    ClientRow,
    PrefetchHooks Function(
        {bool tourStopsTableRefs, bool manualHistoryEntriesTableRefs})>;
typedef $$DistanceMatrixTableTableCreateCompanionBuilder
    = DistanceMatrixTableCompanion Function({
  required int fromId,
  required int toId,
  required int distanceMeters,
  required int durationSeconds,
  required int computedAt,
  Value<int> rowid,
});
typedef $$DistanceMatrixTableTableUpdateCompanionBuilder
    = DistanceMatrixTableCompanion Function({
  Value<int> fromId,
  Value<int> toId,
  Value<int> distanceMeters,
  Value<int> durationSeconds,
  Value<int> computedAt,
  Value<int> rowid,
});

class $$DistanceMatrixTableTableFilterComposer
    extends Composer<_$AppDatabase, $DistanceMatrixTableTable> {
  $$DistanceMatrixTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnFilters(column));
}

class $$DistanceMatrixTableTableOrderingComposer
    extends Composer<_$AppDatabase, $DistanceMatrixTableTable> {
  $$DistanceMatrixTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get fromId => $composableBuilder(
      column: $table.fromId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get toId => $composableBuilder(
      column: $table.toId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => ColumnOrderings(column));
}

class $$DistanceMatrixTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $DistanceMatrixTableTable> {
  $$DistanceMatrixTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get fromId =>
      $composableBuilder(column: $table.fromId, builder: (column) => column);

  GeneratedColumn<int> get toId =>
      $composableBuilder(column: $table.toId, builder: (column) => column);

  GeneratedColumn<int> get distanceMeters => $composableBuilder(
      column: $table.distanceMeters, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<int> get computedAt => $composableBuilder(
      column: $table.computedAt, builder: (column) => column);
}

class $$DistanceMatrixTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $DistanceMatrixTableTable,
    DistanceMatrixRow,
    $$DistanceMatrixTableTableFilterComposer,
    $$DistanceMatrixTableTableOrderingComposer,
    $$DistanceMatrixTableTableAnnotationComposer,
    $$DistanceMatrixTableTableCreateCompanionBuilder,
    $$DistanceMatrixTableTableUpdateCompanionBuilder,
    (
      DistanceMatrixRow,
      BaseReferences<_$AppDatabase, $DistanceMatrixTableTable,
          DistanceMatrixRow>
    ),
    DistanceMatrixRow,
    PrefetchHooks Function()> {
  $$DistanceMatrixTableTableTableManager(
      _$AppDatabase db, $DistanceMatrixTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DistanceMatrixTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DistanceMatrixTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DistanceMatrixTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> fromId = const Value.absent(),
            Value<int> toId = const Value.absent(),
            Value<int> distanceMeters = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<int> computedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              DistanceMatrixTableCompanion(
            fromId: fromId,
            toId: toId,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            computedAt: computedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required int fromId,
            required int toId,
            required int distanceMeters,
            required int durationSeconds,
            required int computedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              DistanceMatrixTableCompanion.insert(
            fromId: fromId,
            toId: toId,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            computedAt: computedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$DistanceMatrixTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $DistanceMatrixTableTable,
    DistanceMatrixRow,
    $$DistanceMatrixTableTableFilterComposer,
    $$DistanceMatrixTableTableOrderingComposer,
    $$DistanceMatrixTableTableAnnotationComposer,
    $$DistanceMatrixTableTableCreateCompanionBuilder,
    $$DistanceMatrixTableTableUpdateCompanionBuilder,
    (
      DistanceMatrixRow,
      BaseReferences<_$AppDatabase, $DistanceMatrixTableTable,
          DistanceMatrixRow>
    ),
    DistanceMatrixRow,
    PrefetchHooks Function()>;
typedef $$SpeciesTableTableCreateCompanionBuilder = SpeciesTableCompanion
    Function({
  Value<int> id,
  required String name,
  Value<String?> iconKey,
  Value<int?> archivedAt,
  required int createdAt,
});
typedef $$SpeciesTableTableUpdateCompanionBuilder = SpeciesTableCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> iconKey,
  Value<int?> archivedAt,
  Value<int> createdAt,
});

final class $$SpeciesTableTableReferences
    extends BaseReferences<_$AppDatabase, $SpeciesTableTable, SpeciesRow> {
  $$SpeciesTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$AnimalCategoriesTableTable,
      List<AnimalCategoryRow>> _animalCategoriesTableRefsTable(
          _$AppDatabase db) =>
      MultiTypedResultKey.fromTable(db.animalCategoriesTable,
          aliasName: $_aliasNameGenerator(
              db.speciesTable.id, db.animalCategoriesTable.speciesId));

  $$AnimalCategoriesTableTableProcessedTableManager
      get animalCategoriesTableRefs {
    final manager = $$AnimalCategoriesTableTableTableManager(
            $_db, $_db.animalCategoriesTable)
        .filter((f) => f.speciesId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_animalCategoriesTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$SpeciesTableTableFilterComposer
    extends Composer<_$AppDatabase, $SpeciesTableTable> {
  $$SpeciesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  Expression<bool> animalCategoriesTableRefs(
      Expression<bool> Function($$AnimalCategoriesTableTableFilterComposer f)
          f) {
    final $$AnimalCategoriesTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.animalCategoriesTable,
            getReferencedColumn: (t) => t.speciesId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AnimalCategoriesTableTableFilterComposer(
                  $db: $db,
                  $table: $db.animalCategoriesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SpeciesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SpeciesTableTable> {
  $$SpeciesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get iconKey => $composableBuilder(
      column: $table.iconKey, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));
}

class $$SpeciesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SpeciesTableTable> {
  $$SpeciesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get iconKey =>
      $composableBuilder(column: $table.iconKey, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> animalCategoriesTableRefs<T extends Object>(
      Expression<T> Function($$AnimalCategoriesTableTableAnnotationComposer a)
          f) {
    final $$AnimalCategoriesTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.id,
            referencedTable: $db.animalCategoriesTable,
            getReferencedColumn: (t) => t.speciesId,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AnimalCategoriesTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.animalCategoriesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return f(composer);
  }
}

class $$SpeciesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $SpeciesTableTable,
    SpeciesRow,
    $$SpeciesTableTableFilterComposer,
    $$SpeciesTableTableOrderingComposer,
    $$SpeciesTableTableAnnotationComposer,
    $$SpeciesTableTableCreateCompanionBuilder,
    $$SpeciesTableTableUpdateCompanionBuilder,
    (SpeciesRow, $$SpeciesTableTableReferences),
    SpeciesRow,
    PrefetchHooks Function({bool animalCategoriesTableRefs})> {
  $$SpeciesTableTableTableManager(_$AppDatabase db, $SpeciesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SpeciesTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SpeciesTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SpeciesTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String?> iconKey = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              SpeciesTableCompanion(
            id: id,
            name: name,
            iconKey: iconKey,
            archivedAt: archivedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> iconKey = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            required int createdAt,
          }) =>
              SpeciesTableCompanion.insert(
            id: id,
            name: name,
            iconKey: iconKey,
            archivedAt: archivedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$SpeciesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({animalCategoriesTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (animalCategoriesTableRefs) db.animalCategoriesTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (animalCategoriesTableRefs)
                    await $_getPrefetchedData<SpeciesRow, $SpeciesTableTable, AnimalCategoryRow>(
                        currentTable: table,
                        referencedTable: $$SpeciesTableTableReferences
                            ._animalCategoriesTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$SpeciesTableTableReferences(db, table, p0)
                                .animalCategoriesTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.speciesId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$SpeciesTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $SpeciesTableTable,
    SpeciesRow,
    $$SpeciesTableTableFilterComposer,
    $$SpeciesTableTableOrderingComposer,
    $$SpeciesTableTableAnnotationComposer,
    $$SpeciesTableTableCreateCompanionBuilder,
    $$SpeciesTableTableUpdateCompanionBuilder,
    (SpeciesRow, $$SpeciesTableTableReferences),
    SpeciesRow,
    PrefetchHooks Function({bool animalCategoriesTableRefs})>;
typedef $$AnimalCategoriesTableTableCreateCompanionBuilder
    = AnimalCategoriesTableCompanion Function({
  Value<int> id,
  required int speciesId,
  required String name,
  Value<int?> archivedAt,
  required int createdAt,
});
typedef $$AnimalCategoriesTableTableUpdateCompanionBuilder
    = AnimalCategoriesTableCompanion Function({
  Value<int> id,
  Value<int> speciesId,
  Value<String> name,
  Value<int?> archivedAt,
  Value<int> createdAt,
});

final class $$AnimalCategoriesTableTableReferences extends BaseReferences<
    _$AppDatabase, $AnimalCategoriesTableTable, AnimalCategoryRow> {
  $$AnimalCategoriesTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $SpeciesTableTable _speciesIdTable(_$AppDatabase db) =>
      db.speciesTable.createAlias($_aliasNameGenerator(
          db.animalCategoriesTable.speciesId, db.speciesTable.id));

  $$SpeciesTableTableProcessedTableManager get speciesId {
    final $_column = $_itemColumn<int>('species_id')!;

    final manager = $$SpeciesTableTableTableManager($_db, $_db.speciesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_speciesIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static MultiTypedResultKey<$PrestationsTableTable, List<PrestationRow>>
      _prestationsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.prestationsTable,
              aliasName: $_aliasNameGenerator(
                  db.animalCategoriesTable.id, db.prestationsTable.categoryId));

  $$PrestationsTableTableProcessedTableManager get prestationsTableRefs {
    final manager =
        $$PrestationsTableTableTableManager($_db, $_db.prestationsTable)
            .filter((f) => f.categoryId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache =
        $_typedResult.readTableOrNull(_prestationsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$AnimalCategoriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $AnimalCategoriesTableTable> {
  $$AnimalCategoriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$SpeciesTableTableFilterComposer get speciesId {
    final $$SpeciesTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.speciesId,
        referencedTable: $db.speciesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpeciesTableTableFilterComposer(
              $db: $db,
              $table: $db.speciesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<bool> prestationsTableRefs(
      Expression<bool> Function($$PrestationsTableTableFilterComposer f) f) {
    final $$PrestationsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.prestationsTable,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrestationsTableTableFilterComposer(
              $db: $db,
              $table: $db.prestationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AnimalCategoriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $AnimalCategoriesTableTable> {
  $$AnimalCategoriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$SpeciesTableTableOrderingComposer get speciesId {
    final $$SpeciesTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.speciesId,
        referencedTable: $db.speciesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpeciesTableTableOrderingComposer(
              $db: $db,
              $table: $db.speciesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$AnimalCategoriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $AnimalCategoriesTableTable> {
  $$AnimalCategoriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$SpeciesTableTableAnnotationComposer get speciesId {
    final $$SpeciesTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.speciesId,
        referencedTable: $db.speciesTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$SpeciesTableTableAnnotationComposer(
              $db: $db,
              $table: $db.speciesTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  Expression<T> prestationsTableRefs<T extends Object>(
      Expression<T> Function($$PrestationsTableTableAnnotationComposer a) f) {
    final $$PrestationsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.prestationsTable,
        getReferencedColumn: (t) => t.categoryId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$PrestationsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.prestationsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$AnimalCategoriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $AnimalCategoriesTableTable,
    AnimalCategoryRow,
    $$AnimalCategoriesTableTableFilterComposer,
    $$AnimalCategoriesTableTableOrderingComposer,
    $$AnimalCategoriesTableTableAnnotationComposer,
    $$AnimalCategoriesTableTableCreateCompanionBuilder,
    $$AnimalCategoriesTableTableUpdateCompanionBuilder,
    (AnimalCategoryRow, $$AnimalCategoriesTableTableReferences),
    AnimalCategoryRow,
    PrefetchHooks Function({bool speciesId, bool prestationsTableRefs})> {
  $$AnimalCategoriesTableTableTableManager(
      _$AppDatabase db, $AnimalCategoriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AnimalCategoriesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$AnimalCategoriesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AnimalCategoriesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> speciesId = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              AnimalCategoriesTableCompanion(
            id: id,
            speciesId: speciesId,
            name: name,
            archivedAt: archivedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int speciesId,
            required String name,
            Value<int?> archivedAt = const Value.absent(),
            required int createdAt,
          }) =>
              AnimalCategoriesTableCompanion.insert(
            id: id,
            speciesId: speciesId,
            name: name,
            archivedAt: archivedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$AnimalCategoriesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: (
              {speciesId = false, prestationsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (prestationsTableRefs) db.prestationsTable
              ],
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
                if (speciesId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.speciesId,
                    referencedTable: $$AnimalCategoriesTableTableReferences
                        ._speciesIdTable(db),
                    referencedColumn: $$AnimalCategoriesTableTableReferences
                        ._speciesIdTable(db)
                        .id,
                  ) as T;
                }

                return state;
              },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (prestationsTableRefs)
                    await $_getPrefetchedData<AnimalCategoryRow,
                            $AnimalCategoriesTableTable, PrestationRow>(
                        currentTable: table,
                        referencedTable: $$AnimalCategoriesTableTableReferences
                            ._prestationsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$AnimalCategoriesTableTableReferences(
                                    db, table, p0)
                                .prestationsTableRefs,
                        referencedItemsForCurrentItem:
                            (item, referencedItems) => referencedItems
                                .where((e) => e.categoryId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$AnimalCategoriesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $AnimalCategoriesTableTable,
        AnimalCategoryRow,
        $$AnimalCategoriesTableTableFilterComposer,
        $$AnimalCategoriesTableTableOrderingComposer,
        $$AnimalCategoriesTableTableAnnotationComposer,
        $$AnimalCategoriesTableTableCreateCompanionBuilder,
        $$AnimalCategoriesTableTableUpdateCompanionBuilder,
        (AnimalCategoryRow, $$AnimalCategoriesTableTableReferences),
        AnimalCategoryRow,
        PrefetchHooks Function({bool speciesId, bool prestationsTableRefs})>;
typedef $$ToursTableTableCreateCompanionBuilder = ToursTableCompanion Function({
  Value<int> id,
  required int plannedDate,
  required int startTimeMinutes,
  required String status,
  required int totalDistanceMeters,
  required int totalDriveSeconds,
  required int totalTravelFeeCents,
  Value<String?> notes,
  Value<int?> completedAt,
  required int createdAt,
  Value<String?> routeGeometry,
});
typedef $$ToursTableTableUpdateCompanionBuilder = ToursTableCompanion Function({
  Value<int> id,
  Value<int> plannedDate,
  Value<int> startTimeMinutes,
  Value<String> status,
  Value<int> totalDistanceMeters,
  Value<int> totalDriveSeconds,
  Value<int> totalTravelFeeCents,
  Value<String?> notes,
  Value<int?> completedAt,
  Value<int> createdAt,
  Value<String?> routeGeometry,
});

final class $$ToursTableTableReferences
    extends BaseReferences<_$AppDatabase, $ToursTableTable, TourRow> {
  $$ToursTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TourStopsTableTable, List<TourStopRow>>
      _tourStopsTableRefsTable(_$AppDatabase db) =>
          MultiTypedResultKey.fromTable(db.tourStopsTable,
              aliasName: $_aliasNameGenerator(
                  db.toursTable.id, db.tourStopsTable.tourId));

  $$TourStopsTableTableProcessedTableManager get tourStopsTableRefs {
    final manager = $$TourStopsTableTableTableManager($_db, $_db.tourStopsTable)
        .filter((f) => f.tourId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_tourStopsTableRefsTable($_db));
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: cache));
  }
}

class $$ToursTableTableFilterComposer
    extends Composer<_$AppDatabase, $ToursTableTable> {
  $$ToursTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get plannedDate => $composableBuilder(
      column: $table.plannedDate, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startTimeMinutes => $composableBuilder(
      column: $table.startTimeMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalDistanceMeters => $composableBuilder(
      column: $table.totalDistanceMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalDriveSeconds => $composableBuilder(
      column: $table.totalDriveSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get totalTravelFeeCents => $composableBuilder(
      column: $table.totalTravelFeeCents,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get routeGeometry => $composableBuilder(
      column: $table.routeGeometry, builder: (column) => ColumnFilters(column));

  Expression<bool> tourStopsTableRefs(
      Expression<bool> Function($$TourStopsTableTableFilterComposer f) f) {
    final $$TourStopsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tourStopsTable,
        getReferencedColumn: (t) => t.tourId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TourStopsTableTableFilterComposer(
              $db: $db,
              $table: $db.tourStopsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ToursTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ToursTableTable> {
  $$ToursTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get plannedDate => $composableBuilder(
      column: $table.plannedDate, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startTimeMinutes => $composableBuilder(
      column: $table.startTimeMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalDistanceMeters => $composableBuilder(
      column: $table.totalDistanceMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalDriveSeconds => $composableBuilder(
      column: $table.totalDriveSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get totalTravelFeeCents => $composableBuilder(
      column: $table.totalTravelFeeCents,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get notes => $composableBuilder(
      column: $table.notes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get routeGeometry => $composableBuilder(
      column: $table.routeGeometry,
      builder: (column) => ColumnOrderings(column));
}

class $$ToursTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ToursTableTable> {
  $$ToursTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get plannedDate => $composableBuilder(
      column: $table.plannedDate, builder: (column) => column);

  GeneratedColumn<int> get startTimeMinutes => $composableBuilder(
      column: $table.startTimeMinutes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get totalDistanceMeters => $composableBuilder(
      column: $table.totalDistanceMeters, builder: (column) => column);

  GeneratedColumn<int> get totalDriveSeconds => $composableBuilder(
      column: $table.totalDriveSeconds, builder: (column) => column);

  GeneratedColumn<int> get totalTravelFeeCents => $composableBuilder(
      column: $table.totalTravelFeeCents, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<String> get routeGeometry => $composableBuilder(
      column: $table.routeGeometry, builder: (column) => column);

  Expression<T> tourStopsTableRefs<T extends Object>(
      Expression<T> Function($$TourStopsTableTableAnnotationComposer a) f) {
    final $$TourStopsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.id,
        referencedTable: $db.tourStopsTable,
        getReferencedColumn: (t) => t.tourId,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$TourStopsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.tourStopsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return f(composer);
  }
}

class $$ToursTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ToursTableTable,
    TourRow,
    $$ToursTableTableFilterComposer,
    $$ToursTableTableOrderingComposer,
    $$ToursTableTableAnnotationComposer,
    $$ToursTableTableCreateCompanionBuilder,
    $$ToursTableTableUpdateCompanionBuilder,
    (TourRow, $$ToursTableTableReferences),
    TourRow,
    PrefetchHooks Function({bool tourStopsTableRefs})> {
  $$ToursTableTableTableManager(_$AppDatabase db, $ToursTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ToursTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ToursTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ToursTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> plannedDate = const Value.absent(),
            Value<int> startTimeMinutes = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> totalDistanceMeters = const Value.absent(),
            Value<int> totalDriveSeconds = const Value.absent(),
            Value<int> totalTravelFeeCents = const Value.absent(),
            Value<String?> notes = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<String?> routeGeometry = const Value.absent(),
          }) =>
              ToursTableCompanion(
            id: id,
            plannedDate: plannedDate,
            startTimeMinutes: startTimeMinutes,
            status: status,
            totalDistanceMeters: totalDistanceMeters,
            totalDriveSeconds: totalDriveSeconds,
            totalTravelFeeCents: totalTravelFeeCents,
            notes: notes,
            completedAt: completedAt,
            createdAt: createdAt,
            routeGeometry: routeGeometry,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int plannedDate,
            required int startTimeMinutes,
            required String status,
            required int totalDistanceMeters,
            required int totalDriveSeconds,
            required int totalTravelFeeCents,
            Value<String?> notes = const Value.absent(),
            Value<int?> completedAt = const Value.absent(),
            required int createdAt,
            Value<String?> routeGeometry = const Value.absent(),
          }) =>
              ToursTableCompanion.insert(
            id: id,
            plannedDate: plannedDate,
            startTimeMinutes: startTimeMinutes,
            status: status,
            totalDistanceMeters: totalDistanceMeters,
            totalDriveSeconds: totalDriveSeconds,
            totalTravelFeeCents: totalTravelFeeCents,
            notes: notes,
            completedAt: completedAt,
            createdAt: createdAt,
            routeGeometry: routeGeometry,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ToursTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({tourStopsTableRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (tourStopsTableRefs) db.tourStopsTable
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tourStopsTableRefs)
                    await $_getPrefetchedData<TourRow, $ToursTableTable,
                            TourStopRow>(
                        currentTable: table,
                        referencedTable: $$ToursTableTableReferences
                            ._tourStopsTableRefsTable(db),
                        managerFromTypedResult: (p0) =>
                            $$ToursTableTableReferences(db, table, p0)
                                .tourStopsTableRefs,
                        referencedItemsForCurrentItem: (item,
                                referencedItems) =>
                            referencedItems.where((e) => e.tourId == item.id),
                        typedResults: items)
                ];
              },
            );
          },
        ));
}

typedef $$ToursTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $ToursTableTable,
    TourRow,
    $$ToursTableTableFilterComposer,
    $$ToursTableTableOrderingComposer,
    $$ToursTableTableAnnotationComposer,
    $$ToursTableTableCreateCompanionBuilder,
    $$ToursTableTableUpdateCompanionBuilder,
    (TourRow, $$ToursTableTableReferences),
    TourRow,
    PrefetchHooks Function({bool tourStopsTableRefs})>;
typedef $$TourStopsTableTableCreateCompanionBuilder = TourStopsTableCompanion
    Function({
  Value<int> id,
  required int tourId,
  Value<int?> clientId,
  required String clientNameSnapshot,
  required int orderIndex,
  required int estimatedArrivalMinutes,
  required int estimatedDepartureMinutes,
  Value<List<TourStopPrestation>> plannedPrestations,
  Value<List<TourStopPrestation>?> actualPrestations,
  Value<String?> interventionNote,
  required int feeShareCents,
});
typedef $$TourStopsTableTableUpdateCompanionBuilder = TourStopsTableCompanion
    Function({
  Value<int> id,
  Value<int> tourId,
  Value<int?> clientId,
  Value<String> clientNameSnapshot,
  Value<int> orderIndex,
  Value<int> estimatedArrivalMinutes,
  Value<int> estimatedDepartureMinutes,
  Value<List<TourStopPrestation>> plannedPrestations,
  Value<List<TourStopPrestation>?> actualPrestations,
  Value<String?> interventionNote,
  Value<int> feeShareCents,
});

final class $$TourStopsTableTableReferences
    extends BaseReferences<_$AppDatabase, $TourStopsTableTable, TourStopRow> {
  $$TourStopsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ToursTableTable _tourIdTable(_$AppDatabase db) =>
      db.toursTable.createAlias(
          $_aliasNameGenerator(db.tourStopsTable.tourId, db.toursTable.id));

  $$ToursTableTableProcessedTableManager get tourId {
    final $_column = $_itemColumn<int>('tour_id')!;

    final manager = $$ToursTableTableTableManager($_db, $_db.toursTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tourIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }

  static $ClientsTableTable _clientIdTable(_$AppDatabase db) =>
      db.clientsTable.createAlias(
          $_aliasNameGenerator(db.tourStopsTable.clientId, db.clientsTable.id));

  $$ClientsTableTableProcessedTableManager? get clientId {
    final $_column = $_itemColumn<int>('client_id');
    if ($_column == null) return null;
    final manager = $$ClientsTableTableTableManager($_db, $_db.clientsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$TourStopsTableTableFilterComposer
    extends Composer<_$AppDatabase, $TourStopsTableTable> {
  $$TourStopsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get clientNameSnapshot => $composableBuilder(
      column: $table.clientNameSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedArrivalMinutes => $composableBuilder(
      column: $table.estimatedArrivalMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get estimatedDepartureMinutes => $composableBuilder(
      column: $table.estimatedDepartureMinutes,
      builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<TourStopPrestation>,
          List<TourStopPrestation>, String>
      get plannedPrestations => $composableBuilder(
          column: $table.plannedPrestations,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnWithTypeConverterFilters<List<TourStopPrestation>?,
          List<TourStopPrestation>, String>
      get actualPrestations => $composableBuilder(
          column: $table.actualPrestations,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get interventionNote => $composableBuilder(
      column: $table.interventionNote,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get feeShareCents => $composableBuilder(
      column: $table.feeShareCents, builder: (column) => ColumnFilters(column));

  $$ToursTableTableFilterComposer get tourId {
    final $$ToursTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tourId,
        referencedTable: $db.toursTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ToursTableTableFilterComposer(
              $db: $db,
              $table: $db.toursTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClientsTableTableFilterComposer get clientId {
    final $$ClientsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clientsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableTableFilterComposer(
              $db: $db,
              $table: $db.clientsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TourStopsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $TourStopsTableTable> {
  $$TourStopsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get clientNameSnapshot => $composableBuilder(
      column: $table.clientNameSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedArrivalMinutes => $composableBuilder(
      column: $table.estimatedArrivalMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get estimatedDepartureMinutes => $composableBuilder(
      column: $table.estimatedDepartureMinutes,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get plannedPrestations => $composableBuilder(
      column: $table.plannedPrestations,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actualPrestations => $composableBuilder(
      column: $table.actualPrestations,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get interventionNote => $composableBuilder(
      column: $table.interventionNote,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get feeShareCents => $composableBuilder(
      column: $table.feeShareCents,
      builder: (column) => ColumnOrderings(column));

  $$ToursTableTableOrderingComposer get tourId {
    final $$ToursTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tourId,
        referencedTable: $db.toursTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ToursTableTableOrderingComposer(
              $db: $db,
              $table: $db.toursTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClientsTableTableOrderingComposer get clientId {
    final $$ClientsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clientsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableTableOrderingComposer(
              $db: $db,
              $table: $db.clientsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TourStopsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $TourStopsTableTable> {
  $$TourStopsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get clientNameSnapshot => $composableBuilder(
      column: $table.clientNameSnapshot, builder: (column) => column);

  GeneratedColumn<int> get orderIndex => $composableBuilder(
      column: $table.orderIndex, builder: (column) => column);

  GeneratedColumn<int> get estimatedArrivalMinutes => $composableBuilder(
      column: $table.estimatedArrivalMinutes, builder: (column) => column);

  GeneratedColumn<int> get estimatedDepartureMinutes => $composableBuilder(
      column: $table.estimatedDepartureMinutes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TourStopPrestation>, String>
      get plannedPrestations => $composableBuilder(
          column: $table.plannedPrestations, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TourStopPrestation>?, String>
      get actualPrestations => $composableBuilder(
          column: $table.actualPrestations, builder: (column) => column);

  GeneratedColumn<String> get interventionNote => $composableBuilder(
      column: $table.interventionNote, builder: (column) => column);

  GeneratedColumn<int> get feeShareCents => $composableBuilder(
      column: $table.feeShareCents, builder: (column) => column);

  $$ToursTableTableAnnotationComposer get tourId {
    final $$ToursTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.tourId,
        referencedTable: $db.toursTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ToursTableTableAnnotationComposer(
              $db: $db,
              $table: $db.toursTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }

  $$ClientsTableTableAnnotationComposer get clientId {
    final $$ClientsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clientsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.clientsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$TourStopsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TourStopsTableTable,
    TourStopRow,
    $$TourStopsTableTableFilterComposer,
    $$TourStopsTableTableOrderingComposer,
    $$TourStopsTableTableAnnotationComposer,
    $$TourStopsTableTableCreateCompanionBuilder,
    $$TourStopsTableTableUpdateCompanionBuilder,
    (TourStopRow, $$TourStopsTableTableReferences),
    TourStopRow,
    PrefetchHooks Function({bool tourId, bool clientId})> {
  $$TourStopsTableTableTableManager(
      _$AppDatabase db, $TourStopsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TourStopsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TourStopsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TourStopsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> tourId = const Value.absent(),
            Value<int?> clientId = const Value.absent(),
            Value<String> clientNameSnapshot = const Value.absent(),
            Value<int> orderIndex = const Value.absent(),
            Value<int> estimatedArrivalMinutes = const Value.absent(),
            Value<int> estimatedDepartureMinutes = const Value.absent(),
            Value<List<TourStopPrestation>> plannedPrestations =
                const Value.absent(),
            Value<List<TourStopPrestation>?> actualPrestations =
                const Value.absent(),
            Value<String?> interventionNote = const Value.absent(),
            Value<int> feeShareCents = const Value.absent(),
          }) =>
              TourStopsTableCompanion(
            id: id,
            tourId: tourId,
            clientId: clientId,
            clientNameSnapshot: clientNameSnapshot,
            orderIndex: orderIndex,
            estimatedArrivalMinutes: estimatedArrivalMinutes,
            estimatedDepartureMinutes: estimatedDepartureMinutes,
            plannedPrestations: plannedPrestations,
            actualPrestations: actualPrestations,
            interventionNote: interventionNote,
            feeShareCents: feeShareCents,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int tourId,
            Value<int?> clientId = const Value.absent(),
            required String clientNameSnapshot,
            required int orderIndex,
            required int estimatedArrivalMinutes,
            required int estimatedDepartureMinutes,
            Value<List<TourStopPrestation>> plannedPrestations =
                const Value.absent(),
            Value<List<TourStopPrestation>?> actualPrestations =
                const Value.absent(),
            Value<String?> interventionNote = const Value.absent(),
            required int feeShareCents,
          }) =>
              TourStopsTableCompanion.insert(
            id: id,
            tourId: tourId,
            clientId: clientId,
            clientNameSnapshot: clientNameSnapshot,
            orderIndex: orderIndex,
            estimatedArrivalMinutes: estimatedArrivalMinutes,
            estimatedDepartureMinutes: estimatedDepartureMinutes,
            plannedPrestations: plannedPrestations,
            actualPrestations: actualPrestations,
            interventionNote: interventionNote,
            feeShareCents: feeShareCents,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$TourStopsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({tourId = false, clientId = false}) {
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
                if (tourId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.tourId,
                    referencedTable:
                        $$TourStopsTableTableReferences._tourIdTable(db),
                    referencedColumn:
                        $$TourStopsTableTableReferences._tourIdTable(db).id,
                  ) as T;
                }
                if (clientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clientId,
                    referencedTable:
                        $$TourStopsTableTableReferences._clientIdTable(db),
                    referencedColumn:
                        $$TourStopsTableTableReferences._clientIdTable(db).id,
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

typedef $$TourStopsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TourStopsTableTable,
    TourStopRow,
    $$TourStopsTableTableFilterComposer,
    $$TourStopsTableTableOrderingComposer,
    $$TourStopsTableTableAnnotationComposer,
    $$TourStopsTableTableCreateCompanionBuilder,
    $$TourStopsTableTableUpdateCompanionBuilder,
    (TourStopRow, $$TourStopsTableTableReferences),
    TourStopRow,
    PrefetchHooks Function({bool tourId, bool clientId})>;
typedef $$ManualHistoryEntriesTableTableCreateCompanionBuilder
    = ManualHistoryEntriesTableCompanion Function({
  Value<int> id,
  required int clientId,
  required int date,
  Value<List<TourStopPrestation>> prestations,
  Value<String?> note,
  required int createdAt,
  required int updatedAt,
});
typedef $$ManualHistoryEntriesTableTableUpdateCompanionBuilder
    = ManualHistoryEntriesTableCompanion Function({
  Value<int> id,
  Value<int> clientId,
  Value<int> date,
  Value<List<TourStopPrestation>> prestations,
  Value<String?> note,
  Value<int> createdAt,
  Value<int> updatedAt,
});

final class $$ManualHistoryEntriesTableTableReferences extends BaseReferences<
    _$AppDatabase, $ManualHistoryEntriesTableTable, ManualHistoryEntryRow> {
  $$ManualHistoryEntriesTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $ClientsTableTable _clientIdTable(_$AppDatabase db) =>
      db.clientsTable.createAlias($_aliasNameGenerator(
          db.manualHistoryEntriesTable.clientId, db.clientsTable.id));

  $$ClientsTableTableProcessedTableManager get clientId {
    final $_column = $_itemColumn<int>('client_id')!;

    final manager = $$ClientsTableTableTableManager($_db, $_db.clientsTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_clientIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$ManualHistoryEntriesTableTableFilterComposer
    extends Composer<_$AppDatabase, $ManualHistoryEntriesTableTable> {
  $$ManualHistoryEntriesTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnFilters(column));

  ColumnWithTypeConverterFilters<List<TourStopPrestation>,
          List<TourStopPrestation>, String>
      get prestations => $composableBuilder(
          column: $table.prestations,
          builder: (column) => ColumnWithTypeConverterFilters(column));

  ColumnFilters<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnFilters(column));

  $$ClientsTableTableFilterComposer get clientId {
    final $$ClientsTableTableFilterComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clientsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableTableFilterComposer(
              $db: $db,
              $table: $db.clientsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ManualHistoryEntriesTableTableOrderingComposer
    extends Composer<_$AppDatabase, $ManualHistoryEntriesTableTable> {
  $$ManualHistoryEntriesTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get date => $composableBuilder(
      column: $table.date, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prestations => $composableBuilder(
      column: $table.prestations, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get note => $composableBuilder(
      column: $table.note, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get updatedAt => $composableBuilder(
      column: $table.updatedAt, builder: (column) => ColumnOrderings(column));

  $$ClientsTableTableOrderingComposer get clientId {
    final $$ClientsTableTableOrderingComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clientsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableTableOrderingComposer(
              $db: $db,
              $table: $db.clientsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ManualHistoryEntriesTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $ManualHistoryEntriesTableTable> {
  $$ManualHistoryEntriesTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumnWithTypeConverter<List<TourStopPrestation>, String>
      get prestations => $composableBuilder(
          column: $table.prestations, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$ClientsTableTableAnnotationComposer get clientId {
    final $$ClientsTableTableAnnotationComposer composer = $composerBuilder(
        composer: this,
        getCurrentColumn: (t) => t.clientId,
        referencedTable: $db.clientsTable,
        getReferencedColumn: (t) => t.id,
        builder: (joinBuilder,
                {$addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer}) =>
            $$ClientsTableTableAnnotationComposer(
              $db: $db,
              $table: $db.clientsTable,
              $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
              joinBuilder: joinBuilder,
              $removeJoinBuilderFromRootComposer:
                  $removeJoinBuilderFromRootComposer,
            ));
    return composer;
  }
}

class $$ManualHistoryEntriesTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $ManualHistoryEntriesTableTable,
    ManualHistoryEntryRow,
    $$ManualHistoryEntriesTableTableFilterComposer,
    $$ManualHistoryEntriesTableTableOrderingComposer,
    $$ManualHistoryEntriesTableTableAnnotationComposer,
    $$ManualHistoryEntriesTableTableCreateCompanionBuilder,
    $$ManualHistoryEntriesTableTableUpdateCompanionBuilder,
    (ManualHistoryEntryRow, $$ManualHistoryEntriesTableTableReferences),
    ManualHistoryEntryRow,
    PrefetchHooks Function({bool clientId})> {
  $$ManualHistoryEntriesTableTableTableManager(
      _$AppDatabase db, $ManualHistoryEntriesTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ManualHistoryEntriesTableTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$ManualHistoryEntriesTableTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ManualHistoryEntriesTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> clientId = const Value.absent(),
            Value<int> date = const Value.absent(),
            Value<List<TourStopPrestation>> prestations = const Value.absent(),
            Value<String?> note = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              ManualHistoryEntriesTableCompanion(
            id: id,
            clientId: clientId,
            date: date,
            prestations: prestations,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int clientId,
            required int date,
            Value<List<TourStopPrestation>> prestations = const Value.absent(),
            Value<String?> note = const Value.absent(),
            required int createdAt,
            required int updatedAt,
          }) =>
              ManualHistoryEntriesTableCompanion.insert(
            id: id,
            clientId: clientId,
            date: date,
            prestations: prestations,
            note: note,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$ManualHistoryEntriesTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({clientId = false}) {
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
                if (clientId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.clientId,
                    referencedTable: $$ManualHistoryEntriesTableTableReferences
                        ._clientIdTable(db),
                    referencedColumn: $$ManualHistoryEntriesTableTableReferences
                        ._clientIdTable(db)
                        .id,
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

typedef $$ManualHistoryEntriesTableTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $ManualHistoryEntriesTableTable,
        ManualHistoryEntryRow,
        $$ManualHistoryEntriesTableTableFilterComposer,
        $$ManualHistoryEntriesTableTableOrderingComposer,
        $$ManualHistoryEntriesTableTableAnnotationComposer,
        $$ManualHistoryEntriesTableTableCreateCompanionBuilder,
        $$ManualHistoryEntriesTableTableUpdateCompanionBuilder,
        (ManualHistoryEntryRow, $$ManualHistoryEntriesTableTableReferences),
        ManualHistoryEntryRow,
        PrefetchHooks Function({bool clientId})>;
typedef $$PrestationsTableTableCreateCompanionBuilder
    = PrestationsTableCompanion Function({
  Value<int> id,
  required String name,
  Value<int?> priceCents,
  Value<int?> minutes,
  Value<int?> categoryId,
  Value<int?> archivedAt,
  required int createdAt,
});
typedef $$PrestationsTableTableUpdateCompanionBuilder
    = PrestationsTableCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<int?> priceCents,
  Value<int?> minutes,
  Value<int?> categoryId,
  Value<int?> archivedAt,
  Value<int> createdAt,
});

final class $$PrestationsTableTableReferences extends BaseReferences<
    _$AppDatabase, $PrestationsTableTable, PrestationRow> {
  $$PrestationsTableTableReferences(
      super.$_db, super.$_table, super.$_typedResult);

  static $AnimalCategoriesTableTable _categoryIdTable(_$AppDatabase db) =>
      db.animalCategoriesTable.createAlias($_aliasNameGenerator(
          db.prestationsTable.categoryId, db.animalCategoriesTable.id));

  $$AnimalCategoriesTableTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<int>('category_id');
    if ($_column == null) return null;
    final manager = $$AnimalCategoriesTableTableTableManager(
            $_db, $_db.animalCategoriesTable)
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
        manager.$state.copyWith(prefetchedData: [item]));
  }
}

class $$PrestationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $PrestationsTableTable> {
  $$PrestationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  $$AnimalCategoriesTableTableFilterComposer get categoryId {
    final $$AnimalCategoriesTableTableFilterComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $db.animalCategoriesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AnimalCategoriesTableTableFilterComposer(
                  $db: $db,
                  $table: $db.animalCategoriesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$PrestationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $PrestationsTableTable> {
  $$PrestationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minutes => $composableBuilder(
      column: $table.minutes, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  $$AnimalCategoriesTableTableOrderingComposer get categoryId {
    final $$AnimalCategoriesTableTableOrderingComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $db.animalCategoriesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AnimalCategoriesTableTableOrderingComposer(
                  $db: $db,
                  $table: $db.animalCategoriesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$PrestationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrestationsTableTable> {
  $$PrestationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get priceCents => $composableBuilder(
      column: $table.priceCents, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);

  GeneratedColumn<int> get archivedAt => $composableBuilder(
      column: $table.archivedAt, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$AnimalCategoriesTableTableAnnotationComposer get categoryId {
    final $$AnimalCategoriesTableTableAnnotationComposer composer =
        $composerBuilder(
            composer: this,
            getCurrentColumn: (t) => t.categoryId,
            referencedTable: $db.animalCategoriesTable,
            getReferencedColumn: (t) => t.id,
            builder: (joinBuilder,
                    {$addJoinBuilderToRootComposer,
                    $removeJoinBuilderFromRootComposer}) =>
                $$AnimalCategoriesTableTableAnnotationComposer(
                  $db: $db,
                  $table: $db.animalCategoriesTable,
                  $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                  joinBuilder: joinBuilder,
                  $removeJoinBuilderFromRootComposer:
                      $removeJoinBuilderFromRootComposer,
                ));
    return composer;
  }
}

class $$PrestationsTableTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PrestationsTableTable,
    PrestationRow,
    $$PrestationsTableTableFilterComposer,
    $$PrestationsTableTableOrderingComposer,
    $$PrestationsTableTableAnnotationComposer,
    $$PrestationsTableTableCreateCompanionBuilder,
    $$PrestationsTableTableUpdateCompanionBuilder,
    (PrestationRow, $$PrestationsTableTableReferences),
    PrestationRow,
    PrefetchHooks Function({bool categoryId})> {
  $$PrestationsTableTableTableManager(
      _$AppDatabase db, $PrestationsTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrestationsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrestationsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrestationsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<int?> priceCents = const Value.absent(),
            Value<int?> minutes = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
          }) =>
              PrestationsTableCompanion(
            id: id,
            name: name,
            priceCents: priceCents,
            minutes: minutes,
            categoryId: categoryId,
            archivedAt: archivedAt,
            createdAt: createdAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<int?> priceCents = const Value.absent(),
            Value<int?> minutes = const Value.absent(),
            Value<int?> categoryId = const Value.absent(),
            Value<int?> archivedAt = const Value.absent(),
            required int createdAt,
          }) =>
              PrestationsTableCompanion.insert(
            id: id,
            name: name,
            priceCents: priceCents,
            minutes: minutes,
            categoryId: categoryId,
            archivedAt: archivedAt,
            createdAt: createdAt,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (
                    e.readTable(table),
                    $$PrestationsTableTableReferences(db, table, e)
                  ))
              .toList(),
          prefetchHooksCallback: ({categoryId = false}) {
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
                if (categoryId) {
                  state = state.withJoin(
                    currentTable: table,
                    currentColumn: table.categoryId,
                    referencedTable:
                        $$PrestationsTableTableReferences._categoryIdTable(db),
                    referencedColumn: $$PrestationsTableTableReferences
                        ._categoryIdTable(db)
                        .id,
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

typedef $$PrestationsTableTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $PrestationsTableTable,
    PrestationRow,
    $$PrestationsTableTableFilterComposer,
    $$PrestationsTableTableOrderingComposer,
    $$PrestationsTableTableAnnotationComposer,
    $$PrestationsTableTableCreateCompanionBuilder,
    $$PrestationsTableTableUpdateCompanionBuilder,
    (PrestationRow, $$PrestationsTableTableReferences),
    PrestationRow,
    PrefetchHooks Function({bool categoryId})>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$ClientsTableTableTableManager get clientsTable =>
      $$ClientsTableTableTableManager(_db, _db.clientsTable);
  $$DistanceMatrixTableTableTableManager get distanceMatrixTable =>
      $$DistanceMatrixTableTableTableManager(_db, _db.distanceMatrixTable);
  $$SpeciesTableTableTableManager get speciesTable =>
      $$SpeciesTableTableTableManager(_db, _db.speciesTable);
  $$AnimalCategoriesTableTableTableManager get animalCategoriesTable =>
      $$AnimalCategoriesTableTableTableManager(_db, _db.animalCategoriesTable);
  $$ToursTableTableTableManager get toursTable =>
      $$ToursTableTableTableManager(_db, _db.toursTable);
  $$TourStopsTableTableTableManager get tourStopsTable =>
      $$TourStopsTableTableTableManager(_db, _db.tourStopsTable);
  $$ManualHistoryEntriesTableTableTableManager get manualHistoryEntriesTable =>
      $$ManualHistoryEntriesTableTableTableManager(
          _db, _db.manualHistoryEntriesTable);
  $$PrestationsTableTableTableManager get prestationsTable =>
      $$PrestationsTableTableTableManager(_db, _db.prestationsTable);
}
