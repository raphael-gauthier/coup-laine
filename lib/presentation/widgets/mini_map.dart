// lib/presentation/widgets/mini_map.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:forui/forui.dart';
import 'package:latlong2/latlong.dart';

import '../../core/design_tokens.dart';
import 'osm_tile_layer.dart';

/// MiniMap non-interactif (gestures disabled). Affiche une route polyline
/// (ordonnée) + des pins numérotés à chaque waypoint + un pin home pour
/// la base. Auto-fit sur les bounds des waypoints au build initial.
///
/// Réutilisé par Tour detail (overview de la tournée) et Tour draft
/// (preview live pendant la composition — Plan 3).
class MiniMap extends StatefulWidget {
  /// Coordonnées de la base (drop-pin home).
  final LatLng base;

  /// Waypoints ordonnés (ordre des stops). Affichés numérotés 1, 2, 3…
  final List<LatLng> waypoints;

  /// Hauteur fixe du widget.
  final double height;

  /// Optional tap callback — lance typiquement une vue plein-écran.
  final VoidCallback? onTap;

  /// Géométrie complète de la route (issue d'ORS). Si non-null, on trace
  /// cette polyline. Sinon, fallback sur des lignes droites entre `base`
  /// et `waypoints` (et retour à `base`).
  final List<LatLng>? routeGeometry;

  const MiniMap({
    super.key,
    required this.base,
    required this.waypoints,
    this.height = 160,
    this.onTap,
    this.routeGeometry,
  });

  @override
  State<MiniMap> createState() => _MiniMapState();
}

class _MiniMapState extends State<MiniMap> {
  final MapController _ctrl = MapController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  LatLngBounds? _computeBounds() {
    final pts = <LatLng>[widget.base, ...widget.waypoints];
    if (pts.length < 2) return null;
    return LatLngBounds.fromPoints(pts);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final bounds = _computeBounds();

    final markers = <Marker>[
      Marker(
        point: widget.base,
        width: 28,
        height: 28,
        child: Container(
          decoration: BoxDecoration(
            color: theme.colors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: theme.colors.background, width: 2),
          ),
          alignment: Alignment.center,
          child: Icon(FIcons.house,
              color: theme.colors.primaryForeground, size: 14),
        ),
      ),
      for (var i = 0; i < widget.waypoints.length; i++)
        Marker(
          point: widget.waypoints[i],
          width: 24,
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colors.secondary,
              shape: BoxShape.circle,
              border: Border.all(color: theme.colors.background, width: 1.5),
            ),
            alignment: Alignment.center,
            child: Text(
              '${i + 1}',
              style: theme.typography.xs.copyWith(
                color: theme.colors.secondaryForeground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppBorderRadius.md),
          border: Border.all(
            color: theme.colors.border,
            width: AppSizes.hairlineBorder,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          mapController: _ctrl,
          options: MapOptions(
            initialCameraFit: bounds == null
                ? CameraFit.coordinates(
                    coordinates: [widget.base],
                    maxZoom: 13,
                  )
                : CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(20),
                    maxZoom: 13,
                  ),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            osmTileLayer(),
            // Route polyline : si `routeGeometry` est fourni, on trace la
            // vraie route ORS ; sinon fallback sur des segments droits
            // entre la base et les waypoints (et retour).
            if (widget.routeGeometry != null &&
                widget.routeGeometry!.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: widget.routeGeometry!,
                    color: theme.colors.primary,
                    strokeWidth: 3,
                  ),
                ],
              )
            else if (widget.waypoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [widget.base, ...widget.waypoints, widget.base],
                    color: theme.colors.primary,
                    strokeWidth: 3,
                  ),
                ],
              ),
            MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
