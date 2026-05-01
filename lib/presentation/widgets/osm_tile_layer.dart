// lib/presentation/widgets/osm_tile_layer.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';

/// Tile layer OpenStreetMap par défaut, partagé par toutes les vues `flutter_map`
/// de l'app (Map principale, MiniMap tour detail, vue proximity, picker map).
///
/// `errorTileCallback` silencie le stack trace bruyant en cas d'échec réseau
/// (typique sur émulateur sans Internet ou rate-limit OSM). La tuile reste
/// vide visuellement ; flutter_map réessayera quand elle redevient visible.
TileLayer osmTileLayer() {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'fr.raphaelgauthier.couplaine',
    evictErrorTileStrategy: EvictErrorTileStrategy.notVisible,
    errorTileCallback: (tile, error, stackTrace) {
      // Log discret en debug uniquement — ne propage pas l'exception
      // (qui sinon est capturée par ImageResourceService et crache un stack
      // trace énorme dans la console).
      if (kDebugMode) {
        debugPrint('[osm-tile] failed ${tile.coordinates}: $error');
      }
    },
  );
}
