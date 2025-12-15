import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class ProductUploadScreen extends StatefulWidget {
  @override
  State<ProductUploadScreen> createState() => _ProductUploadScreenState();
}

class _ProductUploadScreenState extends State<ProductUploadScreen> {
  final picker = ImagePicker();
  List<XFile> images = [];
  String? selectedCategory;
  final categories = [
    'Menstrual Cup',
    'Reusable Cloth Pad',
    'Period Panty',
    'Combo Pack',
    'Bulk Pack',
    'My Category'
  ];
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  bool isUploading = false;

  Future<List<String>> uploadImages(List<XFile> pickedImages) async {
    List<String> downloadUrls = [];
    for (XFile img in pickedImages) {
      final file = File(img.path);
      final ref = FirebaseStorage.instance.ref('products/${DateTime.now().millisecondsSinceEpoch}_${img.name}');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      downloadUrls.add(url);
    }
    return downloadUrls;
  }

  Future<void> uploadProduct() async {
    if (nameController.text.isEmpty || selectedCategory == null || images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all required fields and image')),
      );
      return;
    }
    setState(() { isUploading = true; });
    final imgUrls = await uploadImages(images);
    await FirebaseFirestore.instance.collection('products').add({
      'name': nameController.text,
      'desc': descController.text,
      'price': double.tryParse(priceController.text) ?? 0,
      'category': selectedCategory,
      'images': imgUrls,
      'createdAt': FieldValue.serverTimestamp(),
    });
    setState(() { isUploading = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product uploaded!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Product')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images picker
            Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final picked = await picker.pickMultiImage();
                    if (picked != null) setState(() => images = picked.take(6).toList());
                  },
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue, width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.blue, size: 32),
                        SizedBox(height: 8),
                        Text("Pick Images", style: TextStyle(color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    children: images
                        .map((img) => Image.file(File(img.path), width: 55, height: 55, fit: BoxFit.cover))
                        .toList(),
                  ),
                )
              ],
            ),
            SizedBox(height: 8),
            Text("You can add up to a maximum of 6 images", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
            SizedBox(height: 18),
            DropdownButtonFormField(
              value: selectedCategory,
              items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (cat) => setState(() => selectedCategory = cat),
              decoration: InputDecoration(labelText: 'Category'),
            ),
            SizedBox(height: 14),
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: "Product Name *"),
            ),
            SizedBox(height: 14),
            TextField(
              controller: descController,
              decoration: InputDecoration(labelText: "Product Description"),
            ),
            SizedBox(height: 14),
            TextField(
              controller: priceController,
              decoration: InputDecoration(labelText: "Product Price (₹)"),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 22),
            Center(
              child: isUploading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      icon: Icon(Icons.cloud_upload),
                      label: Text("Upload"),
                      onPressed: uploadProduct,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
