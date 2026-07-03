import 'package:pie_chart/pie_chart.dart';
import 'package:flutter/material.dart';
import 'package:stock_app/home.dart';
import 'package:stock_app/services/portfolio_service.dart';
import 'package:stock_app/stockdetails.dart';

class Portfolio extends StatefulWidget {
  const Portfolio({super.key});

  @override
  State<Portfolio> createState() => _PortfolioState();
}

class _PortfolioState extends State<Portfolio> {
  Map<String, int> holdings = {};
  double totalValue = 0.0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHoldings();
  }

  Future<void> _loadHoldings() async {
    final loaded = await loadPortfolioHoldings();
    final value = await calculatePortfolioValue(loaded);
    if (!mounted) return;
    setState(() {
      holdings = loaded;
      totalValue = value;
      isLoading = false;
    });
  }

  final List<Color> colorlist = [
    const Color(0xFF4BABD0),
    const Color(0xFFEB3A3A),
    const Color(0xFF2BAB4A),
    const Color(0xFFD9D9D9),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final dataMap = <String, double>{};
    holdings.forEach((symbol, shares) {
      dataMap[symbol] = shares.toDouble();
    });
    if (dataMap.isEmpty) {
      dataMap['No holdings'] = 1;
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: const Color(0xFF191625),
        leading: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => Home()),
            );
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: Text(
          'My Portfolio',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: mediaQuery.size.width * 0.7,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          dataMap: dataMap,
                          animationDuration: Duration(milliseconds: 1200),
                          chartLegendSpacing: 32,
                          chartRadius: mediaQuery.size.width / 1.2,
                          colorList: colorlist,
                          initialAngleInDegree: 270,
                          chartType: ChartType.ring,
                          ringStrokeWidth: 60,
                          centerText:
                              'Total value\n\$${totalValue.toStringAsFixed(2)}',
                          centerTextStyle: TextStyle(color: Colors.grey),
                          legendOptions: LegendOptions(
                            showLegendsInRow: false,
                            legendPosition: LegendPosition.right,
                            showLegends: true,
                            legendShape: BoxShape.circle,
                            legendTextStyle: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          chartValuesOptions: ChartValuesOptions(
                            showChartValues: true,

                            showChartValueBackground: false,
                            showChartValuesInPercentage: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(height: 55),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    Text(
                      'Holdings',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 387, height: 1, color: const Color(0xFF374151)),

              const SizedBox(height: 12),
              if (holdings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No holdings yet. Buy a stock to see it here.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                )
              else
                ...holdings.entries.map((entry) {
                  final symbol = entry.key;
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              StockDetails(symbol: symbol, description: symbol),
                        ),
                      );
                    },
                    child: Container(
                      height: 70,
                      width: 368,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF091625),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$symbol (${entry.value} shares)',
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
                                  '\$${entry.value.toDouble().toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Owned',
                                  style: TextStyle(
                                    color: Colors.green,
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
                }),
            ],
          ),
        ),
      ),
    );
  }
}
