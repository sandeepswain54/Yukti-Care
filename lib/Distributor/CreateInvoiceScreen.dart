import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({Key? key}) : super(key: key);

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _customerController = TextEditingController(text: 'Guest Customer');
  final TextEditingController _notesController = TextEditingController();

  void _pickInvoiceDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Invoice',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        centerTitle: false,
        elevation: 0.5,
        actions: [
          IconButton(
              icon: const Icon(Icons.settings, color: Colors.blue),
              onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Invoice Date Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice Date', style: TextStyle(fontSize: 16)),
                InkWell(
                  onTap: _pickInvoiceDate,
                  child: Row(
                    children: [
                      Text(
                        DateFormat.yMMMd().format(_selectedDate),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.calendar_today_rounded, size: 20, color: Colors.blue),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 18),
            // Invoice Number Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Invoice #', style: TextStyle(fontSize: 16)),
                Text(
                  'Auto Assigned (INV-0002)',
                  style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 22),
            // Customer Field
            Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer', style: TextStyle(fontSize: 13, color: Colors.black45)),
                  TextField(
                    controller: _customerController,
                    style: const TextStyle(fontSize: 17),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Add Line Item Button
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart_outlined, color: Colors.blue),
                  label: const Text('Add Line Item', style: TextStyle(color: Colors.blue, fontSize: 16)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    side: const BorderSide(color: Colors.blue),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // Logic to add line items
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Notes Field
            Container(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(7),
              ),
              child: TextField(
                controller: _notesController,
                style: const TextStyle(fontSize: 17),
                maxLines: 2,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Notes',
                ),
              ),
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
      bottomNavigationBar: SizedBox(
        height: 55,
        child: ElevatedButton(
          onPressed: () {
            // Save/create invoice logic here
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade200,
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(0), topRight: Radius.circular(0)))),
          child: const Text(
            'CREATE INVOICE',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
