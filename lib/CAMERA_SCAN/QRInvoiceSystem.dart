import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class QRInvoiceSystem extends StatefulWidget {
  const QRInvoiceSystem({super.key});

  @override
  State<QRInvoiceSystem> createState() => _QRInvoiceSystemState();
}

class _QRInvoiceSystemState extends State<QRInvoiceSystem> {
  int _currentIndex = 0;
  final List<Invoice> _invoices = [];
  final List<Product> _scannedProducts = [];

  // Product database for reusable period products
  final Map<String, Product> _productDatabase = {
    // Menstrual Cups
    '8901234567890': Product(
      id: '8901234567890',
      name: 'Whisper Menstrual Cup - Small',
      price: 499.00,
      description: 'Medical Grade Silicone Cup - 25ml',
      category: 'Menstrual Cups',
    ),
    '8901234567891': Product(
      id: '8901234567891',
      name: 'Whisper Menstrual Cup - Medium',
      price: 599.00,
      description: 'Medical Grade Silicone Cup - 30ml',
      category: 'Menstrual Cups',
    ),
    '8901234567892': Product(
      id: '8901234567892',
      name: 'Whisper Menstrual Cup - Large',
      price: 699.00,
      description: 'Medical Grade Silicone Cup - 35ml',
      category: 'Menstrual Cups',
    ),
    
    // Period Panties
    '8901234567893': Product(
      id: '8901234567893',
      name: 'Whisper Period Panty - XS',
      price: 799.00,
      description: 'Reusable Absorbent Panty - Extra Small',
      category: 'Period Panties',
    ),
    '8901234567894': Product(
      id: '8901234567894',
      name: 'Whisper Period Panty - S',
      price: 849.00,
      description: 'Reusable Absorbent Panty - Small',
      category: 'Period Panties',
    ),
    '8901234567895': Product(
      id: '8901234567895',
      name: 'Whisper Period Panty - M',
      price: 899.00,
      description: 'Reusable Absorbent Panty - Medium',
      category: 'Period Panties',
    ),
    '8901234567896': Product(
      id: '8901234567896',
      name: 'Whisper Period Panty - L',
      price: 949.00,
      description: 'Reusable Absorbent Panty - Large',
      category: 'Period Panties',
    ),
    '8901234567897': Product(
      id: '8901234567897',
      name: 'Whisper Period Panty - XL',
      price: 999.00,
      description: 'Reusable Absorbent Panty - Extra Large',
      category: 'Period Panties',
    ),
    
    // Reusable Pads
    '8901234567898': Product(
      id: '8901234567898',
      name: 'Whisper Reusable Pad Set',
      price: 1299.00,
      description: 'Set of 5 Reusable Cloth Pads',
      category: 'Reusable Pads',
    ),
    
    // Starter Kits
    '8901234567899': Product(
      id: '8901234567899',
      name: 'Whisper Eco-Friendly Kit',
      price: 2499.00,
      description: 'Cup + 2 Panties + Reusable Pads',
      category: 'Starter Kits',
    ),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Eco Period Products Scanner'),
        backgroundColor: Colors.pink.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (_scannedProducts.isNotEmpty)
            Badge(
              label: Text(_scannedProducts.length.toString()),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => setState(() => _currentIndex = 1),
              ),
            ),
        ],
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan QR',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Invoices',
          ),
        ],
      ),
      floatingActionButton: _currentIndex == 1 && _scannedProducts.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _generateInvoice,
              icon: const Icon(Icons.receipt),
              label: const Text('Create Invoice'),
              backgroundColor: Colors.pink,
            )
          : null,
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return QRScannerScreen(
          onProductScanned: _handleProductScanned,
        );
      case 1:
        return CartScreen(
          products: _scannedProducts,
          onRemoveProduct: _removeProduct,
          onUpdateQuantity: _updateQuantity,
        );
      case 2:
        return InvoicesScreen(
          invoices: _invoices,
          onViewInvoice: _viewInvoice,
        );
      default:
        return const SizedBox();
    }
  }

  void _handleProductScanned(String qrData) {
    final productId = qrData.trim();
    
    // Show scanning feedback
    _showScanningFeedback();
    
    // Check if product exists in database
    if (_productDatabase.containsKey(productId)) {
      final product = _productDatabase[productId]!;
      
      // Check if product already in cart
      final existingIndex = _scannedProducts.indexWhere((p) => p.id == productId);
      
      if (existingIndex >= 0) {
        // Increase quantity
        setState(() {
          _scannedProducts[existingIndex] = _scannedProducts[existingIndex].copyWith(
            quantity: _scannedProducts[existingIndex].quantity + 1,
          );
        });
        _showSuccessSnackBar('${product.name} quantity increased to ${_scannedProducts[existingIndex].quantity}');
      } else {
        // Add new product
        setState(() {
          _scannedProducts.add(product.copyWith(quantity: 1));
        });
        _showSuccessSnackBar('${product.name} added to cart');
      }
      
      // Switch to cart screen after short delay
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _currentIndex = 1);
      });
      
    } else {
      _showErrorSnackBar('Product not found in database');
      
      // Option: Add unknown product with manual entry
      _showAddProductDialog(productId);
    }
  }

  void _removeProduct(String productId) {
    setState(() {
      _scannedProducts.removeWhere((p) => p.id == productId);
    });
    _showSnackBar('Product removed from cart');
  }

  void _updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      _removeProduct(productId);
      return;
    }
    
    setState(() {
      final index = _scannedProducts.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        _scannedProducts[index] = _scannedProducts[index].copyWith(quantity: quantity);
      }
    });
  }

  void _generateInvoice() {
    if (_scannedProducts.isEmpty) return;

    final invoice = Invoice(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(),
      products: List.from(_scannedProducts),
      customerName: 'Walk-in Customer',
    );

    setState(() {
      _invoices.insert(0, invoice);
      _scannedProducts.clear();
    });

    _showSuccessSnackBar('Invoice created successfully!');
    setState(() => _currentIndex = 2);
  }

  void _viewInvoice(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => InvoiceDialog(invoice: invoice),
    );
  }

  void _showAddProductDialog(String productId) {
    showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        productId: productId,
        onProductAdded: (product) {
          // Add to database and cart
          setState(() {
            _productDatabase[productId] = product;
            _scannedProducts.add(product.copyWith(quantity: 1));
          });
          _showSuccessSnackBar('${product.name} added to cart');
          setState(() => _currentIndex = 1);
        },
      ),
    );
  }

  void _showScanningFeedback() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Colors.white),
            SizedBox(width: 8),
            Text('Scanning product...'),
          ],
        ),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.pink,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// QR Scanner Screen
class QRScannerScreen extends StatefulWidget {
  final Function(String) onProductScanned;

  const QRScannerScreen({super.key, required this.onProductScanned});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Scanner View
        Expanded(
          child: Stack(
            children: [
              MobileScanner(
                controller: cameraController,
                onDetect: (capture) {
                  if (_isScanning) return;
                  
                  final List<Barcode> barcodes = capture.barcodes;
                  if (barcodes.isNotEmpty) {
                    _isScanning = true;
                    final String code = barcodes.first.rawValue ?? '';
                    
                    widget.onProductScanned(code);
                    
                    // Prevent multiple scans
                    Future.delayed(const Duration(seconds: 2), () {
                      _isScanning = false;
                    });
                  }
                },
              ),
              
              // Scanner Overlay
              const ScannerOverlay(),
              
              // Top Info
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: const Text(
                    'Scan Product Barcode/QR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.black87,
          child: Column(
            children: [
              const Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              const Text(
                'Point camera at product barcode',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Try scanning: Menstrual Cups, Period Panties, etc.',
                style: TextStyle(color: Colors.white60, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _productChip('Menstrual Cup', '8901234567890'),
                  _productChip('Period Panty', '8901234567893'),
                  _productChip('Reusable Pad', '8901234567898'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _productChip(String name, String code) {
    return ActionChip(
      label: Text(name),
      onPressed: () => widget.onProductScanned(code),
      backgroundColor: Colors.pink.shade700,
      labelStyle: const TextStyle(color: Colors.white),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}

// Fixed Scanner Overlay
class ScannerOverlay extends StatelessWidget {
  const ScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScannerOverlayPainter(),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const scannerWidth = 250.0;
    const scannerHeight = 150.0;
    
    final scannerRect = Rect.fromCenter(
      center: center,
      width: scannerWidth,
      height: scannerHeight,
    );

    // Draw background overlay
    final backgroundPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRect(scannerRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(backgroundPath, backgroundPaint);

    // Draw scanner border
    final borderPaint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    canvas.drawRect(scannerRect, borderPaint);

    // Draw corner lines
    final cornerPaint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    const cornerLength = 20.0;

    // Top-left corner
    canvas.drawLine(
      scannerRect.topLeft,
      scannerRect.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.topLeft,
      scannerRect.topLeft + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      scannerRect.topRight,
      scannerRect.topRight - const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.topRight,
      scannerRect.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      scannerRect.bottomLeft,
      scannerRect.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.bottomLeft,
      scannerRect.bottomLeft - const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      scannerRect.bottomRight,
      scannerRect.bottomRight - const Offset(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scannerRect.bottomRight,
      scannerRect.bottomRight - const Offset(0, cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Cart Screen
class CartScreen extends StatelessWidget {
  final List<Product> products;
  final Function(String) onRemoveProduct;
  final Function(String, int) onUpdateQuantity;

  const CartScreen({
    super.key,
    required this.products,
    required this.onRemoveProduct,
    required this.onUpdateQuantity,
  });

  double get totalAmount {
    return products.fold(0, (sum, product) => sum + (product.price * product.quantity));
  }

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Scan product barcodes to add items',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return CartItemCard(
                product: product,
                onRemove: () => onRemoveProduct(product.id),
                onQuantityUpdate: (quantity) => onUpdateQuantity(product.id, quantity),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    '₹${totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              Text(
                '${products.length} item${products.length > 1 ? 's' : ''}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Cart Item Card
class CartItemCard extends StatelessWidget {
  final Product product;
  final VoidCallback onRemove;
  final Function(int) onQuantityUpdate;

  const CartItemCard({
    super.key,
    required this.product,
    required this.onRemove,
    required this.onQuantityUpdate,
  });

  @override
  Widget build(BuildContext context) {
    // Use different icons based on category
    IconData icon = Icons.shopping_bag;
    Color iconColor = Colors.pink.shade700;
    
    if (product.category == 'Menstrual Cups') {
      icon = Icons.bloodtype;
      iconColor = Colors.purple.shade700;
    } else if (product.category == 'Period Panties') {
      icon = Icons.undo_rounded;
      iconColor = Colors.pink.shade700;
    } else if (product.category == 'Reusable Pads') {
      icon = Icons.layers;
      iconColor = Colors.blue.shade700;
    } else if (product.category == 'Starter Kits') {
      icon = Icons.medical_services;
      iconColor = Colors.green.shade700;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Product Icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            
            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${product.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            // Quantity Controls
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () => onQuantityUpdate(product.quantity - 1),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.quantity.toString(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => onQuantityUpdate(product.quantity + 1),
                  iconSize: 18,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            
            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

// Invoices Screen
class InvoicesScreen extends StatelessWidget {
  final List<Invoice> invoices;
  final Function(Invoice) onViewInvoice;

  const InvoicesScreen({
    super.key,
    required this.invoices,
    required this.onViewInvoice,
  });

  @override
  Widget build(BuildContext context) {
    if (invoices.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No invoices yet',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Create your first invoice by scanning products',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return InvoiceCard(
          invoice: invoice,
          onTap: () => onViewInvoice(invoice),
        );
      },
    );
  }
}

// Invoice Card
class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final VoidCallback onTap;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.pink.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.receipt,
            color: Colors.pink.shade700,
          ),
        ),
        title: Text(
          invoice.id,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('dd MMM yyyy, hh:mm a').format(invoice.date),
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              '${invoice.totalItems} items • ₹${invoice.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: const Icon(Icons.visibility, color: Colors.blue),
        onTap: onTap,
      ),
    );
  }
}

// Invoice Dialog
class InvoiceDialog extends StatelessWidget {
  final Invoice invoice;

  const InvoiceDialog({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Text(
                'INVOICE - ECO PRODUCTS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.pink.shade700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Invoice Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Invoice ID: ${invoice.id}'),
                Text(DateFormat('dd/MM/yyyy').format(invoice.date)),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${invoice.customerName}'),
            const SizedBox(height: 16),
            
            const Divider(),
            
            // Products List
            const Text(
              'Eco-Friendly Products:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            
            ...invoice.products.map((product) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text('${product.name} (x${product.quantity})'),
                  ),
                  Text('₹${(product.price * product.quantity).toStringAsFixed(2)}'),
                ],
              ),
            )),
            
            const Divider(),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${invoice.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement print/share functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Print/Share functionality coming soon!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                    ),
                    child: const Text('Print/Share'),
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

// Add Product Dialog
class AddProductDialog extends StatefulWidget {
  final String productId;
  final Function(Product) onProductAdded;

  const AddProductDialog({
    super.key,
    required this.productId,
    required this.onProductAdded,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _category = 'Menstrual Cups';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Eco Product'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Scanned ID: ${widget.productId}'),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price (₹)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              items: const [
                DropdownMenuItem(value: 'Menstrual Cups', child: Text('Menstrual Cups')),
                DropdownMenuItem(value: 'Period Panties', child: Text('Period Panties')),
                DropdownMenuItem(value: 'Reusable Pads', child: Text('Reusable Pads')),
                DropdownMenuItem(value: 'Starter Kits', child: Text('Starter Kits')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _category = value!),
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _addProduct,
          child: const Text('Add to Cart'),
        ),
      ],
    );
  }

  void _addProduct() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter product name and price')),
      );
      return;
    }

    final product = Product(
      id: widget.productId,
      name: _nameController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      description: _descriptionController.text,
      category: _category,
    );

    widget.onProductAdded(product);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

// Data Models
class Product {
  final String id;
  final String name;
  final double price;
  final String description;
  final String category;
  final int quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.category,
    this.quantity = 1,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? description,
    String? category,
    int? quantity,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      description: description ?? this.description,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
    );
  }
}

class Invoice {
  final String id;
  final DateTime date;
  final List<Product> products;
  final String customerName;

  const Invoice({
    required this.id,
    required this.date,
    required this.products,
    required this.customerName,
  });

  double get totalAmount {
    return products.fold(0, (sum, product) => sum + (product.price * product.quantity));
  }

  int get totalItems {
    return products.fold(0, (sum, product) => sum + product.quantity);
  }
}
