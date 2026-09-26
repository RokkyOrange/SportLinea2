import 'package:flutter_test/flutter_test.dart';
import 'package:sportlinea_app/main.dart';

void main() {
  testWidgets('Приложение запускается', (tester) async {
    await tester.pumpWidget(const SportLineaApp());
    expect(find.byType(SportLineaApp), findsOneWidget);
  });
}
