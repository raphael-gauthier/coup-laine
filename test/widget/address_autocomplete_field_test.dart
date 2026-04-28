import 'package:coup_laine/infra/services/ban_geocoding_service.dart';
import 'package:coup_laine/presentation/widgets/address_autocomplete_field.dart';
import 'package:coup_laine/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('shows suggestions and emits picked result', (tester) async {
    final mockHttp = MockClient((_) async => http.Response(
        '{"type":"FeatureCollection","features":[{"geometry":{"type":"Point","coordinates":[-3.0,48.5]},"properties":{"label":"1 Rue Test 22000 Saint-Brieuc","postcode":"22000","city":"Saint-Brieuc"}}]}',
        200));

    GeocodingResult? picked;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          httpClientProvider.overrideWithValue(mockHttp),
        ],
        child: MaterialApp(
          builder: (context, child) => FTheme(
            data: FThemes.blue.light.touch,
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: AddressAutocompleteField(
              onPicked: (r) => picked = r,
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), '1 rue test');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
    expect(find.byType(FTile), findsOneWidget);
    await tester.tap(find.byType(FTile));
    await tester.pumpAndSettle();
    expect(picked, isNotNull);
    expect(picked!.postcode, '22000');
  });
}
