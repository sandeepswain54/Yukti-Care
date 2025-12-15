// checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_provider.dart';
import 'payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Checkout')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Delivery Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildTextFormField('Full Name', _nameController, Icons.person),
              _buildTextFormField('Phone Number', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
              _buildTextFormField('Address', _addressController, Icons.home, maxLines: 3),
              _buildTextFormField('District', _districtController, Icons.location_city),
              _buildTextFormField('State', _stateController, Icons.map),
              _buildTextFormField('Pincode', _pincodeController, Icons.markunread_mailbox, keyboardType: TextInputType.number),
              _buildTextFormField('Landmark (Optional)', _landmarkController, Icons.flag),
              
              SizedBox(height: 24),
              Text('Order Summary', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              ...cartProvider.items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text('${item.name} (x${item.quantity})'),
                    ),
                    Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
              )).toList(),
              Divider(),
              Row(
                children: [
                  Expanded(child: Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                  Text('₹${cartProvider.totalPrice.toStringAsFixed(2)}', 
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
              
              SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Save order to Firebase first
                      final orderId = await _saveOrderToFirebase(cartProvider);
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentScreen(
                            orderId: orderId,
                            totalAmount: cartProvider.totalPrice,
                            address: {
                              'name': _nameController.text,
                              'phone': _phoneController.text,
                              'address': _addressController.text,
                              'district': _districtController.text,
                              'state': _stateController.text,
                              'pincode': _pincodeController.text,
                              'landmark': _landmarkController.text,
                            },
                          ),
                        ),
                      );
                    }
                  },
                  child: Text('PROCEED TO PAYMENT', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(String label, TextEditingController controller, IconData icon, 
                           {TextInputType keyboardType = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            if (label != 'Landmark (Optional)') {
              return 'Please enter $label';
            }
          }
          return null;
        },
      ),
    );
  }

  Future<String> _saveOrderToFirebase(CartProvider cartProvider) async {
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();
    final orderData = {
      'orderId': orderRef.id,
      'items': cartProvider.items.map((item) => item.toMap()).toList(),
      'totalAmount': cartProvider.totalPrice,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'customerName': _nameController.text,
      'customerPhone': _phoneController.text,
      'address': {
        'fullAddress': _addressController.text,
        'district': _districtController.text,
        'state': _stateController.text,
        'pincode': _pincodeController.text,
        'landmark': _landmarkController.text,
      },
    };

    await orderRef.set(orderData);
    return orderRef.id;
  }
}