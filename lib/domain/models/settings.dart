import 'coordinates.dart';

enum ThemeModePreference { system, light, dark }

class Settings {
  final Coordinates baseCoordinates;
  final String baseAddressLabel;
  final int defaultRadiusKm;
  final int travelFeeEurosPerBracket;
  final int bracketKm;
  final ThemeModePreference themeMode;
  final String markerDefaultColor;
  final String markerWaitingColor;
  final String markerScheduledColor;
  final String markerDoneColor;
  final String markerNoAnimalsColor;
  final String markerBannedColor;
  final DateTime seasonStartedAt;

  const Settings({
    required this.baseCoordinates,
    required this.baseAddressLabel,
    required this.seasonStartedAt,
    this.defaultRadiusKm = 15,
    this.travelFeeEurosPerBracket = 8,
    this.bracketKm = 10,
    this.themeMode = ThemeModePreference.system,
    this.markerDefaultColor = '#9CA3AF',
    this.markerWaitingColor = '#EAB308',
    this.markerScheduledColor = '#65A30D',
    this.markerDoneColor = '#166534',
    this.markerNoAnimalsColor = '#1F2937',
    this.markerBannedColor = '#B91C1C',
  });

  Settings copyWith({
    Coordinates? baseCoordinates,
    String? baseAddressLabel,
    int? defaultRadiusKm,
    int? travelFeeEurosPerBracket,
    int? bracketKm,
    ThemeModePreference? themeMode,
    String? markerDefaultColor,
    String? markerWaitingColor,
    String? markerScheduledColor,
    String? markerDoneColor,
    String? markerNoAnimalsColor,
    String? markerBannedColor,
    DateTime? seasonStartedAt,
  }) =>
      Settings(
        baseCoordinates: baseCoordinates ?? this.baseCoordinates,
        baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
        defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
        travelFeeEurosPerBracket:
            travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
        bracketKm: bracketKm ?? this.bracketKm,
        themeMode: themeMode ?? this.themeMode,
        markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
        markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
        markerScheduledColor:
            markerScheduledColor ?? this.markerScheduledColor,
        markerDoneColor: markerDoneColor ?? this.markerDoneColor,
        markerNoAnimalsColor:
            markerNoAnimalsColor ?? this.markerNoAnimalsColor,
        markerBannedColor: markerBannedColor ?? this.markerBannedColor,
        seasonStartedAt: seasonStartedAt ?? this.seasonStartedAt,
      );
}
