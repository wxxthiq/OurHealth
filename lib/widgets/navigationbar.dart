import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:ourhealth/doctor/doctor_chat_page.dart';
import 'package:ourhealth/pages/appointment_status_page.dart';
import 'package:ourhealth/pages/profile_page.dart';
import 'package:ourhealth/pages/requests_type_page.dart';
import '../pages/home_page.dart';
import '../pages/patient_chats_page.dart';


class navBar extends StatefulWidget {
  final String email;

  const navBar({Key? key, required this.email}) : super(key: key);

  @override
  State<navBar> createState() => _navBarState();
}

class _navBarState extends State<navBar> with SingleTickerProviderStateMixin {
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
          MaterialPageRoute(builder: (context) => HomePage()),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => patientChatsPage(patientEmail: widget.email)),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => RequestTypePage(email: widget.email)),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),
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
          icon: Icon(Icons.chat_rounded),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.schedule_send_rounded),
          label: 'Requests',
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
