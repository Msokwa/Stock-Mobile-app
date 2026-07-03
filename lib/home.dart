// import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/services/env.dart';
import 'package:stock_app/stock.dart';
import 'package:stock_app/stockdetails.dart';
import 'country.dart';
import 'news.dart';
import 'notifications.dart';
import 'portfolio.dart';
import 'pro.dart';
import 'account.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'package:stock_app/services/location_service.dart';
import 'package:stock_app/main.dart';
import 'package:stock_app/charts/charts1.dart';
import 'package:stock_app/charts/charts2.dart';
import 'package:stock_app/charts/charts3.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  String _greeting = 'Good morning there';
  String _country = 'United States';
  List<Map<String, String>> _trendingStocks = [];
  DateTime? _trendingUpdatedAt;

  @override
  void initState() {
    super.initState();
    _loadHomeDetails();
  }

  String _formatUpdatedAt(DateTime dateTime) {
    final time = TimeOfDay.fromDateTime(dateTime);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  final String _finnhubApiKey = Env.finnhubApiKey;

  Future<void> _loadHomeDetails() async {
    String name = 'there';
    String country = await LocationService.getSavedCountry();

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profile = await supabase
            .from('profiles')
            .select('username')
            .eq('id', user.id)
            .maybeSingle();

        if (profile != null && profile['username'] != null) {
          name = profile['username'].toString();
        } else {
          name =
              user.userMetadata?['full_name']?.toString() ??
              user.email?.split('@').first ??
              'there';
        }
      }
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _country = country;
      _greeting = LocationService.buildGreeting(DateTime.now(), name);
      _trendingStocks = LocationService.resolveTrendingStocks(country);
    });

    await _refreshTrendingQuotes();
  }

  Future<void> _openCountryPicker() async {
    final selectedCountry = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Country()),
    );

    if (!mounted) return;

    if (selectedCountry is String && selectedCountry.isNotEmpty) {
      await LocationService.saveCountry(selectedCountry);
      setState(() {
        _country = selectedCountry;
        _trendingStocks = LocationService.resolveTrendingStocks(
          selectedCountry,
        );
      });
    } else {
      final savedCountry = await LocationService.getSavedCountry();
      setState(() {
        _country = savedCountry;
        _trendingStocks = LocationService.resolveTrendingStocks(savedCountry);
      });
    }

    await _refreshTrendingQuotes();
  }

  Future<void> _refreshTrendingQuotes() async {
    if (_trendingStocks.isEmpty) return;

    final updatedStocks = <Map<String, String>>[];

    for (final stock in _trendingStocks) {
      final symbol = stock['symbol'] ?? '';
      if (symbol.isEmpty) {
        updatedStocks.add(stock);
        continue;
      }

      try {
        final quoteUrl = Uri.parse(
          'https://finnhub.io/api/v1/quote'
          '?symbol=${Uri.encodeQueryComponent(symbol)}'
          '&token=$_finnhubApiKey',
        );
        final response = await http
            .get(quoteUrl)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () => throw TimeoutException('API request timed out'),
            );
        if (response.statusCode != 200) {
          debugPrint('Failed to fetch $symbol: ${response.statusCode}');
          updatedStocks.add(stock);
          continue;
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final current = (data['c'] as num?)?.toDouble();
        final change = (data['dp'] as num?)?.toDouble();

        updatedStocks.add({
          'symbol': symbol,
          'name': stock['name'] ?? symbol,
          'price': current != null
              ? current.toStringAsFixed(2)
              : stock['price']!,
          'change': change != null
              ? '${change >= 0 ? '+' : ''}${change.toStringAsFixed(2)}%'
              : stock['change']!,
        });
      } catch (e) {
        debugPrint('Error fetching quote for $symbol: $e');
        updatedStocks.add(stock);
      }
    }

    if (!mounted) return;
    setState(() {
      _trendingStocks = updatedStocks;
      _trendingUpdatedAt = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF011625),
          child: ListView(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: const Color(0xFF011625)),
                child: const Center(
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Padding(padding: const EdgeInsets.all(8)),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  color: Colors.transparent,
                ),
                child: const ListTile(
                  leading: Icon(Icons.person),
                  title: Text(
                    'Account Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  color: Colors.transparent,
                ),
                child: const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text(
                    'Account Information',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  color: Colors.transparent,
                ),
                child: const ListTile(
                  leading: Icon(Icons.lock),
                  title: Text(
                    'Security',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  color: Colors.transparent,
                ),
                child: const ListTile(
                  leading: Icon(Icons.settings),
                  title: Text(
                    'Preferences',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  color: Colors.transparent,
                ),
                child: const ListTile(
                  leading: Icon(Icons.attach_money),
                  title: Text(
                    'Currency',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  color: Colors.transparent,
                ),
                child: const ListTile(
                  leading: Icon(Icons.brightness_6),
                  title: Text(
                    'Theme',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey),
                  color: Colors.transparent,
                ),
                child: const ListTile(
                  leading: Icon(Icons.info),
                  title: Text(
                    'About StockScope',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 20),
          child: GNav(
            backgroundColor: const Color(0xFF091625),
            color: Colors.white,
            activeColor: Colors.black,
            tabBackgroundColor: const Color.fromARGB(255, 91, 90, 90),
            padding: EdgeInsets.all(16),
            gap: 8,
            selectedIndex: 0,
            onTabChange: (index) {
              if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => News()),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Portfolio()),
                );
              } else if (index == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Pro()),
                );
              } else if (index == 4) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => Account()),
                );
              }
            },
            tabs: [
              GButton(icon: Icons.home, text: 'Home'),
              GButton(icon: Icons.article, text: 'News'),
              GButton(icon: Icons.pie_chart, text: 'Portfolio'),
              GButton(icon: Icons.star, text: 'Pro'),
              GButton(icon: Icons.person, text: 'Account'),
            ],
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: const Color(0xFF091625),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => Notifications()),
              );
            },
            icon: const Icon(Icons.notifications),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    _greeting,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.waving_hand, color: Colors.yellow),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _openCountryPicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF091625),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white12, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      Text(
                        LocationService.getFlagEmoji(_country),
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _country,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.location_on,
                        color: Colors.green,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              // const SizedBox(height: 12),
              // const Text(
              //   'Summary',
              //   style: TextStyle(
              //     color: Colors.white70,
              //     fontSize: 12,
              //     fontWeight: FontWeight.w500,
              //   ),
              // ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildChartContainer(
                    'DAX',
                    '16,247.94',
                    '+1.35%',
                    const Chart1(),
                  ),
                  _buildChartContainer(
                    'NASDAQ',
                    '16,920.79',
                    '+0.42%',
                    const Chart2(),
                  ),
                  _buildChartContainer(
                    'S&P 500',
                    '5,325.28',
                    '+0.72%',
                    const Chart3(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Spacer(),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trending stocks',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                            if (_trendingUpdatedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Live • Updated ${_formatUpdatedAt(_trendingUpdatedAt!)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Stock(),
                            ),
                          );
                        },
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: _trendingStocks
                        .map((stock) => _buildTrendingStockTile(stock))
                        .toList(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartContainer(
    String label,
    String value,
    String change,
    Widget destination,
  ) {
    final isPositive = change.startsWith('+');
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      },
      child: Container(
        height: 78,
        width: 85,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF091625),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              change,
              style: TextStyle(
                color: isPositive ? const Color(0xFF2BAB4A) : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingStockTile(Map<String, String> stock) {
    final symbol = stock['symbol'] ?? '';
    final name = stock['name'] ?? '';
    final price = stock['price'] ?? '';
    final change = stock['change'] ?? '';
    final isPositive = change.startsWith('+');

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StockDetails(symbol: symbol, description: name),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 70,
        margin: const EdgeInsets.only(bottom: 12),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF091625),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$name ($symbol)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    change,
                    style: TextStyle(
                      color: isPositive ? Colors.green : Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
