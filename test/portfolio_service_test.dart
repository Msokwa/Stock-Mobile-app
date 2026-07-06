import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_app/services/portfolio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('mergeHoldingShares increases the share count for the same symbol', () {
    final holdings = <String, int>{'AAPL': 2};

    final updated = mergeHoldingShares(holdings, 'AAPL', 3);

    expect(updated['AAPL'], 5);
  });

  test(
    'mergeHoldingShares removes a symbol when the remaining shares reach zero',
    () {
      final holdings = <String, int>{'AAPL': 2};

      final updated = mergeHoldingShares(holdings, 'AAPL', -2, allowZero: true);

      expect(updated.containsKey('AAPL'), isFalse);
    },
  );
}
