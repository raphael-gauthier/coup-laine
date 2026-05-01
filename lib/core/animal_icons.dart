// lib/core/animal_icons.dart
//
// Mapping d'une `Species.iconKey` vers un asset SVG custom (silhouette
// animale). Les espèces seed utilisent les clés `mouton`/`cheval`/`bovin`/
// `caprin`. Les espèces custom retournent `null` ; le caller doit utiliser
// un fallback (typiquement `FIcons.pawPrint`).

const _kSpeciesIconAssets = <String, String>{
  'mouton': 'assets/icons/cl_sheep.svg',
  'cheval': 'assets/icons/cl_horse.svg',
  'bovin': 'assets/icons/cl_cow.svg',
  'caprin': 'assets/icons/cl_goat.svg',
};

/// Retourne le chemin de l'asset SVG associé à une `iconKey` d'espèce, ou
/// `null` si la clé est inconnue (custom species, vide).
/// La comparaison est case-insensitive.
String? iconAssetForSpeciesKey(String? key) {
  if (key == null || key.isEmpty) return null;
  return _kSpeciesIconAssets[key.toLowerCase()];
}
