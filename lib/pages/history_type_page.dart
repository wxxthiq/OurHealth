import 'package:flutter/material.dart';
import 'package:ourhealth/Pharmacy/prescription_requests_page.dart';
import 'package:ourhealth/doctor/appointment_requests_page.dart';
import 'package:ourhealth/pages/medical_history_list_page.dart';
import 'package:ourhealth/pages/prescription_history_list_page.dart';
import 'package:ourhealth/pages/prescription_status_page.dart';

import 'appointment_status_page.dart';

class historyTypePage extends StatelessWidget {
  final String email;

  historyTypePage({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('History Type'),
      ),
      body: Center(
        child: GridView.count(
          crossAxisCount: 2, // Number of columns in the grid
          padding: EdgeInsets.all(16.0),
          crossAxisSpacing: 24.0,
          mainAxisSpacing: 24.0,
          children: [
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MedicalHistoryListPage(email: email),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_pin_outlined,
                        size: 48,
                        color: Color(0xFF5D3FD3),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'History with Doctor / Specialist',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => prescriptionHistoryListPage(email: email),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.medication_rounded,
                        size: 48,
                        color: Color(0xFF5D3FD3),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'History with Pharmacies / Drugstores',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
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
