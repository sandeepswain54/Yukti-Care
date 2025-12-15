import 'package:flutter/material.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  DateTime selectedDate = DateTime.now();
  TextEditingController customerController = TextEditingController(text: "Guest Customer");
  TextEditingController noteController = TextEditingController();

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () { Navigator.pop(context); },
                    child: const Icon(Icons.close, size: 30),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    "Order",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.settings, color: Colors.blue[800]),
                ],
              ),
            ),
            const Divider(height: 1),
            // Order Date and Invoice
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text("Order Date", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                      Spacer(),
                      Text(
                        "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, "0")}-${selectedDate.day.toString().padLeft(2, "0")}",
                        style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      SizedBox(width: 8),
                      InkWell(
                        onTap: () => _pickDate(context),
                        child: Icon(Icons.calendar_today_outlined, size: 22, color: Colors.blue[700]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Text("Invoice #", style: TextStyle(color: Colors.grey[700], fontSize: 16)),
                      Spacer(),
                      Text(
                        "Auto Assigned (INV-0002)",
                        style: TextStyle(color: Colors.blue[800], fontWeight: FontWeight.w500, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Customer - Editable
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Customer", style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  SizedBox(height: 4),
                  TextField(
                    controller: customerController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey[400]!)),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(fontSize: 17, color: Colors.black),
                  ),
                ],
              ),
            ),
            // Add Line Item Button
            SizedBox(height: 30),
            Center(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add_shopping_cart, color: Colors.blue[800]),
                label: Text(
                  "Add Line Item",
                  style: TextStyle(color: Colors.blue[800], fontSize: 17),
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: BorderSide(color: Colors.blue[800]!),
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 15),
                  textStyle: TextStyle(fontSize: 17),
                ),
              ),
            ),
            SizedBox(height: 34),
            // Notes field - Editable
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: noteController,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Notes",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ),
            Spacer(),
            // Bottom Button
            Container(
              width: double.infinity,
              height: 56,
              color: Color(0xFFAEC8F6),
              child: Center(
                child: Text(
                  "CREATE ORDER",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
