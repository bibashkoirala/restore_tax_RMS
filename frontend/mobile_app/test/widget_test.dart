import 'package:flutter_test/flutter_test.dart';
import 'package:rtms_mobile/main.dart';
import 'package:rtms_mobile/services/mock_ledger_service.dart';

void main() {
  testWidgets('shows login page for username-based access', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(RtmsApp(ledgerService: const MockLedgerService()));
    await tester.pumpAndSettle();

    expect(find.text('RTMS Record Management'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
