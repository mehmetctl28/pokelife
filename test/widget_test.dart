import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokelife/app/app.dart';

void main() {
  testWidgets('PokéLife app loads correctly', (WidgetTester tester) async {
    // SharedPreferences için test ortamı sahte verisi oluşturuluyor
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PokelifeApp());
    await tester.pumpAndSettle();

    // Uygulamanın sorunsuz bir şekilde ayağa kalktığını doğrula
    expect(find.byType(PokelifeApp), findsOneWidget);
  });
}