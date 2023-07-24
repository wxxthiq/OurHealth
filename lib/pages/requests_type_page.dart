import 'package:flutter/material.dart';
import 'package:ourhealth/Pharmacy/prescription_requests_page.dart';
import 'package:ourhealth/doctor/appointment_requests_page.dart';
import 'package:ourhealth/pages/prescription_status_page.dart';

import 'appointment_status_page.dart';

class RequestTypePage extends StatelessWidget {
  final String email;

  RequestTypePage({required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Request Type'),
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
                      builder: (context) => PrescriptionStatusPage(email: email),
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
                        Icons.medication,
                        size: 48,
                        color: Color(0xFF5D3FD3),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Prescription/Medication Requests',
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
                      builder: (context) => AppointmentStatusPage(email: email),
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
                        Icons.calendar_today,
                        size: 48,
                        color: Color(0xFF5D3FD3),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Appointment Requests',
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
