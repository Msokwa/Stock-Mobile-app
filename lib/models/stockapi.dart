class StockApi {
  final String description; // This is the company name (e.g., "Apple Inc")
  final String displaySymbol; // The symbol displayed to the user
  final String symbol; // The actual stock ticker used for API queries
  final String type; // Asset type (e.g., "Common Stock")

  StockApi({
    required this.description,
    required this.displaySymbol,
    required this.symbol,
    required this.type,
  });

  // Factory constructor to parse a single stock object from image_af8557.png
  factory StockApi.fromJson(Map<String, dynamic> json) {
    return StockApi(
      description: json['description'],
      displaySymbol: json['displaySymbol'],
      symbol: json['symbol'],
      type: json['type'],
    );
  }
}
