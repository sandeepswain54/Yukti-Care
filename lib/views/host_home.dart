import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:service_app/Location/map_page.dart';
import 'package:service_app/UI%20SCREEN/front_screen.dart';
import 'package:service_app/Voice_AI/AI_Voice.dart';
import 'package:service_app/Voice_AI/voice_ai_chat.dart';
import 'package:service_app/model/Screens_home/acccount_screen.dart';
import 'package:service_app/model/Screens_home/explore_screen.dart';
import 'package:service_app/model/Screens_home/inbox.dart';
import 'package:service_app/model/Screens_home/post.dart';
import 'package:service_app/model/Screens_home/saved.dart';
import 'package:service_app/views/Host_Screens/booking.dart';

import 'package:service_app/views/Host_Screens/my_poasting_screen.dart';
import 'package:service_app/views/onboarding_screen.dart';

class HostHomeScreen extends StatefulWidget {

  int? Index;

  HostHomeScreen({super.key, this.Index,});

  @override
  State<HostHomeScreen> createState() => _HostHomeScreenState();
}

class _HostHomeScreenState extends State<HostHomeScreen> {
  int _selectedIndex = 0;

  final List<String> _screenTitles = [
    'Home',
    'Post',
    'Booking',
    'Talk',
    'Tracking',
    'Profile',
  ];

  final List<Widget> _screens = [
     Booking(),
    const MyPoastingScreen(),
    const Post(),
    VoiceAIChatPage(),
     MapScreen(),
    const AccountScreen(),
  ];

  BottomNavigationBarItem _customNavigationBarItem(
      int index, IconData iconData, String title) {
    return BottomNavigationBarItem(
      icon: Icon(
        iconData,
        color: _selectedIndex == index ? Colors.blue : Colors.black,
      ),
      label: title,
    );
  }



@override
  void initState() {
    // TODO: implement initState
    super.initState();

    _selectedIndex = widget.Index ?? 3;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        items: [
          _customNavigationBarItem(0, Icons.home, _screenTitles[0]),
          _customNavigationBarItem(1, Icons.post_add_outlined, _screenTitles[1]),
          _customNavigationBarItem(2, Icons.chat_bubble, _screenTitles[2]),
          _customNavigationBarItem(3, Icons.psychology, _screenTitles[3]),
          _customNavigationBarItem(4, Icons.gps_fixed, _screenTitles[4]),
          _customNavigationBarItem(5, Icons.person, _screenTitles[5]),
        ],
      ),
    );
  }
}