import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/route_manager.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/Widgets/posting_grid_tile_ui.dart';
import 'package:service_app/views/view_posting_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class Booking extends StatefulWidget {
  @override
  State<Booking> createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  final TextEditingController _searchController = TextEditingController();
  String _searchType = "name";
  bool _isNameSelected = false;
  bool _isCitySelected = false;
  bool _isTypeSelected = false;

  final List<String> carouselImages = [
    'assets/pad6.png',
    'assets/pad7.png',
    'assets/pad8.png',
    'assets/pad9.jpg',
    'assets/pad10.jpg',
  ];
  int _currentCarouselIndex = 0;

  // Location variables
  String _currentLocation = 'Getting location...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _getCurrentLocation();
  }

  // Function to get current location
  Future<void> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentLocation = 'Location permission denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentLocation = 'Location permission permanently denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        setState(() {
          _currentLocation = '${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}'.trim();
          if (_currentLocation.endsWith(',')) {
            _currentLocation = _currentLocation.substring(0, _currentLocation.length - 1);
          }
          _isLoadingLocation = false;
        });
      } else {
        setState(() {
          _currentLocation = 'Lat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}';
          _isLoadingLocation = false;
        });
      }
    } catch (e) {
      setState(() {
        _currentLocation = 'Unable to get location';
        _isLoadingLocation = false;
      });
    }
  }

  Stream<QuerySnapshot> get _postingsStream =>
    FirebaseFirestore.instance.collection('postings').snapshots();

  Stream<QuerySnapshot> get _serviceListingsStream =>
    FirebaseFirestore.instance.collection('service_listings').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: false,
            expandedHeight: 260,
            backgroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Padding(
                padding: const EdgeInsets.fromLTRB(20, 50, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Replaced "Featured" with location widget
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Color(0xFF4A6CF7),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentLocation,
                            style: TextStyle(
                              fontSize: 18, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.grey[800],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (_isLoadingLocation)
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A6CF7)),
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: Color(0xFF4A6CF7),
                              size: 20,
                            ),
                            onPressed: _getCurrentLocation,
                            padding: EdgeInsets.zero,
                            constraints: BoxConstraints(),
                          ),
                      ],
                    ),
                    SizedBox(height: 25),
                    CarouselSlider(
                      items: carouselImages.map((image) {
                        return Container(
                          margin: EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: AssetImage(image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      }).toList(),
                      options: CarouselOptions(
                        height: 150,
                        autoPlay: true,
                        enlargeCenterPage: true,
                        aspectRatio: 2.0,
                        onPageChanged: (index, reason) {
                          setState(() => _currentCarouselIndex = index);
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: carouselImages.asMap().entries.map((entry) {
                        return Container(
                          width: 8,
                          height: 8,
                          margin: EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _currentCarouselIndex == entry.key
                                ? Color(0xFF4A6CF7)
                                : Colors.grey[300],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchBarDelegate(
              child: Container(
                color: Colors.white,
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterButton("Period Panty", _isNameSelected, () =>
                              _handleSearch('name', true, false, false, 'homestay')),
                          _buildFilterButton("Period Cup", _isCitySelected, () =>
                              _handleSearch('city', false, true, false, 'local')),
                          _buildFilterButton("Starter Kits", _isTypeSelected, () =>
                              _handleSearch('type', false, false, true, 'cultural')),
                          _buildFilterButton("Bulk Packs", _isTypeSelected, () =>
                              _handleSearch('type', false, false, true, 'guide')),
                          _buildFilterButton("Sterilizers", false, () =>
                              _handleSearch('Accessories', false, false, false, 'Remuna')),
                          _buildFilterButton("Clear", false, () {
                            _searchController.clear();
                            _handleSearch('name', false, false, false);
                          }),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Search",
                        prefixIcon: Icon(Icons.search, color: Colors.black),
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(56),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: _postingsStream,
              builder: (context, postingsSnapshot) {
                if (!postingsSnapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // Nest a second StreamBuilder to also listen to service_listings in real-time
                return StreamBuilder<QuerySnapshot>(
                  stream: _serviceListingsStream,
                  builder: (context, servicesSnapshot) {
                    if (!servicesSnapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }

                    // Map postings collection
                    final postingsList = postingsSnapshot.data!.docs.map((doc) {
                      final posting = PostingModel.fromMap(doc.data() as Map<String, dynamic>);
                      posting.id = doc.id;
                      return posting;
                    }).toList();

                    // Map service_listings collection (created by hosts via Create Posting screen)
                    final servicesList = servicesSnapshot.data!.docs.map((doc) {
                      final posting = PostingModel.fromMap(doc.data() as Map<String, dynamic>);
                      posting.id = doc.id;
                      return posting;
                    }).toList();

                    // Combine both lists and dedupe by id (service_listings may contain different ids)
                    final Map<String, PostingModel> combinedMap = {};
                    for (final p in postingsList) combinedMap[p.id ?? ''] = p;
                    for (final s in servicesList) combinedMap[s.id ?? ''] = s;

                    final allItems = combinedMap.values.toList();

                    final query = _searchController.text.trim().toLowerCase();
                    final results = allItems.where((posting) {
                      if (query.isEmpty) return true;
                      switch (_searchType) {
                        case 'name':
                          return (posting.name ?? '').toLowerCase().contains(query);
                        case 'city':
                          return (posting.city ?? '').toLowerCase().contains(query);
                        case 'type':
                          return (posting.type ?? '').toLowerCase().contains(query);
                        case 'address':
                          return (posting.address ?? '').toLowerCase().contains(query);
                        default:
                          return false;
                      }
                    }).toList();

                    if (results.isEmpty) {
                      return Center(child: Text("No results found."));
                    }

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 15,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final item = results[index];
                        return InkResponse(
                          onTap: () => Get.to(ViewPostingScreen(posting: item)),
                          child: PostingGridTileUi(
                            posting: item,
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleSearch(String type, bool nameSelected, bool citySelected, bool typeSelected, [String? value]) {
    setState(() {
      _searchType = type;
      _isNameSelected = nameSelected;
      _isCitySelected = citySelected;
      _isTypeSelected = typeSelected;
      if (value != null) {
        _searchController.text = value;
      }
    });
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : Colors.grey[700],
        backgroundColor: isSelected ? Color(0xFF4A6CF7) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? Color(0xFF4A6CF7) : Colors.grey[300]!),
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(text),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickySearchBarDelegate({required this.child});

  @override
  double get minExtent => 130;
  @override
  double get maxExtent => 130;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}