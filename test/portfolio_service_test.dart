import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stock_app/services/portfolio_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('adding a holding increases the stored share count', () async {
    await addPortfolioHolding('AAPL', shares: 2);
    await addPortfolioHolding('AAPL', shares: 3);

    final holdings = await loadPortfolioHoldings();

    expect(holdings['AAPL'], 5);
  });
}
