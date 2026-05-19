// ============================================================
// test/widget_test.dart
// Basic widget test para sa login screen
// ============================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:instructor_attendance_monitoring_system/main.dart';

void main() {
  testWidgets('Login screen loads correctly', (WidgetTester tester) async {
    // FIX: Gi-update gikan MyApp -> TCGCApp (mao ang bag-ong class name)
    await tester.pumpWidget(const TCGCApp());
    await tester.pumpAndSettle();

    // I-check kung ang TCGC MONITORING text naa sa screen
    expect(find.text('TCGC MONITORING'), findsOneWidget);

    // I-check kung ang LOGIN button naa
    expect(find.text('LOGIN'), findsOneWidget);
  });
}