import 'coordinates.dart';

enum ThemeModePreference { system, light, dark }

class Settings {
  final Coordinates baseCoordinates;
  final String baseAddressLabel;
  final int defaultRadiusKm;
  final int defaultMinutesPerSmall;
  final int defaultMinutesPerLarge;
  final int travelFeeEurosPerBracket;
  final int bracketKm;
  final ThemeModePreference themeMode;
  final String markerDefaultColor;
  final String markerWaitingColor;
  final String markerScheduledColor;
  final String markerDoneColor;
  final String markerNoSheepColor;
  final String markerBannedColor;
  final DateTime seasonStartedAt;

  const Settings({
    required this.baseCoordinates,
    required this.baseAddressLabel,
    required this.seasonStartedAt,
    this.defaultRadiusKm = 15,
    this.defaultMinutesPerSmall = 8,
    this.defaultMinutesPerLarge = 25,
    this.travelFeeEurosPerBracket = 8,
    this.bracketKm = 10,
    this.themeMode = ThemeModePreference.system,
    this.markerDefaultColor = '#9CA3AF',
    this.markerWaitingColor = '#EAB308',
    this.markerScheduledColor = '#65A30D',
    this.markerDoneColor = '#166534',
    this.markerNoSheepColor = '#1F2937',
    this.markerBannedColor = '#B91C1C',
  });

  Settings copyWith({
    Coordinates? baseCoordinates,
    String? baseAddressLabel,
    int? defaultRadiusKm,
    int? defaultMinutesPerSmall,
    int? defaultMinutesPerLarge,
    int? travelFeeEurosPerBracket,
    int? bracketKm,
    ThemeModePreference? themeMode,
    String? markerDefaultColor,
    String? markerWaitingColor,
    String? markerScheduledColor,
    String? markerDoneColor,
    String? markerNoSheepColor,
    String? markerBannedColor,
    DateTime? seasonStartedAt,
  }) =>
      Settings(
        baseCoordinates: baseCoordinates ?? this.baseCoordinates,
        baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
        defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
        defaultMinutesPerSmall:
            defaultMinutesPerSmall ?? this.defaultMinutesPerSmall,
        defaultMinutesPerLarge:
            defaultMinutesPerLarge ?? this.defaultMinutesPerLarge,
        travelFeeEurosPerBracket:
            travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
        bracketKm: bracketKm ?? this.bracketKm,
        themeMode: themeMode ?? this.themeMode,
        markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
        markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
        markerScheduledColor:
            markerScheduledColor ?? this.markerScheduledColor,
        markerDoneColor: markerDoneColor ?? this.markerDoneColor,
        markerNoSheepColor: markerNoSheepColor ?? this.markerNoSheepColor,
        markerBannedColor: markerBannedColor ?? this.markerBannedColor,
        seasonStartedAt: seasonStartedAt ?? this.seasonStartedAt,
      );
}
