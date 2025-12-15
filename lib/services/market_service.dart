import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/market_data.dart';

class MarketService {
  static const String _baseUrl = "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070";
  static const String _apiKey = "579b464db66ec23bdd000001a4750d8e9abf4c2260159520aca95751";

  Future<List<MarketData>> searchMarkets({
    String? state,
    String? district,
    String? market,
  }) async {
    try {
      final Map<String, String> queryParams = {
        'api-key': _apiKey,
        'format': 'json',
        'limit': '1000',
      };

      if (state != null) queryParams['filters[state]'] = state;
      if (district != null) queryParams['filters[district]'] = district;
      if (market != null) queryParams['filters[market]'] = market;

      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['records'] != null && data['records'] is List) {
          return (data['records'] as List)
              .map((record) => MarketData.fromJson(record))
              .toList();
        }
      }
      // If API call fails, filter sample data based on search criteria
      return _filterSampleData(state: state, district: district, market: market);
    } catch (e) {
      // On any error, filter sample data based on search criteria
      return _filterSampleData(state: state, district: district, market: market);
    }
  }

  List<MarketData> _filterSampleData({
    String? state,
    String? district,
    String? market,
  }) {
    return sampleData.where((data) {
      if (state != null && !data.state.toLowerCase().contains(state.toLowerCase())) {
        return false;
      }
      if (district != null && !data.district.toLowerCase().contains(district.toLowerCase())) {
        return false;
      }
      if (market != null && !data.marketName.toLowerCase().contains(market.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();
  }

  // Sample data to use when API is not available
  List<MarketData> get sampleData => [
    MarketData(
      state: "Maharashtra",
      district: "Pune",
      marketName: "Pune Market",
      commodity: "Rice",
      price: 2750.0,
      lat: 18.5204,
      lon: 73.8567,
      timestamp: DateTime.parse("2024-01-15"),
    ),
    MarketData(
      state: "Karnataka",
      district: "Bangalore",
      marketName: "KR Market",
      commodity: "Wheat",
      price: 2500.0,
      lat: 12.9716,
      lon: 77.5946,
      timestamp: DateTime.parse("2024-01-15"),
    ),
    MarketData(
      state: "Tamil Nadu",
      district: "Chennai",
      marketName: "Koyambedu Market",
      commodity: "Tomatoes",
      price: 50.0,
      lat: 13.0827,
      lon: 80.2707,
      timestamp: DateTime.parse("2024-01-15"),
    ),
    MarketData(
      state: "Gujarat",
      district: "Ahmedabad",
      marketName: "Jamalpur Market",
      commodity: "Cotton",
      price: 5750.0,
      lat: 23.0225,
      lon: 72.5714,
      timestamp: DateTime.parse("2024-01-15"),
    ),
    MarketData(
      state: "Uttar Pradesh",
      district: "Lucknow",
      marketName: "Kaiserbagh Market",
      commodity: "Potato",
      price: 1350.0,
      lat: 26.8467,
      lon: 80.9462,
      timestamp: DateTime.parse("2024-01-15"),
    ),
  ];
}