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

  const Settings({
    required this.baseCoordinates,
    required this.baseAddressLabel,
    this.defaultRadiusKm = 15,
    this.defaultMinutesPerSheep = 20,
    this.travelFeeEurosPerBracket = 8,
    this.bracketKm = 10,
    this.themeMode = ThemeModePreference.system,
  });

  Settings copyWith({
    Coordinates? baseCoordinates,
    String? baseAddressLabel,
    int? defaultRadiusKm,
    int? defaultMinutesPerSheep,
    int? travelFeeEurosPerBracket,
    int? bracketKm,
    ThemeModePreference? themeMode,
  }) => Settings(
    baseCoordinates: baseCoordinates ?? this.baseCoordinates,
    baseAddressLabel: baseAddressLabel ?? this.baseAddressLabel,
    defaultRadiusKm: defaultRadiusKm ?? this.defaultRadiusKm,
    defaultMinutesPerSheep: defaultMinutesPerSheep ?? this.defaultMinutesPerSheep,
    travelFeeEurosPerBracket: travelFeeEurosPerBracket ?? this.travelFeeEurosPerBracket,
    bracketKm: bracketKm ?? this.bracketKm,
    themeMode: themeMode ?? this.themeMode,
  );
}
