import 'package:flutter_test/flutter_test.dart';
import 'package:pokelife/app/app.dart';

void main() {
  testWidgets('PokéLife app loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const PokelifeApp());

    expect(find.text('POKÉLIFE'), findsOneWidget);
  });
}