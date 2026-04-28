import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    _controller.text = r.label;
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
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            errorText: _error,
          ),
          onChanged: _onChanged,
        ),
        if (_results.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              children: _results
                  .map((r) => ListTile(
                        title: Text(r.label),
                        subtitle: Text('${r.postcode} ${r.city}'),
                        onTap: () => _pick(r),
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
