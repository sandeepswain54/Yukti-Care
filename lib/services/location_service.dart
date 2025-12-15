import 'dart:math';
import 'package:dio/dio.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  final Dio _dio = Dio()
    ..options = BaseOptions(
      headers: {
        'User-Agent': 'LocalGrid_EV_App/1.0',
      },
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 3),
    );
  
  Future<List<PlaceLocation>> searchLocations(String query) async {
    if (query.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'limit': 5,
          'addressdetails': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'LocalGrid_EV_App/1.0',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> results = response.data;
        return results.map((result) => PlaceLocation.fromJson(result)).toList();
      }
    } catch (e) {
      print('Error searching locations: $e');
    }
    return [];
  }

  Future<List<ChargingStation>> getNearbyChargingStations(LatLng location) async {
    // Generating dummy data around the selected location
    final random = Random();
    final stations = <ChargingStation>[];
    
    final chargerTypes = [
      ['CCS2 (50 kW)', 'CCS2 (100 kW)'],
      ['Type 2 AC (7.4 kW)', 'Type 2 AC (22 kW)'],
      ['Bharat AC-001 (3.3 kW)', 'Bharat DC-001 (15 kW)'],
      ['CHAdeMO (50 kW)'],
      ['GB/T DC (60 kW)'],
    ];

    final operators = [
      'Tata Power',
      'EESL',
      'Fortum',
      'LocalGrid Network',
      'Ather Grid'
    ];

    // Generate 5 random stations around the location
    for (int i = 0; i < 5; i++) {
      // Generate a random offset between -0.01 and 0.01 (roughly 1km)
      final latOffset = (random.nextDouble() - 0.5) * 0.02;
      final lonOffset = (random.nextDouble() - 0.5) * 0.02;

      final selectedChargerTypes = chargerTypes[random.nextInt(chargerTypes.length)];
      final power = selectedChargerTypes[0].split('(')[1].split(')')[0];

      stations.add(ChargingStation(
        id: i + 1,
        lat: location.latitude + latOffset,
        lon: location.longitude + lonOffset,
        name: 'EV Charging Station ${i + 1}',
        operator: operators[random.nextInt(operators.length)],
        address: 'Near ${location.latitude + latOffset}, ${location.longitude + lonOffset}',
        connectorTypes: selectedChargerTypes,
        isAvailable: random.nextBool(),
        power: power,
        price: 10.0 + random.nextDouble() * 5, // Random price between 10 and 15
      ));
    }

    return stations;
  }
}

class PlaceLocation {
  final String displayName;
  final double lat;
  final double lon;
  final Map<String, dynamic> address;

  PlaceLocation({
    required this.displayName,
    required this.lat,
    required this.lon,
    required this.address,
  });

  factory PlaceLocation.fromJson(Map<String, dynamic> json) {
    return PlaceLocation(
      displayName: json['display_name'],
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
      address: json['address'] ?? {},
    );
  }
}

class ChargingStation {
  final int id;
  final double lat;
  final double lon;
  final String name;
  final String operator;
  final String address;
  final List<String> connectorTypes;
  final bool isAvailable;
  final String power;
  final double price;

  ChargingStation({
    required this.id,
    required this.lat,
    required this.lon,
    required this.name,
    required this.operator,
    required this.address,
    required this.connectorTypes,
    required this.isAvailable,
    required this.power,
    required this.price,
  });

  factory ChargingStation.fromJson(Map<String, dynamic> json) {
    return ChargingStation(
      id: json['id'] ?? 0,
      lat: json['lat'] ?? 0.0,
      lon: json['lon'] ?? 0.0,
      name: json['name'] ?? 'EV Charging Station',
      operator: json['operator'] ?? 'LocalGrid Network',
      address: json['address'] ?? 'Address not available',
      connectorTypes: List<String>.from(json['connectorTypes'] ?? []),
      isAvailable: json['isAvailable'] ?? true,
      power: json['power'] ?? 'Unknown',
      price: json['price']?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'lat': lat,
    'lon': lon,
    'name': name,
    'operator': operator,
    'address': address,
    'connectorTypes': connectorTypes,
    'isAvailable': isAvailable,
    'power': power,
    'price': price,
  };
}