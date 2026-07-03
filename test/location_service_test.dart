import 'package:flutter_test/flutter_test.dart';
import 'package:stock_app/services/location_service.dart';

void main() {
  group('LocationService', () {
    test('builds a greeting based on time and username', () {
      expect(
        LocationService.buildGreeting(DateTime(2025, 1, 1, 8), 'Alex'),
        'Good morning Alex',
      );
      expect(
        LocationService.buildGreeting(DateTime(2025, 1, 1, 18), 'Alex'),
        'Good evening Alex',
      );
    });

    test('maps countries to a finance symbol for news', () {
      expect(LocationService.resolveNewsSymbol('Germany'), 'SAP.DE');
      expect(LocationService.resolveNewsSymbol('United States'), 'AAPL');
      expect(LocationService.resolveNewsSymbol('Unknown Country'), 'AAPL');
    });
  });
}
