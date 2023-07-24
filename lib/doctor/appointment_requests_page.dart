import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'appointment_details_page.dart';

class AppointmentRequestsPage extends StatefulWidget {
  final String healthcareFacility;
  final String doctorEmail;

  AppointmentRequestsPage({required this.healthcareFacility, required this.doctorEmail});

  @override
  _AppointmentRequestsPageState createState() => _AppointmentRequestsPageState();
}

class _AppointmentRequestsPageState extends State<AppointmentRequestsPage> {
  late Stream<QuerySnapshot> _appointmentRequestsStream;

  @override
  void initState() {
    super.initState();
    _appointmentRequestsStream = FirebaseFirestore.instance
        .collection('appointmentRequests')
        .where('facilityName', isEqualTo: widget.healthcareFacility)
      .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF5D3FD3),
        title: Text('Appointment Requests'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _appointmentRequestsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('An error occurred'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text('No appointment requests found'),
            );
          }

          return ListView(
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              final data = document.data() as Map<String, dynamic>?;

              final reason = data?['reason'] as String? ?? 'Reason not provided';
              final appointmentDateTime = data?['appointmentDateTime'] as String? ?? 'Unknown';

              // Convert the appointmentDate to the desired format
              DateTime formattedDateTime;
              try {
                formattedDateTime = DateTime.parse(appointmentDateTime);
              } catch (error) {
                formattedDateTime = DateTime.now(); // Provide a default value, such as the current DateTime
              }
              final formattedDate =
                  '${formattedDateTime.day} ${_getMonthName(formattedDateTime.month)} ${formattedDateTime.year}';
              final formattedTime = _formatTime(formattedDateTime);

              return ListTile(
                title: Text(reason,
                  style: TextStyle(
                    color: Color(0xFF5D3FD3), // Change the color of the reason text
                    fontWeight: FontWeight.bold,
                  ),),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Text(),
                    Text('$formattedDate - $formattedTime',
                      style: TextStyle(
                        color: Colors.black, // Change the color of the date & time text
                      ),),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.arrow_forward),
                  onPressed: () {
                    // Navigate to the appointment details page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AppointmentDetailsPage(
                          appointmentData: data,
                          doctorEmail: widget.doctorEmail,
                        ),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  String _getMonthName(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return 'Unknown';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour < 12 ? 'AM' : 'PM';
    final formattedHour = hour % 12 == 0 ? '12' : (hour % 12).toString().padLeft(2, '0');
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }
}

