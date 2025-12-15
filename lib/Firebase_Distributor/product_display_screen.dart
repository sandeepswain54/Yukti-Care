import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_app/Firebase_Distributor/ProductDetailScreen.dart';

class ProductCategoryDisplayScreen extends StatefulWidget {
  @override
  State<ProductCategoryDisplayScreen> createState() => _ProductCategoryDisplayScreenState();
}

class _ProductCategoryDisplayScreenState extends State<ProductCategoryDisplayScreen> {
  final categories = [
    {'name': 'Menstrual Cup', 'icon': Icons.local_drink},
    {'name': 'Reusable Cloth Pad', 'icon': Icons.opacity},
    {'name': 'Period Panty', 'icon': Icons.checkroom},
    {'name': 'Combo Pack', 'icon': Icons.all_inbox},
    {'name': 'Bulk Pack', 'icon': Icons.inventory_2},
    {'name': 'My Category', 'icon': Icons.image},
  ];

  int selectedTab = 0;
  bool isTabLoading = false;

  @override
  Widget build(BuildContext context) {
    final categoryName = categories[selectedTab]['name']!;
    return Scaffold(
      appBar: AppBar(title: Text('Product Catalogue')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SizedBox(
              height: 130,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    setState(() {
                      isTabLoading = true;
                      selectedTab = index;
                    });
                  },
                  child: Container(
                    width: 85,
                    padding: EdgeInsets.only(top: 7),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: selectedTab == index ? 31 : 26,
                          child: Icon(categories[index]['icon'] as IconData, size: 29),
                        ),
                        SizedBox(height: 5),
                        Text(
                          categories[index]['name'] as String,
                          style: TextStyle(
                            fontWeight: selectedTab == index ? FontWeight.bold : FontWeight.normal,
                            color: selectedTab == index ? Colors.teal : Colors.black,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('products')
                .where('category', isEqualTo: categoryName)
                .orderBy('createdAt', descending: true)
                .snapshots(),
              builder: (context, snap) {
                // Mark loading false ONCE we get data for new tab
                if (isTabLoading && snap.hasData) {
                  Future.microtask(() => setState(() => isTabLoading = false));
                }
                if (isTabLoading && !snap.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData) {
                  return Center(child: SizedBox.shrink());
                }
                final products = snap.data!.docs;
                if (products.isEmpty) return Center(child: Text('No products in this category.'));
                return ListView.separated(
                  itemCount: products.length,
                  separatorBuilder: (_, __) => SizedBox(height: 18),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  itemBuilder: (context, idx) {
                    final prod = products[idx].data() as Map<String, dynamic>;
                    final price = double.tryParse(prod['unitPrice']?.toString() ?? '') ?? 0;
                    final mrp = double.tryParse(prod['mrp']?.toString() ?? '') ?? 0;
                    final discount = (mrp > price && mrp > 0)
                        ? "${((mrp - price) / mrp * 100).round()}% off"
                        : "";
                    final delivery = "By Sat, 15 Nov";
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 7)],
                      ),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (prod['images'] != null && prod['images'].isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                prod['images'][0],
                                width: 65,
                                height: 85,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(Icons.image, size: 40),
                              ),
                            )
                          else
                            Container(
                              width: 65,
                              height: 85,
                              color: Colors.grey[200],
                              child: Icon(Icons.image, size: 40),
                            ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prod['name'] ?? '', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17)),
                                if ((prod['desc'] ?? '').isNotEmpty)
                                  Padding(
                                    padding: EdgeInsets.only(top: 2.5, bottom: 7),
                                    child: Text(prod['desc'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey[700]), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                                Row(
                                  children: [
                                    Text(
                                      '₹${prod['unitPrice'] ?? prod['price'] ?? ''}',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black),
                                    ),
                                    SizedBox(width: 9),
                                    if (mrp > 0)
                                      Text(
                                        '₹${prod['mrp']}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey,
                                          decoration: TextDecoration.lineThrough,
                                        ),
                                      ),
                                    SizedBox(width: 9),
                                    if (discount.isNotEmpty)
                                      Text(
                                        discount,
                                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 7),
                                Row(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.local_shipping, color: Colors.green, size: 18),
                                          SizedBox(width: 2),
                                          Text(
                                            delivery,
                                            style: TextStyle(color: Colors.green[900], fontSize: 13, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Spacer(),
                                    ElevatedButton(
                                      onPressed: () {
                                        Navigator.push(context, MaterialPageRoute(
  builder: (_) => ProductDetailScreen(D21gyO5U1dySI9bXDhuz: products[idx].id),
));

                                      },
                                      child: Text("ADD"),
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 3),
                                        backgroundColor: Colors.teal[700],
                                        foregroundColor: Colors.white,
                                        textStyle: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 2),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
}