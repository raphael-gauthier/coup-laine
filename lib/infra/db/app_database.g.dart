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
  static const VerificationMeta _defaultMinutesPerSheepMeta =
      const VerificationMeta('defaultMinutesPerSheep');
  @override
  late final GeneratedColumn<int> defaultMinutesPerSheep = GeneratedColumn<int>(
      'default_minutes_per_sheep', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(20));
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
  static const VerificationMeta _markerNoSheepColorMeta =
      const VerificationMeta('markerNoSheepColor');
  @override
  late final GeneratedColumn<String> markerNoSheepColor =
      GeneratedColumn<String>('marker_no_sheep_color', aliasedName, false,
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
        defaultMinutesPerSheep,
        travelFeeEurosPerBracket,
        bracketKm,
        themeMode,
        markerDefaultColor,
        markerWaitingColor,
        markerScheduledColor,
        markerDoneColor,
        markerNoSheepColor,
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
    if (data.containsKey('default_minutes_per_sheep')) {
      context.handle(
          _defaultMinutesPerSheepMeta,
          defaultMinutesPerSheep.isAcceptableOrUnknown(
              data['default_minutes_per_sheep']!, _defaultMinutesPerSheepMeta));
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
    if (data.containsKey('marker_no_sheep_color')) {
      context.handle(
          _markerNoSheepColorMeta,
          markerNoSheepColor.isAcceptableOrUnknown(
              data['marker_no_sheep_color']!, _markerNoSheepColorMeta));
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
      defaultMinutesPerSheep: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}default_minutes_per_sheep'])!,
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
      markerNoSheepColor: attachedDatabase.typeMapping.read(DriftSqlType.string,
          data['${effectivePrefix}marker_no_sheep_color'])!,
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
  final int defaultMinutesPerSheep;
  final int travelFeeEurosPerBracket;
  final int bracketKm;
  final String themeMode;
  final String markerDefaultColor;
  final String markerWaitingColor;
  final String markerScheduledColor;
  final String markerDoneColor;
  final String markerNoSheepColor;
  final String markerBannedColor;
  final int seasonStartedAt;
  const SettingsRow(
      {required this.id,
      required this.baseAddressLabel,
      required this.baseLat,
      required this.baseLon,
      required this.defaultRadiusKm,
      required this.defaultMinutesPerSheep,
      required this.travelFeeEurosPerBracket,
      required this.bracketKm,
      required this.themeMode,
      required this.markerDefaultColor,
      required this.markerWaitingColor,
      required this.markerScheduledColor,
      required this.markerDoneColor,
      required this.markerNoSheepColor,
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
    map['default_minutes_per_sheep'] = Variable<int>(defaultMinutesPerSheep);
    map['travel_fee_euros_per_bracket'] =
        Variable<int>(travelFeeEurosPerBracket);
    map['bracket_km'] = Variable<int>(bracketKm);
    map['theme_mode'] = Variable<String>(themeMode);
    map['marker_default_color'] = Variable<String>(markerDefaultColor);
    map['marker_waiting_color'] = Variable<String>(markerWaitingColor);
    map['marker_scheduled_color'] = Variable<String>(markerScheduledColor);
    map['marker_done_color'] = Variable<String>(markerDoneColor);
    map['marker_no_sheep_color'] = Variable<String>(markerNoSheepColor);
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
      defaultMinutesPerSheep: Value(defaultMinutesPerSheep),
      travelFeeEurosPerBracket: Value(travelFeeEurosPerBracket),
      bracketKm: Value(bracketKm),
      themeMode: Value(themeMode),
      markerDefaultColor: Value(markerDefaultColor),
      markerWaitingColor: Value(markerWaitingColor),
      markerScheduledColor: Value(markerScheduledColor),
      markerDoneColor: Value(markerDoneColor),
      markerNoSheepColor: Value(markerNoSheepColor),
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
      defaultMinutesPerSheep:
          serializer.fromJson<int>(json['defaultMinutesPerSheep']),
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
      markerNoSheepColor:
          serializer.fromJson<String>(json['markerNoSheepColor']),
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
      'defaultMinutesPerSheep': serializer.toJson<int>(defaultMinutesPerSheep),
      'travelFeeEurosPerBracket':
          serializer.toJson<int>(travelFeeEurosPerBracket),
      'bracketKm': serializer.toJson<int>(bracketKm),
      'themeMode': serializer.toJson<String>(themeMode),
      'markerDefaultColor': serializer.toJson<String>(markerDefaultColor),
      'markerWaitingColor': serializer.toJson<String>(markerWaitingColor),
      'markerScheduledColor': serializer.toJson<String>(markerScheduledColor),
      'markerDoneColor': serializer.toJson<String>(markerDoneColor),
      'markerNoSheepColor': serializer.toJson<String>(markerNoSheepColor),
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
          int? defaultMinutesPerSheep,
          int? travelFeeEurosPerBracket,
          int? bracketKm,
          String? themeMode,
          String? markerDefaultColor,
          String? markerWaitingColor,
          String? markerScheduledColor,
          String? markerDoneColor,
          String? markerNoSheepColor,
          String? markerBannedColor,
          int? seasonStartedAt}) =>
      SettingsRow(
        id: id ?? this.id,
        baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
        baseLat: baseLat ?? this.baseLat,
        baseLon: baseLon ?? this.baseLon,
        defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
        defaultMinutesPerSheep:
            defaultMinutesPerSheep ?? this.defaultMinutesPerSheep,
        travelFeeEurosPerBracket:
            travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
        bracketKm: bracketKm ?? this.bracketKm,
        themeMode: themeMode ?? this.themeMode,
        markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
        markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
        markerScheduledColor: markerScheduledColor ?? this.markerScheduledColor,
        markerDoneColor: markerDoneColor ?? this.markerDoneColor,
        markerNoSheepColor: markerNoSheepColor ?? this.markerNoSheepColor,
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
      defaultMinutesPerSheep: data.defaultMinutesPerSheep.present
          ? data.defaultMinutesPerSheep.value
          : this.defaultMinutesPerSheep,
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
      markerNoSheepColor: data.markerNoSheepColor.present
          ? data.markerNoSheepColor.value
          : this.markerNoSheepColor,
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
          ..write('defaultMinutesPerSheep: $defaultMinutesPerSheep, ')
          ..write('travelFeeEurosPerBracket: $travelFeeEurosPerBracket, ')
          ..write('bracketKm: $bracketKm, ')
          ..write('themeMode: $themeMode, ')
          ..write('markerDefaultColor: $markerDefaultColor, ')
          ..write('markerWaitingColor: $markerWaitingColor, ')
          ..write('markerScheduledColor: $markerScheduledColor, ')
          ..write('markerDoneColor: $markerDoneColor, ')
          ..write('markerNoSheepColor: $markerNoSheepColor, ')
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
      defaultMinutesPerSheep,
      travelFeeEurosPerBracket,
      bracketKm,
      themeMode,
      markerDefaultColor,
      markerWaitingColor,
      markerScheduledColor,
      markerDoneColor,
      markerNoSheepColor,
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
          other.defaultMinutesPerSheep == this.defaultMinutesPerSheep &&
          other.travelFeeEurosPerBracket == this.travelFeeEurosPerBracket &&
          other.bracketKm == this.bracketKm &&
          other.themeMode == this.themeMode &&
          other.markerDefaultColor == this.markerDefaultColor &&
          other.markerWaitingColor == this.markerWaitingColor &&
          other.markerScheduledColor == this.markerScheduledColor &&
          other.markerDoneColor == this.markerDoneColor &&
          other.markerNoSheepColor == this.markerNoSheepColor &&
          other.markerBannedColor == this.markerBannedColor &&
          other.seasonStartedAt == this.seasonStartedAt);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<String> baseAddressLabel;
  final Value<double> baseLat;
  final Value<double> baseLon;
  final Value<int> defaultRadiusKm;
  final Value<int> defaultMinutesPerSheep;
  final Value<int> travelFeeEurosPerBracket;
  final Value<int> bracketKm;
  final Value<String> themeMode;
  final Value<String> markerDefaultColor;
  final Value<String> markerWaitingColor;
  final Value<String> markerScheduledColor;
  final Value<String> markerDoneColor;
  final Value<String> markerNoSheepColor;
  final Value<String> markerBannedColor;
  final Value<int> seasonStartedAt;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.baseAddressLabel = const Value.absent(),
    this.baseLat = const Value.absent(),
    this.baseLon = const Value.absent(),
    this.defaultRadiusKm = const Value.absent(),
    this.defaultMinutesPerSheep = const Value.absent(),
    this.travelFeeEurosPerBracket = const Value.absent(),
    this.bracketKm = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.markerDefaultColor = const Value.absent(),
    this.markerWaitingColor = const Value.absent(),
    this.markerScheduledColor = const Value.absent(),
    this.markerDoneColor = const Value.absent(),
    this.markerNoSheepColor = const Value.absent(),
    this.markerBannedColor = const Value.absent(),
    this.seasonStartedAt = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    this.id = const Value.absent(),
    required String baseAddressLabel,
    required double baseLat,
    required double baseLon,
    this.defaultRadiusKm = const Value.absent(),
    this.defaultMinutesPerSheep = const Value.absent(),
    this.travelFeeEurosPerBracket = const Value.absent(),
    this.bracketKm = const Value.absent(),
    this.themeMode = const Value.absent(),
    this.markerDefaultColor = const Value.absent(),
    this.markerWaitingColor = const Value.absent(),
    this.markerScheduledColor = const Value.absent(),
    this.markerDoneColor = const Value.absent(),
    this.markerNoSheepColor = const Value.absent(),
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
    Expression<int>? defaultMinutesPerSheep,
    Expression<int>? travelFeeEurosPerBracket,
    Expression<int>? bracketKm,
    Expression<String>? themeMode,
    Expression<String>? markerDefaultColor,
    Expression<String>? markerWaitingColor,
    Expression<String>? markerScheduledColor,
    Expression<String>? markerDoneColor,
    Expression<String>? markerNoSheepColor,
    Expression<String>? markerBannedColor,
    Expression<int>? seasonStartedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (baseAddressLabel != null) 'base_address_label': baseAddressLabel,
      if (baseLat != null) 'base_lat': baseLat,
      if (baseLon != null) 'base_lon': baseLon,
      if (defaultRadiusKm != null) 'default_radius_km': defaultRadiusKm,
      if (defaultMinutesPerSheep != null)
        'default_minutes_per_sheep': defaultMinutesPerSheep,
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
      if (markerNoSheepColor != null)
        'marker_no_sheep_color': markerNoSheepColor,
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
      Value<int>? defaultMinutesPerSheep,
      Value<int>? travelFeeEurosPerBracket,
      Value<int>? bracketKm,
      Value<String>? themeMode,
      Value<String>? markerDefaultColor,
      Value<String>? markerWaitingColor,
      Value<String>? markerScheduledColor,
      Value<String>? markerDoneColor,
      Value<String>? markerNoSheepColor,
      Value<String>? markerBannedColor,
      Value<int>? seasonStartedAt}) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
      baseLat: baseLat ?? this.baseLat,
      baseLon: baseLon ?? this.baseLon,
      defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
      defaultMinutesPerSheep:
          defaultMinutesPerSheep ?? this.defaultMinutesPerSheep,
      travelFeeEurosPerBracket:
          travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
      bracketKm: bracketKm ?? this.bracketKm,
      themeMode: themeMode ?? this.themeMode,
      markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
      markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
      markerScheduledColor: markerScheduledColor ?? this.markerScheduledColor,
      markerDoneColor: markerDoneColor ?? this.markerDoneColor,
      markerNoSheepColor: markerNoSheepColor ?? this.markerNoSheepColor,
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
    if (defaultMinutesPerSheep.present) {
      map['default_minutes_per_sheep'] =
          Variable<int>(defaultMinutesPerSheep.value);
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
    if (markerNoSheepColor.present) {
      map['marker_no_sheep_color'] = Variable<String>(markerNoSheepColor.value);
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
          ..write('defaultMinutesPerSheep: $defaultMinutesPerSheep, ')
          ..write('travelFeeEurosPerBracket: $travelFeeEurosPerBracket, ')
          ..write('bracketKm: $bracketKm, ')
          ..write('themeMode: $themeMode, ')
          ..write('markerDefaultColor: $markerDefaultColor, ')
          ..write('markerWaitingColor: $markerWaitingColor, ')
          ..write('markerScheduledColor: $markerScheduledColor, ')
          ..write('markerDoneColor: $markerDoneColor, ')
          ..write('markerNoSheepColor: $markerNoSheepColor, ')
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
  static const VerificationMeta _phoneMeta = const VerificationMeta('phone');
  @override
  late final GeneratedColumn<String> phone = GeneratedColumn<String>(
      'phone', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
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
  static const VerificationMeta _sheepCountMeta =
      const VerificationMeta('sheepCount');
  @override
  late final GeneratedColumn<int> sheepCount = GeneratedColumn<int>(
      'sheep_count', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  static const VerificationMeta _minutesPerSheepOverrideMeta =
      const VerificationMeta('minutesPerSheepOverride');
  @override
  late final GeneratedColumn<int> minutesPerSheepOverride =
      GeneratedColumn<int>('minutes_per_sheep_override', aliasedName, true,
          type: DriftSqlType.int, requiredDuringInsert: false);
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
  static const VerificationMeta _lastShearingDateMeta =
      const VerificationMeta('lastShearingDate');
  @override
  late final GeneratedColumn<int> lastShearingDate = GeneratedColumn<int>(
      'last_shearing_date', aliasedName, true,
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
        phone,
        addressLabel,
        postcode,
        city,
        lat,
        lon,
        sheepCount,
        minutesPerSheepOverride,
        markerColorHex,
        isWaiting,
        lastShearingDate,
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
    if (data.containsKey('phone')) {
      context.handle(
          _phoneMeta, phone.isAcceptableOrUnknown(data['phone']!, _phoneMeta));
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
    if (data.containsKey('sheep_count')) {
      context.handle(
          _sheepCountMeta,
          sheepCount.isAcceptableOrUnknown(
              data['sheep_count']!, _sheepCountMeta));
    }
    if (data.containsKey('minutes_per_sheep_override')) {
      context.handle(
          _minutesPerSheepOverrideMeta,
          minutesPerSheepOverride.isAcceptableOrUnknown(
              data['minutes_per_sheep_override']!,
              _minutesPerSheepOverrideMeta));
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
    if (data.containsKey('last_shearing_date')) {
      context.handle(
          _lastShearingDateMeta,
          lastShearingDate.isAcceptableOrUnknown(
              data['last_shearing_date']!, _lastShearingDateMeta));
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
      phone: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}phone']),
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
      sheepCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}sheep_count'])!,
      minutesPerSheepOverride: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}minutes_per_sheep_override']),
      markerColorHex: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}marker_color_hex']),
      isWaiting: attachedDatabase.typeMapping
          .read(DriftSqlType.bool, data['${effectivePrefix}is_waiting'])!,
      lastShearingDate: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}last_shearing_date']),
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
}

class ClientRow extends DataClass implements Insertable<ClientRow> {
  final int id;
  final String name;
  final String? phone;
  final String addressLabel;
  final String postcode;
  final String city;
  final double lat;
  final double lon;
  final int sheepCount;
  final int? minutesPerSheepOverride;
  final String? markerColorHex;
  final bool isWaiting;
  final int? lastShearingDate;
  final bool needsDistanceRecompute;
  final bool isBanned;
  final int createdAt;
  final int updatedAt;
  const ClientRow(
      {required this.id,
      required this.name,
      this.phone,
      required this.addressLabel,
      required this.postcode,
      required this.city,
      required this.lat,
      required this.lon,
      required this.sheepCount,
      this.minutesPerSheepOverride,
      this.markerColorHex,
      required this.isWaiting,
      this.lastShearingDate,
      required this.needsDistanceRecompute,
      required this.isBanned,
      required this.createdAt,
      required this.updatedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || phone != null) {
      map['phone'] = Variable<String>(phone);
    }
    map['address_label'] = Variable<String>(addressLabel);
    map['postcode'] = Variable<String>(postcode);
    map['city'] = Variable<String>(city);
    map['lat'] = Variable<double>(lat);
    map['lon'] = Variable<double>(lon);
    map['sheep_count'] = Variable<int>(sheepCount);
    if (!nullToAbsent || minutesPerSheepOverride != null) {
      map['minutes_per_sheep_override'] =
          Variable<int>(minutesPerSheepOverride);
    }
    if (!nullToAbsent || markerColorHex != null) {
      map['marker_color_hex'] = Variable<String>(markerColorHex);
    }
    map['is_waiting'] = Variable<bool>(isWaiting);
    if (!nullToAbsent || lastShearingDate != null) {
      map['last_shearing_date'] = Variable<int>(lastShearingDate);
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
      phone:
          phone == null && nullToAbsent ? const Value.absent() : Value(phone),
      addressLabel: Value(addressLabel),
      postcode: Value(postcode),
      city: Value(city),
      lat: Value(lat),
      lon: Value(lon),
      sheepCount: Value(sheepCount),
      minutesPerSheepOverride: minutesPerSheepOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(minutesPerSheepOverride),
      markerColorHex: markerColorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(markerColorHex),
      isWaiting: Value(isWaiting),
      lastShearingDate: lastShearingDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastShearingDate),
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
      phone: serializer.fromJson<String?>(json['phone']),
      addressLabel: serializer.fromJson<String>(json['addressLabel']),
      postcode: serializer.fromJson<String>(json['postcode']),
      city: serializer.fromJson<String>(json['city']),
      lat: serializer.fromJson<double>(json['lat']),
      lon: serializer.fromJson<double>(json['lon']),
      sheepCount: serializer.fromJson<int>(json['sheepCount']),
      minutesPerSheepOverride:
          serializer.fromJson<int?>(json['minutesPerSheepOverride']),
      markerColorHex: serializer.fromJson<String?>(json['markerColorHex']),
      isWaiting: serializer.fromJson<bool>(json['isWaiting']),
      lastShearingDate: serializer.fromJson<int?>(json['lastShearingDate']),
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
      'phone': serializer.toJson<String?>(phone),
      'addressLabel': serializer.toJson<String>(addressLabel),
      'postcode': serializer.toJson<String>(postcode),
      'city': serializer.toJson<String>(city),
      'lat': serializer.toJson<double>(lat),
      'lon': serializer.toJson<double>(lon),
      'sheepCount': serializer.toJson<int>(sheepCount),
      'minutesPerSheepOverride':
          serializer.toJson<int?>(minutesPerSheepOverride),
      'markerColorHex': serializer.toJson<String?>(markerColorHex),
      'isWaiting': serializer.toJson<bool>(isWaiting),
      'lastShearingDate': serializer.toJson<int?>(lastShearingDate),
      'needsDistanceRecompute': serializer.toJson<bool>(needsDistanceRecompute),
      'isBanned': serializer.toJson<bool>(isBanned),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ClientRow copyWith(
          {int? id,
          String? name,
          Value<String?> phone = const Value.absent(),
          String? addressLabel,
          String? postcode,
          String? city,
          double? lat,
          double? lon,
          int? sheepCount,
          Value<int?> minutesPerSheepOverride = const Value.absent(),
          Value<String?> markerColorHex = const Value.absent(),
          bool? isWaiting,
          Value<int?> lastShearingDate = const Value.absent(),
          bool? needsDistanceRecompute,
          bool? isBanned,
          int? createdAt,
          int? updatedAt}) =>
      ClientRow(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone.present ? phone.value : this.phone,
        addressLabel: addressLabel ?? this.addressLabel,
        postcode: postcode ?? this.postcode,
        city: city ?? this.city,
        lat: lat ?? this.lat,
        lon: lon ?? this.lon,
        sheepCount: sheepCount ?? this.sheepCount,
        minutesPerSheepOverride: minutesPerSheepOverride.present
            ? minutesPerSheepOverride.value
            : this.minutesPerSheepOverride,
        markerColorHex:
            markerColorHex.present ? markerColorHex.value : this.markerColorHex,
        isWaiting: isWaiting ?? this.isWaiting,
        lastShearingDate: lastShearingDate.present
            ? lastShearingDate.value
            : this.lastShearingDate,
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
      phone: data.phone.present ? data.phone.value : this.phone,
      addressLabel: data.addressLabel.present
          ? data.addressLabel.value
          : this.addressLabel,
      postcode: data.postcode.present ? data.postcode.value : this.postcode,
      city: data.city.present ? data.city.value : this.city,
      lat: data.lat.present ? data.lat.value : this.lat,
      lon: data.lon.present ? data.lon.value : this.lon,
      sheepCount:
          data.sheepCount.present ? data.sheepCount.value : this.sheepCount,
      minutesPerSheepOverride: data.minutesPerSheepOverride.present
          ? data.minutesPerSheepOverride.value
          : this.minutesPerSheepOverride,
      markerColorHex: data.markerColorHex.present
          ? data.markerColorHex.value
          : this.markerColorHex,
      isWaiting: data.isWaiting.present ? data.isWaiting.value : this.isWaiting,
      lastShearingDate: data.lastShearingDate.present
          ? data.lastShearingDate.value
          : this.lastShearingDate,
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
          ..write('phone: $phone, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('postcode: $postcode, ')
          ..write('city: $city, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('sheepCount: $sheepCount, ')
          ..write('minutesPerSheepOverride: $minutesPerSheepOverride, ')
          ..write('markerColorHex: $markerColorHex, ')
          ..write('isWaiting: $isWaiting, ')
          ..write('lastShearingDate: $lastShearingDate, ')
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
      phone,
      addressLabel,
      postcode,
      city,
      lat,
      lon,
      sheepCount,
      minutesPerSheepOverride,
      markerColorHex,
      isWaiting,
      lastShearingDate,
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
          other.phone == this.phone &&
          other.addressLabel == this.addressLabel &&
          other.postcode == this.postcode &&
          other.city == this.city &&
          other.lat == this.lat &&
          other.lon == this.lon &&
          other.sheepCount == this.sheepCount &&
          other.minutesPerSheepOverride == this.minutesPerSheepOverride &&
          other.markerColorHex == this.markerColorHex &&
          other.isWaiting == this.isWaiting &&
          other.lastShearingDate == this.lastShearingDate &&
          other.needsDistanceRecompute == this.needsDistanceRecompute &&
          other.isBanned == this.isBanned &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ClientsTableCompanion extends UpdateCompanion<ClientRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> phone;
  final Value<String> addressLabel;
  final Value<String> postcode;
  final Value<String> city;
  final Value<double> lat;
  final Value<double> lon;
  final Value<int> sheepCount;
  final Value<int?> minutesPerSheepOverride;
  final Value<String?> markerColorHex;
  final Value<bool> isWaiting;
  final Value<int?> lastShearingDate;
  final Value<bool> needsDistanceRecompute;
  final Value<bool> isBanned;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const ClientsTableCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.phone = const Value.absent(),
    this.addressLabel = const Value.absent(),
    this.postcode = const Value.absent(),
    this.city = const Value.absent(),
    this.lat = const Value.absent(),
    this.lon = const Value.absent(),
    this.sheepCount = const Value.absent(),
    this.minutesPerSheepOverride = const Value.absent(),
    this.markerColorHex = const Value.absent(),
    this.isWaiting = const Value.absent(),
    this.lastShearingDate = const Value.absent(),
    this.needsDistanceRecompute = const Value.absent(),
    this.isBanned = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ClientsTableCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.phone = const Value.absent(),
    required String addressLabel,
    required String postcode,
    required String city,
    required double lat,
    required double lon,
    this.sheepCount = const Value.absent(),
    this.minutesPerSheepOverride = const Value.absent(),
    this.markerColorHex = const Value.absent(),
    this.isWaiting = const Value.absent(),
    this.lastShearingDate = const Value.absent(),
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
    Expression<String>? phone,
    Expression<String>? addressLabel,
    Expression<String>? postcode,
    Expression<String>? city,
    Expression<double>? lat,
    Expression<double>? lon,
    Expression<int>? sheepCount,
    Expression<int>? minutesPerSheepOverride,
    Expression<String>? markerColorHex,
    Expression<bool>? isWaiting,
    Expression<int>? lastShearingDate,
    Expression<bool>? needsDistanceRecompute,
    Expression<bool>? isBanned,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (addressLabel != null) 'address_label': addressLabel,
      if (postcode != null) 'postcode': postcode,
      if (city != null) 'city': city,
      if (lat != null) 'lat': lat,
      if (lon != null) 'lon': lon,
      if (sheepCount != null) 'sheep_count': sheepCount,
      if (minutesPerSheepOverride != null)
        'minutes_per_sheep_override': minutesPerSheepOverride,
      if (markerColorHex != null) 'marker_color_hex': markerColorHex,
      if (isWaiting != null) 'is_waiting': isWaiting,
      if (lastShearingDate != null) 'last_shearing_date': lastShearingDate,
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
      Value<String?>? phone,
      Value<String>? addressLabel,
      Value<String>? postcode,
      Value<String>? city,
      Value<double>? lat,
      Value<double>? lon,
      Value<int>? sheepCount,
      Value<int?>? minutesPerSheepOverride,
      Value<String?>? markerColorHex,
      Value<bool>? isWaiting,
      Value<int?>? lastShearingDate,
      Value<bool>? needsDistanceRecompute,
      Value<bool>? isBanned,
      Value<int>? createdAt,
      Value<int>? updatedAt}) {
    return ClientsTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      addressLabel: addressLabel ?? this.addressLabel,
      postcode: postcode ?? this.postcode,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      sheepCount: sheepCount ?? this.sheepCount,
      minutesPerSheepOverride:
          minutesPerSheepOverride ?? this.minutesPerSheepOverride,
      markerColorHex: markerColorHex ?? this.markerColorHex,
      isWaiting: isWaiting ?? this.isWaiting,
      lastShearingDate: lastShearingDate ?? this.lastShearingDate,
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
    if (phone.present) {
      map['phone'] = Variable<String>(phone.value);
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
    if (sheepCount.present) {
      map['sheep_count'] = Variable<int>(sheepCount.value);
    }
    if (minutesPerSheepOverride.present) {
      map['minutes_per_sheep_override'] =
          Variable<int>(minutesPerSheepOverride.value);
    }
    if (markerColorHex.present) {
      map['marker_color_hex'] = Variable<String>(markerColorHex.value);
    }
    if (isWaiting.present) {
      map['is_waiting'] = Variable<bool>(isWaiting.value);
    }
    if (lastShearingDate.present) {
      map['last_shearing_date'] = Variable<int>(lastShearingDate.value);
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
          ..write('phone: $phone, ')
          ..write('addressLabel: $addressLabel, ')
          ..write('postcode: $postcode, ')
          ..write('city: $city, ')
          ..write('lat: $lat, ')
          ..write('lon: $lon, ')
          ..write('sheepCount: $sheepCount, ')
          ..write('minutesPerSheepOverride: $minutesPerSheepOverride, ')
          ..write('markerColorHex: $markerColorHex, ')
          ..write('isWaiting: $isWaiting, ')
          ..write('lastShearingDate: $lastShearingDate, ')
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
  /// 0 = base, otherwise client.id
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
        createdAt
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
      required this.createdAt});
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
          int? createdAt}) =>
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
          ..write('createdAt: $createdAt')
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
      createdAt);
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
          other.createdAt == this.createdAt);
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
      Value<int>? createdAt}) {
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
          ..write('createdAt: $createdAt')
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
  static const VerificationMeta _sheepCountSnapshotMeta =
      const VerificationMeta('sheepCountSnapshot');
  @override
  late final GeneratedColumn<int> sheepCountSnapshot = GeneratedColumn<int>(
      'sheep_count_snapshot', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _minutesPerSheepSnapshotMeta =
      const VerificationMeta('minutesPerSheepSnapshot');
  @override
  late final GeneratedColumn<int> minutesPerSheepSnapshot =
      GeneratedColumn<int>('minutes_per_sheep_snapshot', aliasedName, false,
          type: DriftSqlType.int, requiredDuringInsert: true);
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
        sheepCountSnapshot,
        minutesPerSheepSnapshot,
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
    if (data.containsKey('sheep_count_snapshot')) {
      context.handle(
          _sheepCountSnapshotMeta,
          sheepCountSnapshot.isAcceptableOrUnknown(
              data['sheep_count_snapshot']!, _sheepCountSnapshotMeta));
    } else if (isInserting) {
      context.missing(_sheepCountSnapshotMeta);
    }
    if (data.containsKey('minutes_per_sheep_snapshot')) {
      context.handle(
          _minutesPerSheepSnapshotMeta,
          minutesPerSheepSnapshot.isAcceptableOrUnknown(
              data['minutes_per_sheep_snapshot']!,
              _minutesPerSheepSnapshotMeta));
    } else if (isInserting) {
      context.missing(_minutesPerSheepSnapshotMeta);
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
      sheepCountSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.int, data['${effectivePrefix}sheep_count_snapshot'])!,
      minutesPerSheepSnapshot: attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}minutes_per_sheep_snapshot'])!,
      feeShareCents: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}fee_share_cents'])!,
    );
  }

  @override
  $TourStopsTableTable createAlias(String alias) {
    return $TourStopsTableTable(attachedDatabase, alias);
  }
}

class TourStopRow extends DataClass implements Insertable<TourStopRow> {
  final int id;
  final int tourId;
  final int? clientId;
  final String clientNameSnapshot;
  final int orderIndex;
  final int estimatedArrivalMinutes;
  final int estimatedDepartureMinutes;
  final int sheepCountSnapshot;
  final int minutesPerSheepSnapshot;
  final int feeShareCents;
  const TourStopRow(
      {required this.id,
      required this.tourId,
      this.clientId,
      required this.clientNameSnapshot,
      required this.orderIndex,
      required this.estimatedArrivalMinutes,
      required this.estimatedDepartureMinutes,
      required this.sheepCountSnapshot,
      required this.minutesPerSheepSnapshot,
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
    map['sheep_count_snapshot'] = Variable<int>(sheepCountSnapshot);
    map['minutes_per_sheep_snapshot'] = Variable<int>(minutesPerSheepSnapshot);
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
      sheepCountSnapshot: Value(sheepCountSnapshot),
      minutesPerSheepSnapshot: Value(minutesPerSheepSnapshot),
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
      sheepCountSnapshot: serializer.fromJson<int>(json['sheepCountSnapshot']),
      minutesPerSheepSnapshot:
          serializer.fromJson<int>(json['minutesPerSheepSnapshot']),
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
      'sheepCountSnapshot': serializer.toJson<int>(sheepCountSnapshot),
      'minutesPerSheepSnapshot':
          serializer.toJson<int>(minutesPerSheepSnapshot),
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
          int? sheepCountSnapshot,
          int? minutesPerSheepSnapshot,
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
        sheepCountSnapshot: sheepCountSnapshot ?? this.sheepCountSnapshot,
        minutesPerSheepSnapshot:
            minutesPerSheepSnapshot ?? this.minutesPerSheepSnapshot,
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
      sheepCountSnapshot: data.sheepCountSnapshot.present
          ? data.sheepCountSnapshot.value
          : this.sheepCountSnapshot,
      minutesPerSheepSnapshot: data.minutesPerSheepSnapshot.present
          ? data.minutesPerSheepSnapshot.value
          : this.minutesPerSheepSnapshot,
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
          ..write('sheepCountSnapshot: $sheepCountSnapshot, ')
          ..write('minutesPerSheepSnapshot: $minutesPerSheepSnapshot, ')
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
      sheepCountSnapshot,
      minutesPerSheepSnapshot,
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
          other.sheepCountSnapshot == this.sheepCountSnapshot &&
          other.minutesPerSheepSnapshot == this.minutesPerSheepSnapshot &&
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
  final Value<int> sheepCountSnapshot;
  final Value<int> minutesPerSheepSnapshot;
  final Value<int> feeShareCents;
  const TourStopsTableCompanion({
    this.id = const Value.absent(),
    this.tourId = const Value.absent(),
    this.clientId = const Value.absent(),
    this.clientNameSnapshot = const Value.absent(),
    this.orderIndex = const Value.absent(),
    this.estimatedArrivalMinutes = const Value.absent(),
    this.estimatedDepartureMinutes = const Value.absent(),
    this.sheepCountSnapshot = const Value.absent(),
    this.minutesPerSheepSnapshot = const Value.absent(),
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
    required int sheepCountSnapshot,
    required int minutesPerSheepSnapshot,
    required int feeShareCents,
  })  : tourId = Value(tourId),
        clientNameSnapshot = Value(clientNameSnapshot),
        orderIndex = Value(orderIndex),
        estimatedArrivalMinutes = Value(estimatedArrivalMinutes),
        estimatedDepartureMinutes = Value(estimatedDepartureMinutes),
        sheepCountSnapshot = Value(sheepCountSnapshot),
        minutesPerSheepSnapshot = Value(minutesPerSheepSnapshot),
        feeShareCents = Value(feeShareCents);
  static Insertable<TourStopRow> custom({
    Expression<int>? id,
    Expression<int>? tourId,
    Expression<int>? clientId,
    Expression<String>? clientNameSnapshot,
    Expression<int>? orderIndex,
    Expression<int>? estimatedArrivalMinutes,
    Expression<int>? estimatedDepartureMinutes,
    Expression<int>? sheepCountSnapshot,
    Expression<int>? minutesPerSheepSnapshot,
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
      if (sheepCountSnapshot != null)
        'sheep_count_snapshot': sheepCountSnapshot,
      if (minutesPerSheepSnapshot != null)
        'minutes_per_sheep_snapshot': minutesPerSheepSnapshot,
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
      Value<int>? sheepCountSnapshot,
      Value<int>? minutesPerSheepSnapshot,
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
      sheepCountSnapshot: sheepCountSnapshot ?? this.sheepCountSnapshot,
      minutesPerSheepSnapshot:
          minutesPerSheepSnapshot ?? this.minutesPerSheepSnapshot,
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
    if (sheepCountSnapshot.present) {
      map['sheep_count_snapshot'] = Variable<int>(sheepCountSnapshot.value);
    }
    if (minutesPerSheepSnapshot.present) {
      map['minutes_per_sheep_snapshot'] =
          Variable<int>(minutesPerSheepSnapshot.value);
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
          ..write('sheepCountSnapshot: $sheepCountSnapshot, ')
          ..write('minutesPerSheepSnapshot: $minutesPerSheepSnapshot, ')
          ..write('feeShareCents: $feeShareCents')
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
  late final $ToursTableTable toursTable = $ToursTableTable(this);
  late final $TourStopsTableTable tourStopsTable = $TourStopsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        settingsTable,
        clientsTable,
        distanceMatrixTable,
        toursTable,
        tourStopsTable
      ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules(
        [
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
  Value<int> defaultMinutesPerSheep,
  Value<int> travelFeeEurosPerBracket,
  Value<int> bracketKm,
  Value<String> themeMode,
  Value<String> markerDefaultColor,
  Value<String> markerWaitingColor,
  Value<String> markerScheduledColor,
  Value<String> markerDoneColor,
  Value<String> markerNoSheepColor,
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
  Value<int> defaultMinutesPerSheep,
  Value<int> travelFeeEurosPerBracket,
  Value<int> bracketKm,
  Value<String> themeMode,
  Value<String> markerDefaultColor,
  Value<String> markerWaitingColor,
  Value<String> markerScheduledColor,
  Value<String> markerDoneColor,
  Value<String> markerNoSheepColor,
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

  ColumnFilters<int> get defaultMinutesPerSheep => $composableBuilder(
      column: $table.defaultMinutesPerSheep,
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

  ColumnFilters<String> get markerNoSheepColor => $composableBuilder(
      column: $table.markerNoSheepColor,
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

  ColumnOrderings<int> get defaultMinutesPerSheep => $composableBuilder(
      column: $table.defaultMinutesPerSheep,
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

  ColumnOrderings<String> get markerNoSheepColor => $composableBuilder(
      column: $table.markerNoSheepColor,
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

  GeneratedColumn<int> get defaultMinutesPerSheep => $composableBuilder(
      column: $table.defaultMinutesPerSheep, builder: (column) => column);

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

  GeneratedColumn<String> get markerNoSheepColor => $composableBuilder(
      column: $table.markerNoSheepColor, builder: (column) => column);

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
            Value<int> defaultMinutesPerSheep = const Value.absent(),
            Value<int> travelFeeEurosPerBracket = const Value.absent(),
            Value<int> bracketKm = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> markerDefaultColor = const Value.absent(),
            Value<String> markerWaitingColor = const Value.absent(),
            Value<String> markerScheduledColor = const Value.absent(),
            Value<String> markerDoneColor = const Value.absent(),
            Value<String> markerNoSheepColor = const Value.absent(),
            Value<String> markerBannedColor = const Value.absent(),
            Value<int> seasonStartedAt = const Value.absent(),
          }) =>
              SettingsTableCompanion(
            id: id,
            baseAddressLabel: baseAddressLabel,
            baseLat: baseLat,
            baseLon: baseLon,
            defaultRadiusKm: defaultRadiusKm,
            defaultMinutesPerSheep: defaultMinutesPerSheep,
            travelFeeEurosPerBracket: travelFeeEurosPerBracket,
            bracketKm: bracketKm,
            themeMode: themeMode,
            markerDefaultColor: markerDefaultColor,
            markerWaitingColor: markerWaitingColor,
            markerScheduledColor: markerScheduledColor,
            markerDoneColor: markerDoneColor,
            markerNoSheepColor: markerNoSheepColor,
            markerBannedColor: markerBannedColor,
            seasonStartedAt: seasonStartedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String baseAddressLabel,
            required double baseLat,
            required double baseLon,
            Value<int> defaultRadiusKm = const Value.absent(),
            Value<int> defaultMinutesPerSheep = const Value.absent(),
            Value<int> travelFeeEurosPerBracket = const Value.absent(),
            Value<int> bracketKm = const Value.absent(),
            Value<String> themeMode = const Value.absent(),
            Value<String> markerDefaultColor = const Value.absent(),
            Value<String> markerWaitingColor = const Value.absent(),
            Value<String> markerScheduledColor = const Value.absent(),
            Value<String> markerDoneColor = const Value.absent(),
            Value<String> markerNoSheepColor = const Value.absent(),
            Value<String> markerBannedColor = const Value.absent(),
            Value<int> seasonStartedAt = const Value.absent(),
          }) =>
              SettingsTableCompanion.insert(
            id: id,
            baseAddressLabel: baseAddressLabel,
            baseLat: baseLat,
            baseLon: baseLon,
            defaultRadiusKm: defaultRadiusKm,
            defaultMinutesPerSheep: defaultMinutesPerSheep,
            travelFeeEurosPerBracket: travelFeeEurosPerBracket,
            bracketKm: bracketKm,
            themeMode: themeMode,
            markerDefaultColor: markerDefaultColor,
            markerWaitingColor: markerWaitingColor,
            markerScheduledColor: markerScheduledColor,
            markerDoneColor: markerDoneColor,
            markerNoSheepColor: markerNoSheepColor,
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
  Value<String?> phone,
  required String addressLabel,
  required String postcode,
  required String city,
  required double lat,
  required double lon,
  Value<int> sheepCount,
  Value<int?> minutesPerSheepOverride,
  Value<String?> markerColorHex,
  Value<bool> isWaiting,
  Value<int?> lastShearingDate,
  Value<bool> needsDistanceRecompute,
  Value<bool> isBanned,
  required int createdAt,
  required int updatedAt,
});
typedef $$ClientsTableTableUpdateCompanionBuilder = ClientsTableCompanion
    Function({
  Value<int> id,
  Value<String> name,
  Value<String?> phone,
  Value<String> addressLabel,
  Value<String> postcode,
  Value<String> city,
  Value<double> lat,
  Value<double> lon,
  Value<int> sheepCount,
  Value<int?> minutesPerSheepOverride,
  Value<String?> markerColorHex,
  Value<bool> isWaiting,
  Value<int?> lastShearingDate,
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

  ColumnFilters<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnFilters(column));

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

  ColumnFilters<int> get sheepCount => $composableBuilder(
      column: $table.sheepCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minutesPerSheepOverride => $composableBuilder(
      column: $table.minutesPerSheepOverride,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get markerColorHex => $composableBuilder(
      column: $table.markerColorHex,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<bool> get isWaiting => $composableBuilder(
      column: $table.isWaiting, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lastShearingDate => $composableBuilder(
      column: $table.lastShearingDate,
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

  ColumnOrderings<String> get phone => $composableBuilder(
      column: $table.phone, builder: (column) => ColumnOrderings(column));

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

  ColumnOrderings<int> get sheepCount => $composableBuilder(
      column: $table.sheepCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minutesPerSheepOverride => $composableBuilder(
      column: $table.minutesPerSheepOverride,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get markerColorHex => $composableBuilder(
      column: $table.markerColorHex,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<bool> get isWaiting => $composableBuilder(
      column: $table.isWaiting, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lastShearingDate => $composableBuilder(
      column: $table.lastShearingDate,
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

  GeneratedColumn<String> get phone =>
      $composableBuilder(column: $table.phone, builder: (column) => column);

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

  GeneratedColumn<int> get sheepCount => $composableBuilder(
      column: $table.sheepCount, builder: (column) => column);

  GeneratedColumn<int> get minutesPerSheepOverride => $composableBuilder(
      column: $table.minutesPerSheepOverride, builder: (column) => column);

  GeneratedColumn<String> get markerColorHex => $composableBuilder(
      column: $table.markerColorHex, builder: (column) => column);

  GeneratedColumn<bool> get isWaiting =>
      $composableBuilder(column: $table.isWaiting, builder: (column) => column);

  GeneratedColumn<int> get lastShearingDate => $composableBuilder(
      column: $table.lastShearingDate, builder: (column) => column);

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
    PrefetchHooks Function({bool tourStopsTableRefs})> {
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
            Value<String?> phone = const Value.absent(),
            Value<String> addressLabel = const Value.absent(),
            Value<String> postcode = const Value.absent(),
            Value<String> city = const Value.absent(),
            Value<double> lat = const Value.absent(),
            Value<double> lon = const Value.absent(),
            Value<int> sheepCount = const Value.absent(),
            Value<int?> minutesPerSheepOverride = const Value.absent(),
            Value<String?> markerColorHex = const Value.absent(),
            Value<bool> isWaiting = const Value.absent(),
            Value<int?> lastShearingDate = const Value.absent(),
            Value<bool> needsDistanceRecompute = const Value.absent(),
            Value<bool> isBanned = const Value.absent(),
            Value<int> createdAt = const Value.absent(),
            Value<int> updatedAt = const Value.absent(),
          }) =>
              ClientsTableCompanion(
            id: id,
            name: name,
            phone: phone,
            addressLabel: addressLabel,
            postcode: postcode,
            city: city,
            lat: lat,
            lon: lon,
            sheepCount: sheepCount,
            minutesPerSheepOverride: minutesPerSheepOverride,
            markerColorHex: markerColorHex,
            isWaiting: isWaiting,
            lastShearingDate: lastShearingDate,
            needsDistanceRecompute: needsDistanceRecompute,
            isBanned: isBanned,
            createdAt: createdAt,
            updatedAt: updatedAt,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String name,
            Value<String?> phone = const Value.absent(),
            required String addressLabel,
            required String postcode,
            required String city,
            required double lat,
            required double lon,
            Value<int> sheepCount = const Value.absent(),
            Value<int?> minutesPerSheepOverride = const Value.absent(),
            Value<String?> markerColorHex = const Value.absent(),
            Value<bool> isWaiting = const Value.absent(),
            Value<int?> lastShearingDate = const Value.absent(),
            Value<bool> needsDistanceRecompute = const Value.absent(),
            Value<bool> isBanned = const Value.absent(),
            required int createdAt,
            required int updatedAt,
          }) =>
              ClientsTableCompanion.insert(
            id: id,
            name: name,
            phone: phone,
            addressLabel: addressLabel,
            postcode: postcode,
            city: city,
            lat: lat,
            lon: lon,
            sheepCount: sheepCount,
            minutesPerSheepOverride: minutesPerSheepOverride,
            markerColorHex: markerColorHex,
            isWaiting: isWaiting,
            lastShearingDate: lastShearingDate,
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
    PrefetchHooks Function({bool tourStopsTableRefs})>;
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
  required int sheepCountSnapshot,
  required int minutesPerSheepSnapshot,
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
  Value<int> sheepCountSnapshot,
  Value<int> minutesPerSheepSnapshot,
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

  ColumnFilters<int> get sheepCountSnapshot => $composableBuilder(
      column: $table.sheepCountSnapshot,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get minutesPerSheepSnapshot => $composableBuilder(
      column: $table.minutesPerSheepSnapshot,
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

  ColumnOrderings<int> get sheepCountSnapshot => $composableBuilder(
      column: $table.sheepCountSnapshot,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get minutesPerSheepSnapshot => $composableBuilder(
      column: $table.minutesPerSheepSnapshot,
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

  GeneratedColumn<int> get sheepCountSnapshot => $composableBuilder(
      column: $table.sheepCountSnapshot, builder: (column) => column);

  GeneratedColumn<int> get minutesPerSheepSnapshot => $composableBuilder(
      column: $table.minutesPerSheepSnapshot, builder: (column) => column);

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
            Value<int> sheepCountSnapshot = const Value.absent(),
            Value<int> minutesPerSheepSnapshot = const Value.absent(),
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
            sheepCountSnapshot: sheepCountSnapshot,
            minutesPerSheepSnapshot: minutesPerSheepSnapshot,
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
            required int sheepCountSnapshot,
            required int minutesPerSheepSnapshot,
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
            sheepCountSnapshot: sheepCountSnapshot,
            minutesPerSheepSnapshot: minutesPerSheepSnapshot,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
  $$ClientsTableTableTableManager get clientsTable =>
      $$ClientsTableTableTableManager(_db, _db.clientsTable);
  $$DistanceMatrixTableTableTableManager get distanceMatrixTable =>
      $$DistanceMatrixTableTableTableManager(_db, _db.distanceMatrixTable);
  $$ToursTableTableTableManager get toursTable =>
      $$ToursTableTableTableManager(_db, _db.toursTable);
  $$TourStopsTableTableTableManager get tourStopsTable =>
      $$TourStopsTableTableTableManager(_db, _db.tourStopsTable);
}
