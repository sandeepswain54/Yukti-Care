import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';

class NewProductScreen extends StatefulWidget {
  const NewProductScreen({super.key});

  @override
  State<NewProductScreen> createState() => _NewProductScreenState();
}

class _NewProductScreenState extends State<NewProductScreen> {
  final List<String> categories = [
    'Menstrual Cup',
    'Reusable Cloth Pad',
    'Period Panty',
    'Combo Pack',
    'Bulk Pack',
    'My Category',
  ];

  final List<String> sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL'];
  String? selectedCategory;
  String? selectedSize;
  final List<XFile> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  final TextEditingController locationController = TextEditingController();
  Position? currentPosition;
  bool isLoadingLocation = false;
  bool uploading = false;

  // Additional controllers for more fields
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController unitPriceController = TextEditingController();
  final TextEditingController mrpController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController colorController = TextEditingController();
  final TextEditingController deliveryTimeController = TextEditingController();
  final TextEditingController packagingWeightController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  @override
  void dispose() {
    locationController.dispose();
    nameController.dispose();
    descController.dispose();
    unitPriceController.dispose();
    mrpController.dispose();
    stockController.dispose();
    quantityController.dispose();
    colorController.dispose();
    deliveryTimeController.dispose();
    packagingWeightController.dispose();
    super.dispose();
  }

  Future<void> _showLocationDeniedDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Access Required'),
          content: Text('Please enable location access in your device settings to get your current address.'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('Open Settings'),
              onPressed: () async {
                Navigator.of(context).pop();
                await Geolocator.openLocationSettings();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _checkLocationPermission() async {
    await Geolocator.requestPermission();
  }

  Future<bool> _checkAndRequestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return false;
      _showLocationDeniedDialog();
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return false;
        _showLocationDeniedDialog();
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return false;
      _showLocationDeniedDialog();
      return false;
    }
    return true;
  }

  Future<String?> _getAddressFromCoordinates(double latitude, longitude) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$latitude&lon=$longitude&zoom=18&addressdetails=1&accept-language=en'
      );
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ServiceApp/1.0',
          'Accept': 'application/json'
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) return null;
        final Map<String, dynamic> address = data['address'] as Map<String, dynamic>;
        List parts = [
          address['road'] ?? '', address['village'] ?? '', address['city'] ?? '', address['state'] ?? ''
        ].where((s) => s.isNotEmpty).toList();
        return parts.isEmpty ? null : parts.join(', ');
      }
      return null;
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  Future<void> _getCurrentLocation() async {
    if (isLoadingLocation) return;
    setState(() { isLoadingLocation = true; locationController.text = 'Detecting your location...'; });
    try {
      final hasPermission = await _checkAndRequestLocationPermission();
      if (!hasPermission) {
        if (!mounted) return;
        setState(() { locationController.text = 'Location access denied'; isLoadingLocation = false; });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      );
      setState(() { currentPosition = position; locationController.text = 'Getting your address...'; });
      String? address = await _getAddressFromCoordinates(position.latitude, position.longitude);
      setState(() { locationController.text = address ?? 'Could not get address.'; });
    } catch (e) {
      setState(() { locationController.text = 'Could not detect location. Please try again.'; });
    } finally {
      setState(() { isLoadingLocation = false; });
    }
  }

  Future<void> _pickImages() async {
    if (selectedImages.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum 6 images allowed')),
      );
      return;
    }
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        if (selectedImages.length + images.length > 6) {
          final remainingSlots = 6 - selectedImages.length;
          selectedImages.addAll(images.take(remainingSlots));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Maximum 6 images allowed')),
          );
        } else {
          selectedImages.addAll(images);
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      selectedImages.removeAt(index);
    });
  }

  // --------- LOCAL STORAGE IN FIRESTORE ---------
  Future<List<String>> _getImagePaths() async {
    // Store only the local file paths in Firestore
    List<String> imagePaths = [];
    for (XFile img in selectedImages) {
      imagePaths.add(img.path);
    }
    return imagePaths;
  }

  Future<void> _uploadProduct() async {
    if (selectedCategory == null || selectedImages.isEmpty || nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fill all required fields')),
      );
      return;
    }
    setState(() { uploading = true; });
    
    // Get local image paths instead of uploading to Firebase Storage
    List<String> imagePaths = await _getImagePaths();
    
    await FirebaseFirestore.instance.collection('products').add({
      'category': selectedCategory,
      'size': selectedSize,
      'imagePaths': imagePaths, // Store local paths instead of URLs
      'location': locationController.text,
      'name': nameController.text,
      'desc': descController.text,
      'unitPrice': unitPriceController.text,
      'mrp': mrpController.text,
      'stock': stockController.text,
      'quantity': quantityController.text,
      'color': colorController.text,
      'deliveryTime': deliveryTimeController.text,
      'packagingWeight': packagingWeightController.text,
      'createdAt': FieldValue.serverTimestamp(),
      'storageType': 'local', // Add a flag to indicate local storage
    });
    
    setState(() { uploading = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product uploaded with local images!')));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    "New Product",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Spacer(),
                  Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(Icons.settings, color: Colors.blue[700], size: 24),
                ],
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 18),
                      // Image picker
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue, width: 1.5),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, color: Colors.blue, size: 32),
                                    SizedBox(height: 6),
                                    Text(
                                      "Image",
                                      style: TextStyle(color: Colors.blue, fontSize: 17),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            ...selectedImages.asMap().entries.map((entry) {
                              int idx = entry.key;
                              XFile image = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: Stack(
                                  children: [
                                    Container(
                                      width: 100,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey[300]!),
                                        image: DecorationImage(
                                          image: FileImage(File(image.path)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(idx),
                                        child: Container(
                                          padding: EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.close, color: Colors.white, size: 16),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "You can add up to a maximum of 6 images",
                        style: TextStyle(color: Colors.grey[700], fontSize: 15),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Product Details",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: "Product Name",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: descController,
                        decoration: InputDecoration(
                          labelText: "Product Description",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          labelText: "Category",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: categories.map((String category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        },
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Pricing",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                      ),
                      SizedBox(height: 10),
                      // Unit Price, MRP, Stock fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: unitPriceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: "₹ ",
                                labelText: "Unit Price",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: TextField(
                              controller: mrpController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: "₹ ",
                                labelText: "MRP",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: "₹ ",
                                labelText: "Stock",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      // Quantity, Size
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: quantityController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Quantity",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedSize,
                              decoration: InputDecoration(
                                labelText: "Size",
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              items: sizes.map((String size) {
                                return DropdownMenuItem<String>(
                                  value: size,
                                  child: Text(size),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedSize = newValue;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Variants",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: colorController,
                        decoration: InputDecoration(
                          labelText: "Color",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 25),
                      Text(
                        "Logistics",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: deliveryTimeController,
                        decoration: InputDecoration(
                          labelText: "Delivery Time",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 14),
                      TextField(
                        controller: packagingWeightController,
                        decoration: InputDecoration(
                          labelText: "Packaging Weight",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      SizedBox(height: 15),
                      Text(
                        "Distributor Address",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                      ),
                      SizedBox(height: 15),
                      TextField(
                        controller: locationController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: "Current Location",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          suffixIcon: isLoadingLocation
                            ? Container(
                                margin: EdgeInsets.all(12),
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: Icon(Icons.my_location),
                                onPressed: _getCurrentLocation,
                              ),
                          hintText: "Tap to get current location",
                        ),
                        onTap: _getCurrentLocation,
                      ),
                      SizedBox(height: 15),
                    ],
                  ),
                ),
              ),
            ),
            // Save/Upload button
            Container(
              color: Color(0xFFAEC8F6),
              width: double.infinity,
              height: 60,
              child: uploading
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : TextButton.icon(
                onPressed: _uploadProduct,
                icon: Icon(Icons.save, color: Colors.white),
                label: Text(
                  "Upload",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}