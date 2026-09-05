import 'package:flutter_test/flutter_test.dart';
import 'package:career_twin/main.dart';

void main() {
  testWidgets('CareerTwin starts', (WidgetTester tester) async {
    await tester.pumpWidget(const CareerTwinApp());

    expect(find.text('Let\'s build your CareerTwin'), findsOneWidget);
  });
}