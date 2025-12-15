import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pay/pay.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:service_app/Payment_Gateway/payment_config.dart';
import 'package:service_app/model/app_constant.dart';
import 'package:service_app/model/posting_model.dart';
import 'package:service_app/model/conversation_model.dart';
import 'package:service_app/model/contact_model.dart';
import 'package:service_app/views/Widgets/calender_ui.dart';
import 'package:service_app/views/host_home.dart';
import 'package:service_app/views/conversation_screen.dart';

class BookListingScreen extends StatefulWidget {
  final PostingModel? posting;
  final String? hostID;

  const BookListingScreen({super.key, this.posting, this.hostID});

  @override
  State<BookListingScreen> createState() => _BookListingScreenState();
}

class _BookListingScreenState extends State<BookListingScreen> {
  PostingModel? posting;
  List<DateTime> bookedDates = [];
  List<DateTime> selectedDates = [];
  List<CalenderUi> calendarWidgets = [];
  double bookingPrice = 0.0;
  String paymentResult = "";
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    posting = widget.posting;
    _loadBookedDates();
  }




  void _buildCalendarWidgets() {
    calendarWidgets = List.generate(12, (index) => CalenderUi(
      monthIndex: index,
      bookedDates: bookedDates,
      selectDate: _selectDate,
      onBookedDateTap: _onBookedDateTap,
      getSelectedDates: _getSelectedDates,
    ));
    setState(() {});
  }

  Future<void> _onBookedDateTap(DateTime date) async {
    try {
      // Ensure bookings are loaded
      await posting!.getAllBookingFromFirestore();

      // Find bookings that include this date
      final matching = posting!.bookings
              ?.where((b) => b.dates != null && b.dates!.any((d) => d.year == date.year && d.month == date.month && d.day == date.day))
              .toList() ?? [];

      if (matching.isEmpty) {
        Get.snackbar('No bookings', 'No booking found for ${date.day}/${date.month}/${date.year}');
        return;
      }

      // Show bottom sheet with booking(s) details
      showModalBottomSheet(
        context: context,
        builder: (context) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bookings on ${date.day}/${date.month}/${date.year}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ...matching.map((b) {
                  final user = b.user;
                  return Card(
                    child: ListTile(
                      leading: user?.displayImage != null ? CircleAvatar(backgroundImage: user!.displayImage) : CircleAvatar(child: Icon(Icons.person)),
                      title: Text(user?.getFullNameofUser() ?? 'Unknown'),
                      subtitle: Text('Nights: ${b.dates?.length ?? 0}\nAmount: \$${(b.price ?? 0).toStringAsFixed(2)}'),
                      isThreeLine: true,
                      trailing: ElevatedButton(
                        onPressed: () async {
                          // Open conversation with the booking user
                          try {
                            ConversationModel conv = ConversationModel();
                            // Try to find existing conversation
                            final snap = await FirebaseFirestore.instance.collection('conversations')
                                .where('userIDs', arrayContains: AppConstants.currentUser.id)
                                .get();
                            bool exists = false;
                            for (var doc in snap.docs) {
                              List<String> ids = List<String>.from(doc['userIDs'] ?? []);
                              if (ids.contains(user?.id)) {
                                await conv.getConversationInfoFromFirestore(doc);
                                exists = true;
                                break;
                              }
                            }
                            if (!exists) {
                              // create
                              ContactModel other = ContactModel(id: user?.id);
                              await other.getContactInfoFromFirestore();
                              await conv.addConversationToFirestore(other);
                            }

                            // Close bottom sheet then open chat
                            Navigator.of(context).pop();
                            Get.to(ConversationScreen(conversation: conv));
                          } catch (e) {
                            Get.snackbar('Error', 'Failed to open chat: ${e.toString()}');
                          }
                        },
                        child: Text('Chat'),
                      ),
                    ),
                  );
                }).toList(),
                const SizedBox(height: 8),
              ],
            ),
          );
        }
      );
    } catch (e) {
      Get.snackbar('Error', 'Failed to load booking info: ${e.toString()}');
    }
  }

  List<DateTime> _getSelectedDates() => selectedDates;

  void _selectDate(DateTime date) {
    setState(() {
      if (selectedDates.any((d) => _isSameDate(d, date))) {
        selectedDates.removeWhere((d) => _isSameDate(d, date));
      } else {
        selectedDates.add(date);
      }
      selectedDates.sort();
    });
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _loadBookedDates() async {
    setState(() => isLoading = true);
    try {
      await posting!.getAllBookingFromFirestore();
      bookedDates = posting!.getAllBookedDates();
      _buildCalendarWidgets();
    } catch (e) {
      Get.snackbar("Error", "Failed to load booked dates: ${e.toString()}");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _makeBooking() async {
    if (selectedDates.isEmpty) {
      Get.snackbar("Error", "Please select at least one date");
      return;
    }
    
    setState(() => isLoading = true);
    try {
      // If hostID is missing, proceed with an empty string so booking can still be created
      final hostId = widget.hostID ?? '';
      await posting!.makeNewBooking(selectedDates, context, hostId);
      
      // Generate a unique order ID
      final orderID = 'ORD${DateTime.now().millisecondsSinceEpoch}';
      
      // Navigate back first
      Get.back();
      
      // Show success message with Order ID
      Get.snackbar(
        "Success",
        "Booking created successfully!\nOrder ID: $orderID",
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      
      // Create or retrieve conversation with the host (non-blocking)
      if (hostId.isNotEmpty) {
        Future.microtask(() async {
          try {
            await _sendOrderMessageToHost(hostId, orderID);
          } catch (e) {
            debugPrint("❌ Failed to send order message: $e");
          }
        });
      }
      
    } catch (e) {
      Get.snackbar("Booking Error", e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _sendOrderMessageToHost(String hostId, String orderID) async {
    try {
      debugPrint("📨 Starting to send order message to host: $hostId");
      
      ConversationModel conversation = ConversationModel();
      
      // Try to find existing conversation
      final conversationSnapshot = await FirebaseFirestore.instance
          .collection("conversations")
          .where("userIDs", arrayContains: AppConstants.currentUser.id)
          .get();
      
      bool conversationExists = false;
      for (var doc in conversationSnapshot.docs) {
        List<String> userIDs = List<String>.from(doc["userIDs"] ?? []);
        if (userIDs.contains(hostId)) {
          await conversation.getConversationInfoFromFirestore(doc);
          conversationExists = true;
          debugPrint("✅ Found existing conversation: ${conversation.id}");
          break;
        }
      }
      
      // If not exists, create new conversation
      if (!conversationExists) {
        debugPrint("📝 Creating new conversation with host...");
        ContactModel hostContact = ContactModel(id: hostId);
        await hostContact.getContactInfoFromFirestore();
        await conversation.addConversationToFirestore(hostContact);
        debugPrint("✅ New conversation created with ID: ${conversation.id}");
      }
      
      // Ensure conversation has valid ID before sending message
      if (conversation.id == null || conversation.id!.isEmpty) {
        throw Exception("Conversation ID is null or empty after creation");
      }
      
      // Prepare order message
      final orderMessage = '''✅ Successfully placed your order! 🎉
We'll notify you once your order has been shipped.
Your Order ID is $orderID
Use it to track your order status.
Service: ${posting?.name ?? 'Unknown'}
Dates: ${selectedDates.length} night(s)
Total Amount: \$${bookingPrice.toStringAsFixed(2)}''';
      
      // Send the message
      debugPrint("📤 Sending order message to conversation ${conversation.id}...");
      await conversation.addMessageToFirestore(orderMessage);
      debugPrint("✅ Order message sent successfully!");
      
      // Wait for Firestore to fully process the message before opening chat
      await Future.delayed(Duration(milliseconds: 800));
      
      // Refresh conversation from Firestore to ensure we get the latest message
      try {
        final freshDoc = await FirebaseFirestore.instance
            .collection("conversations")
            .doc(conversation.id)
            .get();
        if (freshDoc.exists) {
          await conversation.getConversationInfoFromFirestore(freshDoc);
          debugPrint("🔄 Conversation refreshed with ID: ${conversation.id}");
        }
      } catch (e) {
        debugPrint("⚠️ Could not refresh conversation: $e");
      }
      
      // Open conversation screen with fresh data
      if (Get.context != null) {
        debugPrint("🔄 Opening ConversationScreen with conversation: ${conversation.id}");
        Get.to(ConversationScreen(conversation: conversation));
      }
      
    } catch (e) {
      debugPrint("❌ Error in _sendOrderMessageToHost: $e");
      // Still try to open chat even if message send failed
      if (Get.context != null) {
        ConversationModel fallbackConversation = ConversationModel();
        fallbackConversation.id = ""; // Will cause stream to load
        fallbackConversation.otherContact = ContactModel(id: hostId);
        Get.to(ConversationScreen(conversation: fallbackConversation));
      }
    }
  }

  void calculateAmountForOverallStay() {
    if (selectedDates.isEmpty) return;
    setState(() {
      bookingPrice = selectedDates.length * (posting?.price ?? 0.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
             colors: [Color(0xFF4A6CF7), Color(0xFF82C3FF)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        title: Text(
          "Order ${posting?.name ?? ''}",
          style: const TextStyle(color: Colors.white, fontSize: 26),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(25, 25, 25, 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Text("Sun"), Text("Mon"), Text("Tue"),
                      Text("Wed"), Text("Thu"), Text("Fri"), Text("Sat"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 2,
                    child: calendarWidgets.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : PageView.builder(
                            itemCount: calendarWidgets.length,
                            itemBuilder: (context, index) => calendarWidgets[index],
                          ),
                  ),
                  if (bookingPrice == 0.0)
                    MaterialButton(
                      onPressed: calculateAmountForOverallStay,
                      minWidth: double.infinity,
                      height: MediaQuery.of(context).size.height / 14,
                      color: Colors.green,
                      child: const Text(
                        "Calculate Total Price",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (paymentResult.isNotEmpty)
                    MaterialButton(
                      onPressed: () {
                        Get.to(HostHomeScreen());
                        setState(() => paymentResult = "");
                      },
                      minWidth: double.infinity,
                      height: MediaQuery.of(context).size.height / 14,
                      color: Colors.green,
                      child: const Text(
                        "Proceed",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  if (bookingPrice > 0.0 && paymentResult.isEmpty)
                    Platform.isIOS
                        ? ApplePayButton(
                            paymentConfiguration:
                                PaymentConfiguration.fromJsonString(defaultApplePay),
                            paymentItems: [
                              PaymentItem(
                                amount: bookingPrice.toStringAsFixed(2),
                                label: "Booking Amount",
                                status: PaymentItemStatus.final_price,
                              ),
                            ],
                            style: ApplePayButtonStyle.black,
                            width: double.infinity,
                            height: 50,
                            type: ApplePayButtonType.buy,
                            margin: const EdgeInsets.only(top: 15),
                            onPaymentResult: (result) {
                              setState(() => paymentResult = result.toString());
                              _makeBooking();
                            },
                            loadingIndicator: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : GooglePayButton(
                            paymentConfiguration:
                                PaymentConfiguration.fromJsonString(defaultGooglePay),
                            paymentItems: [
                              PaymentItem(
                                label: "Total",
                                amount: bookingPrice.toStringAsFixed(2),
                                status: PaymentItemStatus.final_price,
                              ),
                            ],
                            type: GooglePayButtonType.pay,
                            margin: const EdgeInsets.only(top: 15),
                            onPaymentResult: (result) {
                              setState(() => paymentResult = result.toString());
                              _makeBooking();
                            },
                            loadingIndicator: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                ],
              ),
            ),
    );
  }
}