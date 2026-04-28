import 'coordinates.dart';

enum ThemeModePreference { system, light, dark }

class Settings {
  final Coordinates baseCoordinates;
  final String baseAddressLabel;
  final int defaultRadiusKm;
  final int defaultMinutesPerSheep;
  final int travelFeeEurosPerBracket;
  final int bracketKm;
  final ThemeModePreference themeMode;
  final String markerDefaultColor;
  final String markerWaitingColor;
  final String markerOverdueColor;
  final String markerRecomputeColor;

  const Settings({
    required this.baseCoordinates,
    required this.baseAddressLabel,
    this.defaultRadiusKm = 15,
    this.defaultMinutesPerSheep = 20,
    this.travelFeeEurosPerBracket = 8,
    this.bracketKm = 10,
    this.themeMode = ThemeModePreference.system,
    this.markerDefaultColor = '#4A6B52',
    this.markerWaitingColor = '#C77B5C',
    this.markerOverdueColor = '#B33A3A',
    this.markerRecomputeColor = '#A89F92',
  });

  Settings copyWith({
    Coordinates? baseCoordinates,
    String? baseAddressLabel,
    int? defaultRadiusKm,
    int? defaultMinutesPerSheep,
    int? travelFeeEurosPerBracket,
    int? bracketKm,
    ThemeModePreference? themeMode,
    String? markerDefaultColor,
    String? markerWaitingColor,
    String? markerOverdueColor,
    String? markerRecomputeColor,
  }) => Settings(
    baseCoordinates: baseCoordinates ?? this.baseCoordinates,
    baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
    defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
    defaultMinutesPerSheep: defaultMinutesPerSheep ?? this.defaultMinutesPerSheep,
    travelFeeEurosPerBracket: travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
    bracketKm: bracketKm ?? this.bracketKm,
    themeMode: themeMode ?? this.themeMode,
    markerDefaultColor: markerDefaultColor ?? this.markerDefaultColor,
    markerWaitingColor: markerWaitingColor ?? this.markerWaitingColor,
    markerOverdueColor: markerOverdueColor ?? this.markerOverdueColor,
    markerRecomputeColor: markerRecomputeColor ?? this.markerRecomputeColor,
  );
}
