import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_app/Distributor/order_screen.dart';
// provider import not required here

class OnlineOrdersScreen extends StatelessWidget {
  const OnlineOrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: DefaultTabController(
        length: 7,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  "Online Orders",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 1),
              Padding(
                padding: EdgeInsets.zero,
                child: _OrderStatusTabs(),
              ),
              Expanded(
                child: _OrdersList(),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'orders_fab',
        backgroundColor: Colors.blue[700],
        icon: const Icon(Icons.add),
        label: const Text("ORDER"),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateOrderScreen()),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

class _OrderStatusTabs extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
  final controller = DefaultTabController.of(context);
    return Column(
      children: [
        TabBar(
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.blue[300],
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "New"),
            Tab(text: "Confirmed"),
            Tab(text: "Shipment Ready"),
            Tab(text: "In Transit"),
            Tab(text: "Completed"),
            Tab(text: "Returns"),
            Tab(text: "Cancelled"),
          ],
        ),
        AnimatedBuilder(
          animation: controller.animation!,
          builder: (context, _) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                _getStatusDescription(controller.index),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ],
    );
  }

  String _getStatusDescription(int index) {
    switch (index) {
      case 0:
        return "New orders waiting for confirmation";
      case 1:
        return "Orders confirmed and being processed";
      case 2:
        return "Orders ready for shipment";
      case 3:
        return "Orders in transit to customers";
      case 4:
        return "Successfully delivered orders";
      case 5:
        return "Return requests and processing";
      case 6:
        return "Cancelled orders";
      default:
        return "";
    }
  }
}

class _OrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    DefaultTabController.of(context);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final orders = snapshot.data!.docs;
        
        return TabBarView(
          children: List.generate(7, (tabIndex) {
            final status = _getStatusFromIndex(tabIndex);
            final filteredOrders = orders.where((doc) {
              final order = doc.data() as Map<String, dynamic>;
              return order['status'] == status;
            }).toList();

            if (filteredOrders.isEmpty) {
              return _buildEmptyTabState(tabIndex);
            }

            return ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                final doc = filteredOrders[index];
                final order = doc.data() as Map<String, dynamic>;
                final orderId = doc.id;
                
                return _OrderCard(
                  order: order,
                  orderId: orderId,
                  onStatusUpdate: (newStatus) {
                    _updateOrderStatus(orderId, newStatus);
                  },
                );
              },
            );
          }),
        );
      },
    );
  }

  String _getStatusFromIndex(int index) {
    switch (index) {
      case 0: return 'pending';
      case 1: return 'confirmed';
      case 2: return 'shipment_ready';
      case 3: return 'in_transit';
      case 4: return 'completed';
      case 5: return 'returns';
      case 6: return 'cancelled';
      default: return 'pending';
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment,
            color: Colors.grey[300],
            size: 72,
          ),
          const SizedBox(height: 12),
          Text(
            "No orders found.",
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Orders will appear here when customers place them.",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTabState(int tabIndex) {
    final messages = [
      "No new orders waiting for confirmation",
      "No confirmed orders at the moment",
      "No orders ready for shipment",
      "No orders in transit",
      "No completed orders yet",
      "No return requests",
      "No cancelled orders"
    ];

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assignment_outlined,
            color: Colors.grey[300],
            size: 72,
          ),
          const SizedBox(height: 12),
          Text(
            messages[tabIndex],
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
            'status': newStatus,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      print('Error updating order status: $e');
    }
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String orderId;
  final Function(String) onStatusUpdate;

  const _OrderCard({
    required this.order,
    required this.orderId,
    required this.onStatusUpdate,
  });

  @override
  Widget build(BuildContext context) {
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final totalAmount = parseDouble(order['totalAmount'] ?? 0.0);
    final customerName = order['customerName'] ?? 'Unknown Customer';
    final customerPhone = order['customerPhone'] ?? 'No Phone';
    final status = order['status'] ?? 'pending';
    final createdAt = order['createdAt'] != null 
        ? (order['createdAt'] as Timestamp).toDate()
        : DateTime.now();
    final items = order['items'] ?? [];

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${orderId.substring(0, 8)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    _getStatusText(status).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: _getStatusColor(status),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(customerName, style: TextStyle(fontWeight: FontWeight.w500)),
                SizedBox(width: 16),
                Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(customerPhone),
              ],
            ),
            
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                SizedBox(width: 4),
                Text(
                  '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Spacer(),
                Text(
                  '₹${totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
            
            if (items.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                'Items (${items.length}):',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              SizedBox(height: 4),
              Column(
                children: items.take(2).map<Widget>((item) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text('•'),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${item['name']} x${item['quantity']}',
                            style: TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '₹${(parseDouble(item['unitPrice']) * (item['quantity'] ?? 0)).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (items.length > 2)
                Text(
                  '+ ${items.length - 2} more items',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
            ],
            
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: Icon(Icons.visibility, size: 16),
                    label: Text('Details'),
                    onPressed: () => _showOrderDetails(context, order, orderId),
                  ),
                ),
                SizedBox(width: 8),
                if (_shouldShowActions(status))
                  Expanded(
                    child: _buildActionButton(status),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return ElevatedButton.icon(
          icon: Icon(Icons.check, size: 16),
          label: Text('Confirm'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue[700]),
          onPressed: () => onStatusUpdate('confirmed'),
        );
      case 'confirmed':
        return ElevatedButton.icon(
          icon: Icon(Icons.inventory, size: 16),
          label: Text('Ready'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange[700]),
          onPressed: () => onStatusUpdate('shipment_ready'),
        );
      case 'shipment_ready':
        return ElevatedButton.icon(
          icon: Icon(Icons.local_shipping, size: 16),
          label: Text('Ship'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple[700]),
          onPressed: () => onStatusUpdate('in_transit'),
        );
      case 'in_transit':
        return ElevatedButton.icon(
          icon: Icon(Icons.done_all, size: 16),
          label: Text('Complete'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green[700]),
          onPressed: () => onStatusUpdate('completed'),
        );
      default:
        return SizedBox.shrink();
    }
  }

  bool _shouldShowActions(String status) {
    return ['pending', 'confirmed', 'shipment_ready', 'in_transit'].contains(status);
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'New';
      case 'confirmed': return 'Confirmed';
      case 'shipment_ready': return 'Shipment Ready';
      case 'in_transit': return 'In Transit';
      case 'completed': return 'Completed';
      case 'returns': return 'Returns';
      case 'cancelled': return 'Cancelled';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.blue;
      case 'shipment_ready': return Colors.purple;
      case 'in_transit': return Colors.amber[700]!;
      case 'completed': return Colors.green;
      case 'returns': return Colors.red;
      case 'cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  void _showOrderDetails(BuildContext context, Map<String, dynamic> order, String orderId) {
    final items = order['items'] ?? [];
    final address = order['address'] ?? {};
    double parseDouble(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final totalAmount = parseDouble(order['totalAmount'] ?? 0.0);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Order Details',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              
              // Order Information
              _buildDetailRow('Order ID', orderId.substring(0, 8)),
              _buildDetailRow('Customer', order['customerName'] ?? 'Unknown'),
              _buildDetailRow('Phone', order['customerPhone'] ?? 'No Phone'),
              _buildDetailRow('Status', _getStatusText(order['status'])),
              _buildDetailRow('Total Amount', '₹${totalAmount.toStringAsFixed(2)}'),
              
              SizedBox(height: 16),
              Divider(),
              
              // Address Information
              Text('Delivery Address', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(address['fullAddress'] ?? 'No address'),
              if (address['district'] != null) Text('District: ${address['district']}'),
              if (address['state'] != null) Text('State: ${address['state']}'),
              if (address['pincode'] != null) Text('Pincode: ${address['pincode']}'),
              if (address['landmark'] != null) Text('Landmark: ${address['landmark']}'),
              
              SizedBox(height: 16),
              Divider(),
              
              // Order Items
              Text('Order Items (${items.length})', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              ...items.map<Widget>((item) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] ?? 'Unknown Item'),
                            if (item['size'] != null) Text('Size: ${item['size']}', style: TextStyle(fontSize: 12)),
                            if (item['color'] != null) Text('Color: ${item['color']}', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('x${item['quantity']}'),
                      SizedBox(width: 16),
                      Text('₹${(parseDouble(item['unitPrice']) * (item['quantity'] ?? 0)).toStringAsFixed(2)}'),
                    ],
                  ),
                );
              }).toList(),
              
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text('$label:', style: TextStyle(fontWeight: FontWeight.w500)),
          SizedBox(width: 8),
          Text(value),
        ],
      ),
    );
  }
}

