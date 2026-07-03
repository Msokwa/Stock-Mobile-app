import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:stock_app/home.dart';
import 'package:stock_app/search.dart';
import 'package:stock_app/services/env.dart';
import 'package:stock_app/stockdetails.dart';
import 'package:stock_app/services/location_service.dart';

class Stock extends StatefulWidget {
  const Stock({super.key});

  @override
  State<Stock> createState() => _StockState();
}

class _StockState extends State<Stock> {
  List<Map<String, String>> _trendingStocks = [];
  DateTime? _trendingUpdatedAt;
  final String _finnhubApiKey = Env.finnhubApiKey;

  String _formatUpdatedAt(DateTime dateTime) {
    final time = TimeOfDay.fromDateTime(dateTime);
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:${time.minute.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //APP Bar with search and back icon button
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF191625),
        leading: IconButton(
          iconSize: 23,
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          },
        ),
        actions: [
          // in any widget build()
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final selectedSymbol = await showSearch<String?>(
                context: context,
                delegate: Search(),
              );

              if (selectedSymbol != null) {
                // do something with the selected symbol
                debugPrint('Selected: $selectedSymbol');
              }
            },
          ),
        ],
      ),

      // create the all,stocks Button
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text(
                    'Stocks',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_trendingStocks.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'No trending stocks loaded yet.',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              )
            else ...[
              if (_trendingUpdatedAt != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Live • Updated ${_formatUpdatedAt(_trendingUpdatedAt!)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ..._trendingStocks.map((stock) {
                final symbol = stock['symbol'] ?? '';
                final name = stock['name'] ?? symbol;
                final price = stock['price'] ?? '';
                final change = stock['change'] ?? '';
                final isPositive = change.startsWith('+');
                return Column(
                  children: [
                    _buildStockTile(
                      context,
                      name: name,
                      symbol: symbol,
                      price: price.startsWith(r'\$') ? price : '\$$price',
                      change: change,
                      changeColor: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(height: 10),
                  ],
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadTrendingStocks();
  }

  Future<void> _loadTrendingStocks() async {
    final country = await LocationService.getSavedCountry();
    final stocks = LocationService.resolveTrendingStocks(country);
    if (!mounted) return;
    setState(() {
      _trendingStocks = stocks;
    });
    await _refreshTrendingQuotes();
  }

  Future<void> _refreshTrendingQuotes() async {
    if (_trendingStocks.isEmpty) return;

    final updated = <Map<String, String>>[];

    for (final stock in _trendingStocks) {
      final symbol = stock['symbol'] ?? '';
      if (symbol.isEmpty) {
        updated.add(stock);
        continue;
      }

      try {
        final quoteUrl = Uri.parse(
          'https://finnhub.io/api/v1/quote?symbol=${Uri.encodeQueryComponent(symbol)}&token=$_finnhubApiKey',
        );
        final response = await http.get(quoteUrl);
        if (response.statusCode != 200) {
          updated.add(stock);
          continue;
        }

        final data = json.decode(response.body) as Map<String, dynamic>;
        final current = (data['c'] as num?)?.toDouble();
        final changePct = (data['dp'] as num?)?.toDouble();

        updated.add({
          'symbol': symbol,
          'name': stock['name'] ?? symbol,
          'price': current != null
              ? current.toStringAsFixed(2)
              : (stock['price'] ?? ''),
          'change': changePct != null
              ? '${changePct >= 0 ? '+' : ''}${changePct.toStringAsFixed(2)}%'
              : (stock['change'] ?? ''),
        });
      } catch (_) {
        updated.add(stock);
      }
    }

    if (!mounted) return;
    setState(() {
      _trendingStocks = updated;
      _trendingUpdatedAt = DateTime.now();
    });
  }

  Widget _buildStockTile(
    BuildContext context, {
    required String name,
    required String symbol,
    required String price,
    required String change,
    required Color changeColor,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StockDetails(symbol: symbol, description: name),
          ),
        );
      },
      child: Container(
        height: 70,
        width: 368,
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
                child: Text(
                  '$name ($symbol)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Spacer(),
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
                  const SizedBox(height: 5),
                  Text(
                    change,
                    style: TextStyle(
                      color: changeColor,
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
