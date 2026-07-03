import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationService {
  static const _countryKey = 'selected_country';
  static const _defaultCountry = 'Germany';

  static String buildGreeting(DateTime now, String username) {
    final trimmedName = username.trim().isEmpty ? 'there' : username.trim();
    final hour = now.hour;

    if (hour < 12) {
      return 'Good morning $trimmedName';
    }
    if (hour < 18) {
      return 'Good afternoon $trimmedName';
    }
    return 'Good evening $trimmedName';
  }

  static Future<String> getSavedCountry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_countryKey) ?? _defaultCountry;
  }

  static Future<void> saveCountry(String country) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_countryKey, country);
  }

  static Future<String> getCurrentCountryName() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return _defaultCountry;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        return _defaultCountry;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.first;
      final countryName = placemark.country?.trim();
      return countryName != null && countryName.isNotEmpty
          ? countryName
          : _defaultCountry;
    } catch (_) {
      return _defaultCountry;
    }
  }

  static String getFlagEmoji(String country) {
    final normalized = country.toLowerCase();
    if (normalized.contains('germany')) return '🇩🇪';
    if (normalized.contains('united states') ||
        normalized.contains('usa') ||
        normalized.contains('america') ||
        normalized.contains('us')) {
      return '🇺🇸';
    }
    if (normalized.contains('india')) return '🇮🇳';
    if (normalized.contains('uk') ||
        normalized.contains('britain') ||
        normalized.contains('england') ||
        normalized.contains('united kingdom') ||
        normalized.contains('kingdom')) {
      return '🇬🇧';
    }
    if (normalized.contains('canada')) return '🇨🇦';
    if (normalized.contains('france')) return '🇫🇷';
    if (normalized.contains('japan')) return '🇯🇵';
    if (normalized.contains('south africa')) return '🇿🇦';
    if (normalized.contains('australia')) return '🇦🇺';
    return '🌍';
  }

  static String resolveNewsSymbol(String country) {
    final normalized = country.toLowerCase();
    if (normalized.contains('germany')) return 'SAP.DE';
    if (normalized.contains('united states') ||
        normalized.contains('usa') ||
        normalized.contains('america')) {
      return 'AAPL';
    }
    if (normalized.contains('india')) return 'RELIANCE.NS';
    if (normalized.contains('uk') ||
        normalized.contains('britain') ||
        normalized.contains('england')) {
      return 'TSCO.L';
    }
    if (normalized.contains('japan')) return '7203.T';
    if (normalized.contains('canada')) return 'SHOP.TO';
    return 'AAPL';
  }

  static List<Map<String, String>> resolveTrendingStocks(String country) {
    final normalized = country.toLowerCase();
    if (normalized.contains('germany')) {
      return [
        {
          'symbol': 'SAP.DE',
          'name': 'SAP SE',
          'price': '141.22',
          'change': '+0.45%',
        },
        {
          'symbol': 'BMW.DE',
          'name': 'BMW AG',
          'price': '87.34',
          'change': '+0.26%',
        },
        {
          'symbol': 'ALV.DE',
          'name': 'Allianz SE',
          'price': '212.10',
          'change': '+0.33%',
        },
      ];
    }
    if (normalized.contains('united states') ||
        normalized.contains('usa') ||
        normalized.contains('america')) {
      return [
        {
          'symbol': 'AAPL',
          'name': 'Apple Inc.',
          'price': '175.43',
          'change': '+1.28%',
        },
        {
          'symbol': 'TSLA',
          'name': 'Tesla Inc.',
          'price': '182.63',
          'change': '-1.32%',
        },
        {
          'symbol': 'NVDA',
          'name': 'NVIDIA Corp.',
          'price': '950.02',
          'change': '+2.31%',
        },
      ];
    }
    if (normalized.contains('india')) {
      return [
        {
          'symbol': 'RELIANCE.NS',
          'name': 'Reliance Industries',
          'price': '2,532.25',
          'change': '+0.49%',
        },
        {
          'symbol': 'TCS.NS',
          'name': 'TCS',
          'price': '3,750.10',
          'change': '+0.78%',
        },
        {
          'symbol': 'INFY.NS',
          'name': 'Infosys',
          'price': '1,266.80',
          'change': '+0.35%',
        },
      ];
    }
    if (normalized.contains('uk') ||
        normalized.contains('britain') ||
        normalized.contains('england')) {
      return [
        {
          'symbol': 'TSCO.L',
          'name': 'Tesco PLC',
          'price': '2.57',
          'change': '+0.23%',
        },
        {
          'symbol': 'HSBA.L',
          'name': 'HSBC Holdings',
          'price': '6.35',
          'change': '+0.10%',
        },
        {
          'symbol': 'BP.L',
          'name': 'BP PLC',
          'price': '3.01',
          'change': '+0.18%',
        },
      ];
    }
    if (normalized.contains('japan')) {
      return [
        {
          'symbol': '7203.T',
          'name': 'Toyota Motor',
          'price': '2,011.00',
          'change': '+0.12%',
        },
        {
          'symbol': '6758.T',
          'name': 'Sony Group',
          'price': '12,540.00',
          'change': '-0.07%',
        },
        {
          'symbol': '9984.T',
          'name': 'SoftBank',
          'price': '5,432.00',
          'change': '+0.35%',
        },
      ];
    }
    if (normalized.contains('canada')) {
      return [
        {
          'symbol': 'SHOP.TO',
          'name': 'Shopify',
          'price': '47.78',
          'change': '+1.14%',
        },
        {
          'symbol': 'ENB.TO',
          'name': 'Enbridge',
          'price': '58.20',
          'change': '+0.34%',
        },
        {
          'symbol': 'BNS.TO',
          'name': 'Bank of Nova Scotia',
          'price': '70.10',
          'change': '+0.22%',
        },
      ];
    }
    if (normalized.contains('france')) {
      return [
        {
          'symbol': 'AIR.PA',
          'name': 'Airbus',
          'price': '108.40',
          'change': '+0.19%',
        },
        {
          'symbol': 'SAN.PA',
          'name': 'Sanofi',
          'price': '116.50',
          'change': '+0.14%',
        },
        {
          'symbol': 'BNP.PA',
          'name': 'BNP Paribas',
          'price': '54.20',
          'change': '+0.10%',
        },
      ];
    }
    if (normalized.contains('australia')) {
      return [
        {
          'symbol': 'CBA.AX',
          'name': 'Commonwealth Bank',
          'price': '98.90',
          'change': '+0.20%',
        },
        {
          'symbol': 'BHP.AX',
          'name': 'BHP Group',
          'price': '44.50',
          'change': '+0.28%',
        },
        {
          'symbol': 'WES.AX',
          'name': 'Wesfarmers',
          'price': '52.10',
          'change': '+0.17%',
        },
      ];
    }
    return [
      {
        'symbol': 'AAPL',
        'name': 'Apple Inc.',
        'price': '175.43',
        'change': '+1.28%',
      },
      {
        'symbol': 'TSLA',
        'name': 'Tesla Inc.',
        'price': '182.63',
        'change': '-1.32%',
      },
      {
        'symbol': 'NVDA',
        'name': 'NVIDIA Corp.',
        'price': '950.02',
        'change': '+2.31%',
      },
    ];
  }
}
