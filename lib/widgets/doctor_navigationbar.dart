import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/pages/profile_page.dart';

import '../doctor/doctor_home_page.dart';
import '../doctor/doctor_profile_page.dart';
import '../pages/filter_page.dart';
import '../pages/home_page.dart';
import '../pages/login_page.dart';
import '../pages/register_page.dart';

class doctorNavBar extends StatefulWidget {
  final String email;

  const doctorNavBar({Key? key, required this.email}) : super(key: key);

  @override
  State<doctorNavBar> createState() => _navBarState();
}

class _navBarState extends State<doctorNavBar> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Add your navigation logic here
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => doctorHomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => doctorProfilePage(email: widget.email)),
        );
        break;

    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        )


      ],
      currentIndex: _selectedIndex,
      unselectedItemColor: Colors.grey[600],
      selectedItemColor: Color(0xFF5D3FD3),
      onTap: _onItemTapped,
    );
  }
}
