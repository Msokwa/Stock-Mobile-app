class NewsApi {
  final String category;
  final DateTime datetime;
  final String headline;
  final int id;
  final String image;
  final String related;
  final String source;
  final String summary;
  final String url;

  NewsApi({
    required this.category,
    required this.datetime,
    required this.headline,
    required this.id,
    required this.image,
    required this.related,
    required this.source,
    required this.summary,
    required this.url,
  });
  factory NewsApi.fromJson(Map<String, dynamic> json) {
    return NewsApi(
      category: json['category'] ?? '',
      datetime: DateTime.fromMillisecondsSinceEpoch(
        (json['datetime'] ?? 0) * 1000,
      ),
      headline: json['headline'] ?? '',
      id: json['id'] ?? 0,
      image: json['image'] ?? '',
      related: json['related'] ?? '',
      source: json['source'] ?? '',
      summary: json['summary'] ?? '',
      url: json['url'] ?? '',
    );
  }
}
