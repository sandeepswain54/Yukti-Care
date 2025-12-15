import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final MapController _mapController = MapController();
  final TextEditingController _emailController = TextEditingController();

  LatLng? _currentLocation;
  LatLng? _otherUserLocation;
  List<Polyline> _polylines = [];
  double? _distance;
  bool _isTracking = false;
  bool _isLoading = false;
  bool _locationEnabled = false;
  String? _trackedUserEmail;
  String? _trackedUserId;
  
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<DocumentSnapshot>? _otherUserStream;
  DateTime? _lastUpdateTime;

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _otherUserStream?.cancel();
    _mapController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _isLoading = true);
    
    // Step 1: Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showEnableLocationDialog();
      setState(() {
        _isLoading = false;
        _locationEnabled = false; // Allow map to show with default location
      });
      return;
    }

    // Step 2: Check location permission
    LocationPermission permission = await Geolocator.checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnackBar('Location permission is required');
        setState(() {
          _isLoading = false;
          _locationEnabled = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showLocationSettingsDialog();
      setState(() {
        _isLoading = false;
        _locationEnabled = false;
      });
      return;
    }

    // Step 3: Get current location
    await _getCurrentLocation();
    setState(() {
      _locationEnabled = true;
      _isLoading = false;
    });
  }

  void _showEnableLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Service Disabled'),
        content: const Text('Please enable location services to use this app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openLocationSettings();
            },
            child: const Text('Enable Location'),
          ),
        ],
      ),
    );
  }

  void _showLocationSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text('Location permission is permanently denied. Please enable it in app settings.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      _updateLocationInFirestore(position.latitude, position.longitude);
      
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _updateDistance(); // Update distance when current location changes
      });

      // Start listening to location updates
      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (_lastUpdateTime == null || 
            DateTime.now().difference(_lastUpdateTime!) > const Duration(seconds: 5)) {
          
          _updateLocationInFirestore(position.latitude, position.longitude);
          setState(() {
            _currentLocation = LatLng(position.latitude, position.longitude);
            _updateDistance(); // Update distance when current location changes
          });
          _lastUpdateTime = DateTime.now();
        }
      });

    } catch (e) {
      _showSnackBar('Error getting location: ${e.toString()}');
    }
  }

  Future<void> _updateLocationInFirestore(double lat, double lng) async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('user_locations').doc(user.uid).set({
          'email': user.email?.toLowerCase() ?? 'unknown',
          'userId': user.uid,
          'latitude': lat,
          'longitude': lng,
          'timestamp': FieldValue.serverTimestamp(),
          'isOnline': true,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating location: $e');
    }
  }

  Future<void> _trackUserByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      
      // Don't allow tracking yourself
      if (normalizedEmail == _auth.currentUser?.email?.toLowerCase()) {
        _showSnackBar('You cannot track yourself');
        return;
      }

      setState(() {
        _isTracking = true;
        _trackedUserEmail = normalizedEmail;
        _isLoading = true;
      });

      // Find user by email
      final query = await _firestore.collection('user_locations')
          .where('email', isEqualTo: normalizedEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showSnackBar('User not found or not sharing location');
        setState(() {
          _isLoading = false;
          _isTracking = false;
        });
        return;
      }

      final doc = query.docs.first;
      final data = doc.data();
      
      if (data['latitude'] == null || data['longitude'] == null) {
        _showSnackBar('User location not available');
        setState(() {
          _isLoading = false;
          _isTracking = false;
        });
        return;
      }

      _trackedUserId = doc.id;
      
      // Start listening to location updates
      _otherUserStream?.cancel();
      
      _otherUserStream = _firestore.collection('user_locations')
          .doc(_trackedUserId)
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists) {
          final data = snapshot.data()!;
          final lat = data['latitude'] as double?;
          final lng = data['longitude'] as double?;
          
          if (lat != null && lng != null) {
            setState(() {
              _otherUserLocation = LatLng(lat, lng);
              _updateDistance(); // Update distance when other user location changes
              _isLoading = false;
            });
            
            if (_currentLocation != null && _otherUserLocation != null) {
              _updateMapBounds();
            }
          }
        } else {
          _showSnackBar('User stopped sharing location');
          _stopTracking();
        }
      });

      await _saveEmail(email);
    } catch (e) {
      _showSnackBar('Error tracking user: ${e.toString()}');
      setState(() {
        _isLoading = false;
        _isTracking = false;
      });
    }
  }

  void _updateMapBounds() {
    if (_currentLocation != null && _otherUserLocation != null) {
      try {
        final bounds = LatLngBounds.fromPoints([_currentLocation!, _otherUserLocation!]);
        if (bounds.isValid) {
          _mapController.fitBounds(bounds, padding: const EdgeInsets.all(50));
        }
      } catch (e) {
        print('Error fitting bounds: $e');
      }
    }
  }

  void _updateDistance() {
    if (_currentLocation != null && _otherUserLocation != null) {
      final distance = _calculateDistance(_currentLocation!, _otherUserLocation!);
      setState(() {
        _distance = distance;
        _polylines = [
          Polyline(
            points: [_currentLocation!, _otherUserLocation!],
            strokeWidth: 4,
            color: Colors.blue,
          )
        ];
      });
    }
  }

  double _calculateDistance(LatLng start, LatLng end) {
    const R = 6371.0;
    double dLat = (end.latitude - start.latitude) * (pi / 180);
    double dLon = (end.longitude - start.longitude) * (pi / 180);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(start.latitude * (pi / 180)) *
            cos(end.latitude * (pi / 180)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tracked_email', email);
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString('tracked_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
  }

  void _showTrackDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Track Your Order'),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            hintText: "Enter delivery partner's email",
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_emailController.text.isEmpty) {
                _showSnackBar('Please enter an email address');
                return;
              }
              Navigator.pop(context);
              _trackUserByEmail(_emailController.text);
            },
            child: const Text('Track Order'),
          ),
        ],
      ),
    );
  }

  void _stopTracking() {
    _otherUserStream?.cancel();
    setState(() {
      _isTracking = false;
      _trackedUserEmail = null;
      _trackedUserId = null;
      _otherUserLocation = null;
      _polylines = [];
      _distance = null;
    });
    _clearSavedEmail();
    _showSnackBar('Stopped tracking');
  }

  Future<void> _clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tracked_email');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Custom widget for truck icon
  Widget _buildTruckIcon() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.local_shipping,
        color: Colors.white,
        size: 30,
      ),
    );
  }

  // Custom widget for person icon (current user)
  Widget _buildPersonIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚚 Track Your Order'),
        backgroundColor: Colors.orange,
        actions: [
          if (_isTracking)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white),
              onPressed: _stopTracking,
              tooltip: 'Stop Tracking',
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentLocation ?? const LatLng(23.8103, 90.4125),
              initialZoom: 13.0,
              onMapReady: () {
                print("Map is ready!");
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.upyogi.service_app',
              ),
              
              // Alternative tile layer as fallback
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c'],
                userAgentPackageName: 'com.upyogi.service_app',
              ),

              // Polyline layer - shows connecting line between you and the tracked user
              if (_polylines.isNotEmpty)
                PolylineLayer(polylines: _polylines),
              
              // Marker layer - shows both user locations
             // Marker layer - shows both user locations
MarkerLayer(
  markers: [
    // Current user location (You) - Person icon
    if (_currentLocation != null)
      Marker(
        point: _currentLocation!,
        width: 40,
        height: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPersonIcon(),
          ],
        ),
      ),
    
    // Tracked user location (Delivery Partner) - Truck icon
    if (_otherUserLocation != null)
      Marker(
        point: _otherUserLocation!,
        width: 50,
        height: 50,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTruckIcon(),
          ],
        ),
      ),
  ],
),
            ],
          ),

          // Loading indicator
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Location disabled warning
          if (!_locationEnabled && !_isLoading)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Card(
                color: Colors.orange,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Icon(Icons.location_off, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Location Access Required',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enable location to share your position',
                              style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _initLocation,
                        child: const Text('Enable', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Track button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: _showTrackDialog,
              backgroundColor: Colors.orange,
              child: const Icon(Icons.search, color: Colors.white),
            ),
          ),

          // Distance and tracking info card
          if (_distance != null)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.local_shipping, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tracking: $_trackedUserEmail',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.space_dashboard, color: Colors.blue, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Distance: ${_distance!.toStringAsFixed(2)} km',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      if (_currentLocation != null && _otherUserLocation != null)
                        const SizedBox(height: 10),
                      if (_currentLocation != null && _otherUserLocation != null)
                        const Text(
                          '📍 Blue line shows real-time connection between you and delivery partner',
                          style: TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                    ],
                  ),
                ),
              ),
            ),

          // Status indicator when tracking
          if (_isTracking && _otherUserLocation != null)
            Positioned(
              top: 70,
              left: 20,
              right: 20,
              child: IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _isTracking ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: Card(
                    color: Colors.green.withOpacity(0.9),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.circle, color: Colors.white, size: 12),
                          SizedBox(width: 8),
                          Text(
                            'LIVE TRACKING ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class LatLngBounds {
  final LatLng northeast;
  final LatLng southwest;

  LatLngBounds({required this.northeast, required this.southwest});

  factory LatLngBounds.fromPoints(List<LatLng> points) {
    if (points.isEmpty) throw ArgumentError('Points list cannot be empty');
    
    double minLat = points[0].latitude;
    double maxLat = points[0].latitude;
    double minLng = points[0].longitude;
    double maxLng = points[0].longitude;

    for (final point in points) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return LatLngBounds(
      northeast: LatLng(maxLat, maxLng),
      southwest: LatLng(minLat, minLng),
    );
  }

  LatLng get center {
    return LatLng(
      (northeast.latitude + southwest.latitude) / 2,
      (northeast.longitude + southwest.longitude) / 2,
    );
  }

  bool get isValid {
    return northeast.latitude.isFinite &&
           northeast.longitude.isFinite &&
           southwest.latitude.isFinite &&
           southwest.longitude.isFinite;
  }
}

extension MapControllerExtensions on MapController {
  void fitBounds(LatLngBounds bounds, {EdgeInsets padding = EdgeInsets.zero}) {
    if (!bounds.isValid) return;
    
    final center = bounds.center;
    final zoom = _getZoomLevelForBounds(bounds, padding);
    
    if (zoom.isFinite) {
      move(center, zoom);
    }
  }
  
  double _getZoomLevelForBounds(LatLngBounds bounds, EdgeInsets padding) {
    final width = bounds.northeast.longitude - bounds.southwest.longitude;
    final height = bounds.northeast.latitude - bounds.southwest.latitude;
    
    if (width.isNaN || height.isNaN) return 13.0;
    
    final maxDimension = max(width, height);
    double zoom = 16 - log(maxDimension * 1000) / log(2);
    return zoom.clamp(1.0, 18.0);
  }
}