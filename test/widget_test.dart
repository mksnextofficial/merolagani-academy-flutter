import 'package:flutter_test/flutter_test.dart';
import 'package:merolagani_academy/main.dart';

void main() {
  testWidgets('renders the Merolagani Academy shell', (tester) async {
    await tester.pumpWidget(const MerolaganiAcademyApp());

    expect(find.text('Merolagani Academy'), findsOneWidget);
  });
}
