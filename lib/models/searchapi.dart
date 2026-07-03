class SearchApi {
  
  int? count;
  List<Result>? result;

  SearchApi({this.count, this.result});

  SearchApi.fromJson(Map<String, dynamic> json) {
    count = json['count'];
    if (json['result'] != null) {
      result = <Result>[];
      json['result'].forEach((v) {
        result!.add(Result.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['count'] = count;
    if (result != null) {
      data['result'] = result!.map((v) => v.toJson()).toList();
    }
    return data;
  }
}

class Result {
  String? description;
  String? displaySymbol;
  String? symbol;
  String? type;

  Result({this.description, this.displaySymbol, this.symbol, this.type});

  Result.fromJson(Map<String, dynamic> json) {
    description = json['description'];
    displaySymbol = json['displaySymbol'];
    symbol = json['symbol'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['description'] = description;
    data['displaySymbol'] = displaySymbol;
    data['symbol'] = symbol;
    data['type'] = type;
    return data;
  }
}