class MarketData {
  final String marketName;
  final String commodity;
  final double price;
  final double lat;
  final double lon;
  final String state;
  final String district;
  final DateTime timestamp;

  MarketData({
    required this.marketName,
    required this.commodity,
    required this.price,
    required this.lat,
    required this.lon,
    required this.state,
    required this.district,
    required this.timestamp,
  });

  factory MarketData.fromJson(Map<String, dynamic> json) {
    // Clean and standardize district name
    String cleanDistrict = (json['district'] ?? '').toString().trim();
    if (cleanDistrict.toLowerCase().endsWith(' district')) {
      cleanDistrict = cleanDistrict.substring(0, cleanDistrict.length - 9);
    }

    // Clean and standardize state name
    String cleanState = (json['state'] ?? '').toString().trim();

    return MarketData(
      marketName: (json['market'] ?? '').toString().trim(),
      commodity: (json['commodity'] ?? '').toString().trim(),
      price: double.tryParse(json['modal_price']?.toString() ?? '0') ?? 0.0,
      lat: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
      lon: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      state: cleanState,
      district: cleanDistrict,
      timestamp: DateTime.tryParse(json['arrival_date'] ?? '') ?? DateTime.now(),
    );
  }

  // Helper method to get display name for search results
  String get displayName => '$district, $state';
  
  // Helper method to check if market matches search query
  bool matchesSearch(String query) {
    query = query.toLowerCase();
    return district.toLowerCase().contains(query) ||
           state.toLowerCase().contains(query) ||
           marketName.toLowerCase().contains(query) ||
           commodity.toLowerCase().contains(query);
  }
}