import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:service_app/Cart_Product/cart_model.dart';
import 'package:service_app/Cart_Product/cart_provider.dart';
import 'package:service_app/Cart_Product/cart_screen.dart';
import 'package:service_app/Cart_Product/quantity_selector_dialog.dart';
import 'package:service_app/Distributor/new_product_screen.dart';

class ProductCatalogueScreen extends StatelessWidget {
  const ProductCatalogueScreen({super.key});

  // List of 7 fallback images
  final List<String> fallbackImages = const [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRxaW56CpZ8xbAAF0OHn37DJsqQxQACgDeV0A&s',
    'https://rukminim2.flixcart.com/image/480/640/xif0q/sanitary-pad-pantyliner/0/s/o/reusable-period-panty-for-women-girls-medium-size-90-97cm-original-imahhbvfg4fnejgj.jpeg?q=20',
    'https://m.media-amazon.com/images/I/61BshYp0HJL._AC_UF1000,1000_QL80_.jpg',
    'https://m.media-amazon.com/images/I/61-MZbI2OiL._AC_UF1000,1000_QL80_.jpg',
    'https://via.placeholder.com/150/96CEB4/FFFFFF?text=Product+5',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcROTc4xDYJmsEiMWp3KfI3KH9tJmPzWD_eKSw&s',
    'https://www.peesafe.com/cdn/shop/files/RS_pads.jpg?v=1756094477&width=2100',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            "Catalogue",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.black),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen()));
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Consumer<CartProvider>(
                  builder: (context, cart, child) {
                    return cart.totalItems > 0 ? Container(
                      padding: EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${cart.totalItems}',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                        textAlign: TextAlign.center,
                      ),
                    ) : SizedBox();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            DefaultTabController(
              length: 3,
              child: Padding(
                padding: EdgeInsets.zero,
                child: TabBar(
                  isScrollable: false,
                  padding: EdgeInsets.zero,
                  labelPadding: EdgeInsets.symmetric(horizontal: 16),
                  labelColor: Colors.blue,
                  unselectedLabelColor: Colors.blue[300],
                  indicatorColor: Colors.blue,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                  tabs: const [
                    Tab(text: "Products"),
                    Tab(text: "Inventory"),
                    Tab(text: "Categories"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[400]!),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: TextField(
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Search by name or brand",
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: Colors.grey[700]),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('products')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No products found.'));
                  }
                  
                  final products = snapshot.data!.docs;
                  return ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        16, 6, 16, MediaQuery.of(context).padding.bottom + kBottomNavigationBarHeight + 80),
                    itemCount: products.length,
                    physics: AlwaysScrollableScrollPhysics(),
                    separatorBuilder: (_, __) => SizedBox(height: 16),
                    itemBuilder: (ctx, idx) {
                      final prod = products[idx].data() as Map<String, dynamic>;
                      final docId = products[idx].id;
                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  (prod['images'] != null && prod['images'].isNotEmpty)
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            prod['images'][0],
                                            width: 60, 
                                            height: 60, 
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              // Use fallback image based on index
                                              final fallbackIndex = idx % fallbackImages.length;
                                              return Image.network(
                                                fallbackImages[fallbackIndex],
                                                width: 60,
                                                height: 60,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          width: 60,
                                          height: 60,
                                          color: Color(0xFF40B6AC),
                                          child: Icon(Icons.biotech, color: Colors.white, size: 38),
                                        ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(prod['name'] ?? '',
                                            style: TextStyle(fontWeight: FontWeight.w500),
                                            maxLines: 1),
                                        Text(prod['desc'] ?? '',
                                            maxLines: 2, style: TextStyle(fontSize: 13)),
                                        SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Text("₹ ${prod['unitPrice'] ?? ''}",
                                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                            SizedBox(width: 4),
                                            Text("Sale Price",
                                                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                            Spacer(),
                                            Text("₹ ${prod['mrp'] ?? ''}",
                                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16)),
                                            SizedBox(width: 4),
                                            Text("MRP",
                                                style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Divider(),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Add to Cart Button
                                  IconButton(
                                    tooltip: "Add to Cart",
                                    icon: Icon(Icons.add_shopping_cart, color: Colors.green[800]),
                                    onPressed: () {
                                      _showAddToCartDialog(context, prod, docId);
                                    },
                                  ),

                                  // View Details Button
                                  IconButton(
                                    tooltip: "View Details",
                                    icon: Icon(Icons.visibility, color: Colors.blue[800]),
                                    onPressed: () {
                                      _showProductDetails(context, prod, idx);
                                    },
                                  ),

                                  // Edit Button
                                  IconButton(
                                    tooltip: "Edit/Update",
                                    icon: Icon(Icons.edit, color: Colors.orange[800]),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => NewProductScreen(),
                                        ),
                                      );
                                    },
                                  ),

                                  // Delete Button
                                  IconButton(
                                    tooltip: "Delete",
                                    icon: Icon(Icons.delete, color: Colors.red[700]),
                                    onPressed: () => _deleteProduct(context, docId),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: kBottomNavigationBarHeight),
        child: FloatingActionButton.extended(
          backgroundColor: Colors.blue[700],
          heroTag: 'product_fab',
          icon: Icon(Icons.add),
          label: Text("PRODUCT"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const NewProductScreen()),
            );
          },
        ),
      ),
    );
  }

  void _showAddToCartDialog(BuildContext context, Map<String, dynamic> prod, String docId) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    
    showDialog(
      context: context,
          builder: (context) => QuantitySelectorDialog(
        product: prod,
        onAddToCart: (quantity) {
          // Safely parse numeric values that might be stored as String or num in Firestore
          double parseDouble(dynamic v) {
            if (v is num) return v.toDouble();
            if (v is String) return double.tryParse(v) ?? 0.0;
            return 0.0;
          }

          final cartItem = CartItem(
            productId: docId,
            name: prod['name'] ?? 'Unknown Product',
            image: (prod['images'] != null && prod['images'].isNotEmpty)
                ? prod['images'][0]
                : '',
            unitPrice: parseDouble(prod['unitPrice'] ?? 0),
            mrp: parseDouble(prod['mrp'] ?? 0),
            quantity: quantity,
            size: prod['size'],
            color: prod['color'],
          );
          cartProvider.addToCart(cartItem);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${prod['name']} added to cart!'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> prod, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => Padding(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (prod['images'] != null && prod['images'].isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    prod['images'][0],
                    height: 160, 
                    width: double.infinity, 
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Use fallback image based on index
                      final fallbackIndex = index % fallbackImages.length;
                      return Image.network(
                        fallbackImages[fallbackIndex],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 160,
                  width: double.infinity,
                  color: Color(0xFF40B6AC),
                  child: Icon(Icons.biotech, color: Colors.white, size: 60),
                ),
              SizedBox(height: 18),
              Text(prod['name'] ?? '',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
              SizedBox(height: 6),
              Text(prod['desc'] ?? ''),
              SizedBox(height: 18),
              Text("Unit Price: ₹${prod['unitPrice'] ?? ''}",
                  style: TextStyle(fontSize: 16)),
              SizedBox(height: 3),
              Text("MRP: ₹${prod['mrp'] ?? ''}"),
              SizedBox(height: 3),
              Text("Category: ${prod['category'] ?? ''}"),
              SizedBox(height: 3),
              Text("Quantity: ${prod['quantity'] ?? ''}"),
              SizedBox(height: 3),
              Text("Size: ${prod['size'] ?? ''}"),
              SizedBox(height: 3),
              Text("Color: ${prod['color'] ?? ''}"),
              SizedBox(height: 3),
              Text("Delivery Time: ${prod['deliveryTime'] ?? ''}"),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("CLOSE")),
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, String docId) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Product'),
        content: Text('Are you sure you want to delete this product?'),
        actions: [
          TextButton(
              child: Text('No'),
              onPressed: () => Navigator.of(ctx).pop(false)),
          TextButton(
              child: Text('Yes'),
              onPressed: () => Navigator.of(ctx).pop(true)),
        ],
      ),
    );
    if (confirmDelete) {
      try {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(docId)
            .delete();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Product deleted successfully')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting product: $e')));
      }
    }
  }
}