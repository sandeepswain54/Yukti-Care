import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductDetailScreen extends StatelessWidget {
  final String D21gyO5U1dySI9bXDhuz; // Pass Firestore doc id

  const ProductDetailScreen({super.key, required this.D21gyO5U1dySI9bXDhuz});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(),
        actions: [
          IconButton(icon: Icon(Icons.search), onPressed: () {}),
          IconButton(icon: Icon(Icons.shopping_cart_checkout), onPressed: () {}),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('products').doc(D21gyO5U1dySI9bXDhuz).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return Center(child: Text('Product not found.'));
          final prod = snapshot.data!.data() as Map<String, dynamic>;
          final images = (prod['images'] ?? []) as List<dynamic>;
          final price = double.tryParse(prod['unitPrice']?.toString() ?? '') ?? 0;
          final mrp = double.tryParse(prod['mrp']?.toString() ?? '') ?? 0;
          final discount = (mrp > price && mrp > 0) ? "${((mrp-price)/mrp*100).round()}% off" : "";
          final variants = (prod['variants'] ?? ["Sky"]) as List<dynamic>; // default
          final variantsDisplay = variants.isNotEmpty ? variants : [prod['name']];
          final selectedVariant = ValueNotifier(0);

          return ValueListenableBuilder<int>(
            valueListenable: selectedVariant,
            builder: (context, variantIdx, __) {
              return ListView(
                padding: EdgeInsets.only(bottom: 24),
                children: [
                  // Popularity (fake, or you can fetch if you store)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                    child: Row(children: [
                      Icon(Icons.trending_up, size: 18, color: Colors.green[700]),
                      SizedBox(width: 6),
                      Text(
                        "333 people bought in last 7 days",
                        style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w500, fontSize: 14),
                      ),
                    ]),
                  ),
                  // Product Title + Bestseller badge + Share
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prod['name'] ?? '',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 7),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Color(0xFFEFE6FB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text("Bestseller", style: TextStyle(color: Colors.purple, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.share, size: 27),
                          onPressed: () {}, // share logic
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Image carousel
                  if (images.isNotEmpty)
                    Container(
                      height: 220,
                      child: PageView.builder(
                        itemCount: images.length,
                        itemBuilder: (context, idx) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 38),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(images[idx], fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.image)),
                          ),
                        ),
                        onPageChanged: (idx) {
                          // slider dots can be added with setState/ValueNotifier
                        },
                      ),
                    ),
                  if (images.length > 1)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(images.length, (i) {
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 2),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[400],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  SizedBox(height: 9),
                  // Variant selection
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Selected Variant: " +
                            variantsDisplay[variantIdx].toString(),
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        SizedBox(height: 10),
                        Row(
                          children: List.generate(variantsDisplay.length, (i) => Padding(
                            padding: const EdgeInsets.only(right: 7),
                            child: OutlinedButton(
                              onPressed: () => selectedVariant.value = i,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: i == variantIdx ? Colors.teal : Colors.grey[300]!),
                                backgroundColor: i == variantIdx ? Colors.teal[50] : Colors.white,
                              ),
                              child: Text(
                                variantsDisplay[i].toString(),
                                style: TextStyle(
                                    color: i == variantIdx ? Colors.teal : Colors.black87,
                                    fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  // Pricing row and off amount
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Text('₹${price.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        SizedBox(width: 10),
                        if (mrp > 0)
                          Text('MRP ₹${mrp.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              )),
                        SizedBox(width: 10),
                        if (discount.isNotEmpty)
                          Text(discount,
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 3),
                    child: Text("₹${(price/50).toStringAsFixed(2)}/ml  •  (Inclusive of all Taxes)", style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ),
                  // Quantity selector + add to cart
                  Padding(
                    padding: EdgeInsets.all(18.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(9)),
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            child: Row(
                              children: [
                                Text("1 Bottle", style: TextStyle(fontWeight: FontWeight.w600)),
                                Icon(Icons.expand_more, size: 22)
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: () {}, // Add to cart logic
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              child: Text("ADD TO CART", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            ),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal[800],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9))),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              );
            }
          );
        },
      ),
    );
  }
}
