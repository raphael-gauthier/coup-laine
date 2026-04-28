import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';

import '../../core/design_tokens.dart';
import '../../infra/services/ban_geocoding_service.dart';
import '../../state/providers.dart';

typedef GeocodingPickedCallback = void Function(GeocodingResult result);

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
  late final TextEditingController _controller;
  Timer? _debounce;
  List<GeocodingResult> _results = const [];
  bool _loading = false;
  String? _error;

  /// Set to the label of the suggestion the user just picked. The next
  /// onChange callback (fired by the controller when we write `r.label`
  /// into it) will see the same value and skip the search — preventing
  /// the dropdown from re-appearing immediately after a pick.
  String? _justPickedLabel;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialLabel);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // After a pick, the TextEditingController may fire its listeners
    // multiple times (text change + selection change). Keep ignoring
    // until the user actually types something different from the
    // picked label.
    if (value == _justPickedLabel) return;
    _justPickedLabel = null;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _search(value));
  }

  Future<void> _search(String q) async {
    final svc = ref.read(banGeocodingServiceProvider);
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final r = await svc.search(q);
      if (!mounted) return;
      setState(() {
        _results = r;
        _loading = false;
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
        _results = const [];
      });
    }
  }

  void _pick(GeocodingResult r) {
    _debounce?.cancel();
    _justPickedLabel = r.label;
    _controller.text = r.label;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _results = const [];
    });
    widget.onPicked(r);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FTextField(
          control: FTextFieldControl.managed(
            controller: _controller,
            onChange: (v) => _onChanged(v.text),
          ),
          label: Text(widget.labelText),
          error: _error != null ? Text(_error!) : null,
          suffixBuilder: _loading
              ? (_, __, ___) => const Padding(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: FCircularProgress(size: FCircularProgressSizeVariant.sm),
                    ),
                  )
              : null,
        ),
        if (_results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: FCard.raw(
              child: Column(
                children: _results
                    .map((r) => FTile(
                          title: Text(r.label),
                          subtitle: Text('${r.postcode} ${r.city}'),
                          onPress: () => _pick(r),
                        ))
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}
