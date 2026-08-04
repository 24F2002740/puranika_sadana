import 'package:flutter_test/flutter_test.dart';
import 'package:puranika_sadana/main.dart';

void main() {
  testWidgets('App should load correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PuranikaSadanaApp());

    // Basic check to see if the app starts
    expect(find.byType(PuranikaSadanaApp), findsOneWidget);
  });
}
