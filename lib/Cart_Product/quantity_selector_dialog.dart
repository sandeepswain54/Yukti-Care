import 'package:flutter/material.dart';

class QuantitySelectorDialog extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(int) onAddToCart;

  const QuantitySelectorDialog({
    Key? key,
    required this.product,
    required this.onAddToCart,
  }) : super(key: key);

  @override
  _QuantitySelectorDialogState createState() => _QuantitySelectorDialogState();
}

class _QuantitySelectorDialogState extends State<QuantitySelectorDialog> {
  int _quantity = 1;

  void _addToCart(BuildContext context) {
    widget.onAddToCart(_quantity);
    Navigator.of(context).pop(); // Close the dialog
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add to Cart',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // Product Info
            Row(
              children: [
                widget.product['images'] != null && widget.product['images'].isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.product['images'][0],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey[300],
                              child: Icon(Icons.shopping_bag, color: Colors.grey[600]),
                            );
                          },
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: Icon(Icons.shopping_bag, color: Colors.grey[600]),
                      ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['name'] ?? 'Product',
                        style: TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Builder(
                        builder: (context) {
                          // unitPrice in product map can be a String or a number. Parse safely.
                          final dynamic rawPrice = widget.product['unitPrice'];
                          double unitPrice = 0.0;
                          if (rawPrice is num) unitPrice = rawPrice.toDouble();
                          else if (rawPrice is String) unitPrice = double.tryParse(rawPrice) ?? 0.0;

                          return Text(
                            '₹${unitPrice.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.green),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            Text('Select Quantity', style: TextStyle(fontWeight: FontWeight.w500)),
            SizedBox(height: 12),
            
            // Quantity Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  iconSize: 30,
                  onPressed: () {
                    if (_quantity > 1) {
                      setState(() => _quantity--);
                    }
                  },
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$_quantity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add_circle, color: Colors.green),
                  iconSize: 30,
                  onPressed: () {
                    setState(() => _quantity++);
                  },
                ),
              ],
            ),
            
            SizedBox(height: 16),
            Builder(
              builder: (context) {
                final dynamic rawPrice = widget.product['unitPrice'];
                double unitPrice = 0.0;
                if (rawPrice is num) unitPrice = rawPrice.toDouble();
                else if (rawPrice is String) unitPrice = double.tryParse(rawPrice) ?? 0.0;

                final double total = unitPrice * _quantity;
                return Text(
                  'Total: ₹${total.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                );
              },
            ),
            
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel', style: TextStyle(color: Colors.grey[600])),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _addToCart(context),
                    child: Text('Add to Cart'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}