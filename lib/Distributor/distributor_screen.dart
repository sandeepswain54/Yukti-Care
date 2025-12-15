import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  bool isOnline = true;
  late TabController _tabController;
  int _currentTabIndex = 0;

  final List<String> _tabTitles = [
    'Sale',
    'Orders',
    'To Pay',
    'To Collect',
    'Low Stocks',
    'Abandoned',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTitles.length, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // ===== Top Bar =====
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.store, color: Colors.blue),
                        ),
                        const SizedBox(width: 8),
                         const SizedBox(height: 80),
                        const Text(
                          "Distributor",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green.shade50 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isOnline ? Colors.green : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isOnline ? "Online" : "Offline",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: isOnline ? Colors.green.shade800 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          value: isOnline,
                          onChanged: (value) {
                            setState(() {
                              isOnline = value;
                            });
                          },
                          activeColor: Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                
                // ===== Business Summary =====
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Business Summary",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Complete business summary in a glance",
                          style: TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== Tab Bar =====
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.blue.shade50,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.normal,
                fontSize: 13,
              ),
              tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
            ),
          ),

          // ===== Tab Content =====
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Sale Tab
                _buildSaleTab(),
                // Orders Tab
                _buildOrdersTab(),
                // To Pay Tab
                _buildToPayTab(),
                // To Collect Tab
                _buildToCollectTab(),
                // Low Stocks Tab
                _buildLowStocksTab(),
                // Abandoned Tab
                _buildAbandonedTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== Sale Tab =====
  Widget _buildSaleTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sales Overview Cards
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  "Today's Sales",
                  "₹12,450",
                  Colors.green,
                  Icons.trending_up,
                  "+12%",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  "This Week",
                  "₹89,230",
                  Colors.blue,
                  Icons.bar_chart,
                  "+8%",
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  "This Month",
                  "₹3,45,670",
                  Colors.orange,
                  Icons.calendar_today,
                  "+15%",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  "Total Sales",
                  "₹12,89,450",
                  Colors.purple,
                  Icons.attach_money,
                  "+22%",
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            "Recent Sales",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSalesList(),
        ],
      ),
    );
  }

  // ===== Orders Tab =====
  Widget _buildOrdersTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Stats
          Row(
            children: [
              Expanded(
                child: _orderStatCard("Pending", "12", Colors.orange),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _orderStatCard("Processing", "8", Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _orderStatCard("Completed", "45", Colors.green),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            "Recent Orders",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildOrdersList(),
        ],
      ),
    );
  }

  // ===== To Pay Tab =====
  Widget _buildToPayTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountCard("Total Amount Due", "₹45,670", Colors.red),
          const SizedBox(height: 16),
          _amountCard("Overdue Amount", "₹12,340", Colors.orange),
          const SizedBox(height: 16),
          _amountCard("Due This Week", "₹8,900", Colors.blue),

          const SizedBox(height: 24),
          const Text(
            "Pending Payments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildPaymentsList(),
        ],
      ),
    );
  }

  // ===== To Collect Tab =====
  Widget _buildToCollectTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _amountCard("Total Receivable", "₹67,890", Colors.green),
          const SizedBox(height: 16),
          _amountCard("Overdue Receivables", "₹23,450", Colors.orange),
          const SizedBox(height: 16),
          _amountCard("Expected This Week", "₹15,670", Colors.blue),

          const SizedBox(height: 24),
          const Text(
            "Pending Collections",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCollectionsList(),
        ],
      ),
    );
  }

  // ===== Low Stocks Tab =====
  Widget _buildLowStocksTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stockAlertCard("Critical Stock", "8 items", Colors.red),
          const SizedBox(height: 16),
          _stockAlertCard("Low Stock", "15 items", Colors.orange),
          const SizedBox(height: 16),
          _stockAlertCard("Out of Stock", "3 items", Colors.purple),

          const SizedBox(height: 24),
          const Text(
            "Low Stock Items",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildLowStockList(),
        ],
      ),
    );
  }

  // ===== Abandoned Tab =====
  Widget _buildAbandonedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _abandonedCard("Today", "3 carts", "₹4,560", Colors.red),
          const SizedBox(height: 16),
          _abandonedCard("This Week", "12 carts", "₹18,900", Colors.orange),
          const SizedBox(height: 16),
          _abandonedCard("This Month", "45 carts", "₹67,890", Colors.purple),

          const SizedBox(height: 24),
          const Text(
            "Recent Abandoned Carts",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAbandonedList(),
        ],
      ),
    );
  }

  // ===== Reusable Widgets =====
  Widget _metricCard(String title, String value, Color color, IconData icon, String trend) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
              Text(
                trend,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _orderStatCard(String status, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            status,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _amountCard(String title, String amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockAlertCard(String level, String count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              level,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _abandonedCard(String period, String carts, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            period,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                carts,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===== List Builders =====
  Widget _buildSalesList() {
    final sales = [
      {'customer': 'Customer A', 'amount': '₹2,450', 'time': '2 hours ago'},
      {'customer': 'Customer B', 'amount': '₹1,890', 'time': '4 hours ago'},
      {'customer': 'Customer C', 'amount': '₹3,210', 'time': '5 hours ago'},
      {'customer': 'Customer D', 'amount': '₹890', 'time': '6 hours ago'},
    ];

    return Column(
      children: sales.map((sale) => _listItem(
        title: sale['customer']!,
        subtitle: sale['time']!,
        trailing: sale['amount']!,
        color: Colors.green,
      )).toList(),
    );
  }

  Widget _buildOrdersList() {
    final orders = [
      {'id': '#ORD-001', 'status': 'Pending', 'amount': '₹2,450'},
      {'id': '#ORD-002', 'status': 'Processing', 'amount': '₹1,890'},
      {'id': '#ORD-003', 'status': 'Completed', 'amount': '₹3,210'},
    ];

    return Column(
      children: orders.map((order) => _listItem(
        title: order['id']!,
        subtitle: order['status']!,
        trailing: order['amount']!,
        color: order['status'] == 'Pending' ? Colors.orange : 
               order['status'] == 'Processing' ? Colors.blue : Colors.green,
      )).toList(),
    );
  }

  Widget _buildPaymentsList() {
    final payments = [
      {'vendor': 'Vendor A', 'amount': '₹12,340', 'due': 'Overdue'},
      {'vendor': 'Vendor B', 'amount': '₹8,900', 'due': 'Due Today'},
      {'vendor': 'Vendor C', 'amount': '₹15,670', 'due': 'Due in 3 days'},
    ];

    return Column(
      children: payments.map((payment) => _listItem(
        title: payment['vendor']!,
        subtitle: payment['due']!,
        trailing: payment['amount']!,
        color: payment['due'] == 'Overdue' ? Colors.red : Colors.orange,
      )).toList(),
    );
  }

  Widget _buildCollectionsList() {
    final collections = [
      {'customer': 'Customer X', 'amount': '₹8,900', 'due': 'Due Today'},
      {'customer': 'Customer Y', 'amount': '₹12,340', 'due': 'Overdue'},
      {'customer': 'Customer Z', 'amount': '₹5,670', 'due': 'Due in 2 days'},
    ];

    return Column(
      children: collections.map((collection) => _listItem(
        title: collection['customer']!,
        subtitle: collection['due']!,
        trailing: collection['amount']!,
        color: collection['due'] == 'Overdue' ? Colors.red : Colors.green,
      )).toList(),
    );
  }

  Widget _buildLowStockList() {
    final stocks = [
      {'product': 'Product A', 'stock': '2 left', 'status': 'Critical'},
      {'product': 'Product B', 'stock': '5 left', 'status': 'Low'},
      {'product': 'Product C', 'stock': '0 left', 'status': 'Out of Stock'},
    ];

    return Column(
      children: stocks.map((stock) => _listItem(
        title: stock['product']!,
        subtitle: stock['stock']!,
        trailing: stock['status']!,
        color: stock['status'] == 'Critical' ? Colors.red : 
               stock['status'] == 'Low' ? Colors.orange : Colors.purple,
      )).toList(),
    );
  }

  Widget _buildAbandonedList() {
    final abandoned = [
      {'customer': 'Customer P', 'items': '3 items', 'value': '₹2,450'},
      {'customer': 'Customer Q', 'items': '2 items', 'value': '₹1,890'},
      {'customer': 'Customer R', 'items': '5 items', 'value': '₹4,560'},
    ];

    return Column(
      children: abandoned.map((item) => _listItem(
        title: item['customer']!,
        subtitle: item['items']!,
        trailing: item['value']!,
        color: Colors.red,
      )).toList(),
    );
  }

  Widget _listItem({
    required String title,
    required String subtitle,
    required String trailing,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            trailing,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}