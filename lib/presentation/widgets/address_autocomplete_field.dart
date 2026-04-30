import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';

typedef GeocodingPickedCallback = void Function(GeocodingResult result);

/// Address picker built on top of [FAutocomplete] (forui's combo
/// text-field + popover suggestion list).
///
/// `FAutocomplete` reasons in `String`s, but the geocoding service returns
/// rich `GeocodingResult` objects (label + coordinates + postcode + city).
/// We bridge the two by caching the latest filter results in
/// [_resultsByLabel] so that, when the controller's text matches a known
/// label (= the user picked an item), we can recover the full record and
/// hand it back via [onPicked].
class AddressAutocompleteField extends ConsumerStatefulWidget {
  final String? initialLabel;
  final GeocodingPickedCallback onPicked;
  final String labelText;

  const AddressAutocompleteField({
    super.key,
    required this.onPicked,
    this.initialLabel,
    this.labelText = 'Adresse',
  });

  @override
  ConsumerState<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState
    extends ConsumerState<AddressAutocompleteField> {
  final Map<String, GeocodingResult> _resultsByLabel = {};
  late final FAutocompleteController _controller;

  /// Last label we've already reported via onPicked, so we don't
  /// repeatedly fire for the same value (the controller can notify
  /// several times after a pick — text + selection changes).
  String? _lastReportedLabel;

  @override
  void initState() {
    super.initState();
    _controller = FAutocompleteController(text: widget.initialLabel ?? '');
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<Iterable<String>> _filter(String query) async {
    if (query.trim().isEmpty) return const [];
    final svc = ref.read(banGeocodingServiceProvider);
    final results = await svc.search(query);
    // Merge instead of clearing: a previously-fetched label might be the
    // one the user just picked, and FAutocomplete fires the controller
    // listener after we've already issued a new filter for the picked
    // text. Keeping past entries lets the lookup still resolve.
    _resultsByLabel.addEntries(results.map((r) => MapEntry(r.label, r)));
    return results.map((r) => r.label);
  }

  void _onControllerChanged() {
    final text = _controller.text;
    final picked = _resultsByLabel[text];
    if (picked != null && text != _lastReportedLabel) {
      _lastReportedLabel = text;
      widget.onPicked(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FAutocomplete.builder(
      label: Text(widget.labelText),
      filter: _filter,
      // Anchor the suggestions popover ABOVE the field so the on-screen
      // keyboard never covers the results.
      fieldAnchor: AlignmentDirectional.topStart,
      contentAnchor: AlignmentDirectional.bottomStart,
      contentBuilder: (ctx, query, values) => [
        for (final value in values)
          FAutocompleteItem(
            value: value,
            title: Text(value),
            subtitle: () {
              final r = _resultsByLabel[value];
              return r == null ? null : Text('${r.postcode} ${r.city}');
            }(),
          ),
      ],
      control: FAutocompleteControl.managed(controller: _controller),
    );
  }
}
