class StockDetailsApi {
  final double currentPrice;
  final double change;
  final double percentChange;
  final double highPrice;
  final double lowPrice;
  final double openPrice;
  final double previousClose;
  final DateTime timestamp;

  StockDetailsApi({
    required this.currentPrice,
    required this.change,
    required this.percentChange,
    required this.highPrice,
    required this.lowPrice,
    required this.openPrice,
    required this.previousClose,
    required this.timestamp,
  });

  // Factory constructor matching the raw values exactly from your image
  factory StockDetailsApi.fromJson(Map<String, dynamic> json) {
    return StockDetailsApi(
      currentPrice: json['c'] ,
      change: json['d'], 
      percentChange: json['dp'], 
      highPrice: json['h'],
      lowPrice: json['l'] ,
      openPrice: json['o'] ,
      previousClose: json['pc'] ,
      timestamp: json['t'] ,
    );
  }
}
