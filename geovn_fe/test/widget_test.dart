import 'package:flutter_test/flutter_test.dart';

import 'package:geovn_fe/main.dart';

void main() {
  testWidgets('App loads main screen title', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();
    expect(find.text('V-GeoStats'), findsOneWidget);
  });
}
