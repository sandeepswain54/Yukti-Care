import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:service_app/Distributor/CreateInvoiceScreen.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedFilterIndex = 0;
  final List<String> filters = ["All", "Today", "Yesterday", "- 7 Days"];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.3,
        title: const Text(
          "Invoices",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions: const [
          Icon(Icons.search, color: Colors.black87),
          SizedBox(width: 12),
          Icon(Icons.more_vert, color: Colors.black87),
          SizedBox(width: 12),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.black54,
              indicatorColor: Colors.blue,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Paid"),
                Tab(text: "Unpaid"),
              ],
            ),
          ),
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          _buildInvoiceTab(),
          _buildInvoiceTab(),
          _buildInvoiceTab(),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
       onPressed: () {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => CreateInvoiceScreen()),
  );
},

        backgroundColor: Colors.blue.shade700,
        label: const Text(
          "INVOICE",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // ===== Helper Widget for Each Tab =====
  Widget _buildInvoiceTab() {
    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(filters.length, (index) {
                final isSelected = _selectedFilterIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      filters[index],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Colors.blue.shade600,
                    backgroundColor: Colors.grey.shade200,
                    onSelected: (value) {
                      setState(() {
                        _selectedFilterIndex = index;
                      });
                    },
                  ),
                );
              }),
            ),
          ),
        ),

        const Spacer(),

        // Empty State Illustration
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.description_outlined,
                size: 100,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 10),
              const Text(
                "No Invoices in this section.",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),

        const Spacer(),
      ],
    );
  }
}
