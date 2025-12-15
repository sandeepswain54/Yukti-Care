import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/views/host_home.dart';

class CreatePostingScreen extends StatefulWidget {
  final PostingModel? posting;
  const CreatePostingScreen({super.key, this.posting});

  @override
  State<CreatePostingScreen> createState() => _CreatePostingScreenState();
}

class _CreatePostingScreenState extends State<CreatePostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController();
  final _amenitiesController = TextEditingController();

  final List<String> _serviceTypes = [
    "Reusable Pads",
    "Menstrual Cups",
    "Period Panties",
    "Starter Kits",
    "Storage Bags",

  ];

  late String _selectedServiceType;
  late Map<String, int> _beds;
  late Map<String, int> _bathrooms;
  List<String> _base64Images = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedServiceType = _serviceTypes.first;
    _beds = {"small": 0, "medium": 0, "large": 0};
    _bathrooms = {"full": 0, "half": 0};

    // If editing an existing posting, populate fields
    if (widget.posting != null) {
      _populateFields();
    }
  }

  void _populateFields() {
    final posting = widget.posting!;
    _nameController.text = posting.name ?? '';
    _priceController.text = posting.price?.toString() ?? '';
    _descriptionController.text = posting.description ?? '';
    _addressController.text = posting.address ?? '';
    _cityController.text = posting.city ?? '';
    _countryController.text = posting.country ?? '';
    _amenitiesController.text = posting.amenities?.join(', ') ?? '';
    _selectedServiceType = posting.type ?? _serviceTypes.first;
    _beds = posting.beds ?? {"small": 0, "medium": 0, "large": 0};

    try {
      final baths = (posting as dynamic).bathrooms;
      if (baths is Map<String, int>) {
        _bathrooms = baths;
      } else if (baths is Map) {
        _bathrooms = baths.cast<String, int>();
      }
    } catch (_) {
      _bathrooms = {"full": 0, "half": 0};
    }
  }

  Future<void> _pickImage(int index) async {
    if (_isLoading) return;

    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
      maxWidth: 800,
    );

    if (pickedFile != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await File(pickedFile.path).readAsBytes();
        final base64Image = base64Encode(bytes);
        setState(() {
          if (index < 0) {
            _base64Images.add(base64Image);
          } else {
            _base64Images[index] = base64Image;
          }
        });
      } catch (e) {
        Get.snackbar("Error", "Failed to process image: ${e.toString()}");
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitPosting() async {
    if (!_formKey.currentState!.validate()) return;
    if (_base64Images.isEmpty && (widget.posting == null || (widget.posting!.imageNames?.isEmpty ?? true))) {
      Get.snackbar("Error", "Please add at least one image");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final postingData = {
        'name': _nameController.text.trim(),
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'country': _countryController.text.trim(),
        'amenities': _amenitiesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
        'type': _selectedServiceType,
        'beds': _beds,
        'bathrooms': _bathrooms,
        'hostId': AppConstants.currentUser.id,
        'hostName': (AppConstants.currentUser.getFullNameofUser().isNotEmpty
            ? AppConstants.currentUser.getFullNameofUser()
            : (AppConstants.currentUser.email ?? '')),
        'hostEmail': AppConstants.currentUser.email,
        'timestamp': FieldValue.serverTimestamp(),
        'isActive': true,
      };

      Future<List<String>> uploadImagesToStorage(String docId, List<String> base64Images) async {
        final List<String> imageNames = [];
        for (int i = 0; i < base64Images.length; i++) {
          try {
            final bytes = base64Decode(base64Images[i]);
            final imageName = "${docId}_image_${DateTime.now().millisecondsSinceEpoch}_$i.png";
            final ref = FirebaseStorage.instance.ref().child('postingImages').child(docId).child(imageName);
            await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
            imageNames.add(imageName);
          } catch (e) {
            debugPrint("Failed to upload image #$i: $e");
          }
        }
        return imageNames;
      }

      if (widget.posting != null && widget.posting!.id != null && widget.posting!.id!.isNotEmpty) {
        final docId = widget.posting!.id!;
        await FirebaseFirestore.instance.collection('service_listings').doc(docId).update(postingData);

        if (_base64Images.isNotEmpty) {
          final imageNames = await uploadImagesToStorage(docId, _base64Images);
          if (imageNames.isNotEmpty) {
            await FirebaseFirestore.instance.collection('service_listings').doc(docId).update({
              'imageNames': FieldValue.arrayUnion(imageNames),
            });
          }
        }

        Get.snackbar("Success", "Service updated successfully");
      } else {
        final docRef = await FirebaseFirestore.instance.collection('service_listings').add(postingData);
        final docId = docRef.id;

        if (_base64Images.isNotEmpty) {
          final imageNames = await uploadImagesToStorage(docId, _base64Images);
          if (imageNames.isNotEmpty) {
            await FirebaseFirestore.instance.collection('service_listings').doc(docId).update({
              'imageNames': imageNames,
            });
          }
        }

        Get.snackbar("Success", "Service created successfully");
      }

      Get.offAll(() => HostHomeScreen(Index: 1));
    } catch (e) {
      Get.snackbar("Error", "Failed to save: ${e.toString()}");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text("$label:", style: TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.remove, size: 20),
              onPressed: () => onChanged(value - 1 < 0 ? 0 : value - 1),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            Container(
              width: 30,
              alignment: Alignment.center,
              child: Text(value.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: Icon(Icons.add, size: 20),
              onPressed: () => onChanged(value + 1),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("${_base64Images.length}/10 photos", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: _base64Images.length + (_base64Images.length < 10 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _base64Images.length) {
              return GestureDetector(
                onTap: () => _pickImage(-1),
                child: Container(
                  decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.add_a_photo, size: 30, color: Colors.grey),
                ),
              );
            }

            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    base64Decode(_base64Images[index]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(color: Colors.grey[200], child: Icon(Icons.error, color: Colors.red));
                    },
                  ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => setState(() => _base64Images.removeAt(index)),
                    child: Container(
                      decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _amenitiesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.posting != null ? "Edit Service" : "Upload Product"),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF4A6CF7), Color(0xFF82C3FF)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: "Product Name", border: OutlineInputBorder()),
                      validator: (value) => value?.isEmpty ?? true ? "Required" : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedServiceType,
                      items: _serviceTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                      onChanged: (value) => setState(() => _selectedServiceType = value!),
                      decoration: InputDecoration(labelText: "Product Type", border: OutlineInputBorder()),
                      validator: (value) => value == null ? "Required" : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: "Price (\$)", border: OutlineInputBorder(), prefixText: "\$ "),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return "Required";
                        if (double.tryParse(value!) == null) return "Invalid number";
                        if (double.parse(value) <= 0) return "Must be greater than 0";
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: "Description", border: OutlineInputBorder(), alignLabelWithHint: true),
                      validator: (value) => value?.isEmpty ?? true ? "Required" : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(labelText: "Pharmacy Address", border: OutlineInputBorder()),
                      validator: (value) => value?.isEmpty ?? true ? "Required" : null,
                    ),
                    SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: TextFormField(controller: _cityController, decoration: InputDecoration(labelText: "City", border: OutlineInputBorder()), validator: (value) => value?.isEmpty ?? true ? "Required" : null)),
                      SizedBox(width: 16),
                      Expanded(child: TextFormField(controller: _countryController, decoration: InputDecoration(labelText: "Country", border: OutlineInputBorder()), validator: (value) => value?.isEmpty ?? true ? "Required" : null)),
                    ]),
                    SizedBox(height: 16),
                    Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Product Quantity", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 12),
                      _buildCounter("Reusable Pads", _beds["small"]!, (value) => setState(() => _beds["small"] = value)),
                      _buildCounter("Menstrual Cups", _beds["medium"]!, (value) => setState(() => _beds["medium"] = value)),
                      _buildCounter("Period Panties", _beds["large"]!, (value) => setState(() => _beds["large"] = value)),
                      SizedBox(height: 8),
                      _buildCounter("Combo Kits", _bathrooms["full"]!, (value) => setState(() => _bathrooms["full"] = value)),
                      _buildCounter("Storage Bags", _bathrooms["half"]!, (value) => setState(() => _bathrooms["half"] = value)),
                    ]))),
                    SizedBox(height: 16),
                    TextFormField(controller: _amenitiesController, maxLines: 2, decoration: InputDecoration(labelText: "Product Details / Features", hintText: "Sizes available (S, M, L)", border: OutlineInputBorder(), alignLabelWithHint: true), validator: (value) => value?.isEmpty ?? true ? "Required" : null),
                    SizedBox(height: 16),
                    Card(child: Padding(padding: EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("Product Photos", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), SizedBox(height: 8), _buildImageGrid(),]))),
                    SizedBox(height: 24),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _isLoading ? null : _submitPosting, style: ElevatedButton.styleFrom(backgroundColor: Color.fromARGB(255, 137, 147, 189), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), child: _isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white)) : Text(widget.posting != null ? "Update Service" : "Upload Product", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}