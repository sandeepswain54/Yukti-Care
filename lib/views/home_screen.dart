import 'package:flutter/material.dart';
import 'package:service_app/Apps/app.dart';

import 'package:service_app/CAMERA_SCAN/QRInvoiceSystem.dart';
import 'package:service_app/Chat_Bot/chat_provider.dart';
import 'package:service_app/Chat_Bot/chat_screen.dart';
import 'package:service_app/Distributor/InvoiceScreen.dart';
import 'package:service_app/Distributor/Product_Catlog.dart';
import 'package:service_app/Distributor/distributor_screen.dart';
import 'package:service_app/Distributor/online_Order.dart';


import 'package:service_app/Firebase_Distributor/product_display_screen.dart';
import 'package:service_app/OpenStreet/openstreet.dart';
import 'package:service_app/PharmacyScreen/pharmacyscreen.dart';


import 'package:service_app/UserScreen_Product/catalog_User.dart';
import 'package:service_app/model/Screens_home/acccount_screen.dart';
import 'package:service_app/model/Screens_home/explore_screen.dart';
import 'package:service_app/model/Screens_home/inbox.dart';
import 'package:service_app/model/Screens_home/post.dart';
import 'package:service_app/model/Screens_home/saved.dart';
import 'package:service_app/views/Host_Screens/booking.dart';
// Import your settings file

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selelectedIndex = 0;
  bool _showUnreadBadge = true;

  final List<String> screenTitles = [
    'Home',
    'Saved',
    'Inbox',
    'Chat',
    'Profile',
    'Find Safest Travel Path',
    "new"
  ];

  final List<Widget> screens = [
    
   DashboardScreen(),
    InvoiceScreen(),
    OnlineOrdersScreen(),
    ProductCatalogueScreen(),
    AccountScreen(),
   QRInvoiceSystem(),
   Productuser() // This should be imported from your settings.dart file
  ];

  BottomNavigationBarItem customNavigationBarItem(
      int index, IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(iconData, color: Colors.black),
      activeIcon: Icon(iconData, color: Colors.blue),
      label: title,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: IndexedStack(
        index: selelectedIndex,
        children: screens,
      ),
      floatingActionButton: selelectedIndex == 0
          ? FloatingActionButton(
              onPressed: () {
                setState(() => _showUnreadBadge = false);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatScreen(),
                    fullscreenDialog: true,
                  ),
                );
              },
              backgroundColor: Colors.blue[600],
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.chat_bubble, color: Colors.white, size: 30),
                  if (_showUnreadBadge)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) {
          setState(() {
            selelectedIndex = i;
          });
        },
        currentIndex: selelectedIndex,
        type: BottomNavigationBarType.fixed,
        items: [
          customNavigationBarItem(0, Icons.home, screenTitles[0]),
          customNavigationBarItem(1, Icons.save_rounded, screenTitles[1]),
          customNavigationBarItem(2, Icons.calendar_month, screenTitles[2]),
          customNavigationBarItem(3, Icons.message, screenTitles[3]),
          customNavigationBarItem(4, Icons.person, screenTitles[4]),
          customNavigationBarItem(5, Icons.map, screenTitles[5]),
          customNavigationBarItem(6, Icons.production_quantity_limits_outlined, screenTitles[6]),
        ],
      ),
    );
  }
}