// payment_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final Map<String, dynamic> address;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.totalAmount,
    required this.address,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isProcessing = false;
  bool _paymentSuccess = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);
    
    // Simulate payment processing
    await Future.delayed(Duration(seconds: 3));
    
    // Update order status in Firebase
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .update({
          'status': 'confirmed',
          'paidAt': FieldValue.serverTimestamp(),
          'paymentMethod': 'UPI',
        });
    
    setState(() {
      _isProcessing = false;
      _paymentSuccess = true;
    });
    
    // Clear cart
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    cartProvider.clearCart();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Payment')),
      body: _paymentSuccess
          ? _buildSuccessScreen()
          : _buildPaymentScreen(),
    );
  }

  Widget _buildPaymentScreen() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order ID:'),
                      Text(widget.orderId.substring(0, 8), style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount:'),
                      Text('₹${widget.totalAmount.toStringAsFixed(2)}', 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          SizedBox(height: 24),
          Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          _buildPaymentMethod('UPI', 'Pay using UPI', Icons.payment),
          _buildPaymentMethod('Credit/Debit Card', 'Pay using card', Icons.credit_card),
          _buildPaymentMethod('Net Banking', 'Internet banking', Icons.account_balance),
          
          Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                padding: EdgeInsets.symmetric(vertical: 16),
                disabledBackgroundColor: Colors.grey,
              ),
              onPressed: _isProcessing ? null : _processPayment,
              child: _isProcessing
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(width: 12),
                        Text('Processing Payment...'),
                      ],
                    )
                  : Text('PAY ₹${widget.totalAmount.toStringAsFixed(2)}', 
                      style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethod(String title, String subtitle, IconData icon) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Radio(value: title, groupValue: 'UPI', onChanged: (value) {}),
      ),
    );
  }

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 24),
            Text('Payment Successful!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Your order has been placed successfully.', 
                style: TextStyle(fontSize: 16, color: Colors.grey[600]), textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Order ID: ${widget.orderId}', 
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              child: Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}