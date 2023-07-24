import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrescriptionStatusPage extends StatefulWidget {
  final String email;

  const PrescriptionStatusPage({Key? key, required this.email}) : super(key: key);

  @override
  _AppointmentStatusPageState createState() => _AppointmentStatusPageState();
}

class _AppointmentStatusPageState extends State<PrescriptionStatusPage> {


  Future<void> _cancelAppointment(DocumentReference appointmentRef) async {
    await appointmentRef.update({
      'cancelReason': 'User requested cancellation',
      'status': 'cancelled',
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: const Color(0xFF5D3FD3),
        title: Text('Prescription/Medication Request Status'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('prescriptionRequests')
                    .where('patientEmail', isEqualTo: widget.email)
                    .where('cancelReason', isEqualTo: "")
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final appointments = snapshot.data!.docs;
                    if (appointments.isEmpty) {
                      return Center(
                        child: Text('No appointment status to view'),
                      );
                    }
                    return Column(
                      children: appointments.map((appointment) {
                        final appointmentData = appointment.data();
                        final appointmentDateTime =
                        appointmentData?['requestDateTime'] as String?;

                        final facilityName =
                        appointmentData?['facilityName'] as String?;
                        final reason = appointmentData?['reason'] as String?;
                        final isCancelled =  appointmentData?['status'] == 'cancelled';
                        final prescriptionUrl = appointmentData?['prescriptionUrl'] as String;
                        final notes = appointmentData?['notes'] as String;
print("decline pic is"+appointmentData?['declinePic']);
                        if (appointmentDateTime != null && facilityName != null) {
                          final dateTimeParts =
                          appointmentDateTime.split(' ');
                          final date = dateTimeParts[0];
                          final time = dateTimeParts[1];
                          return AppointmentCard(
                            appointmentRef: appointment.reference,
                            date: date,
                            time: time,
                            healthcareFacility: facilityName,
                            declinePicUrl: appointmentData?['declinePic'],
                            declineReason: appointmentData?['declineReason'] ,
                            status: appointmentData?['status'] as String,
                            notes: notes,
                            prescriptionUrl: prescriptionUrl,
                            isCancelled: isCancelled,
                            onCancel: () async {
                              await _cancelAppointment(appointment.reference);
                              setState(() {}); // Refresh the page
                            },
                          );
                        } else {
                          return SizedBox(); // Skip invalid appointments
                        }
                      }).toList(),
                    );
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else {
                    return CircularProgressIndicator();
                  }
                },
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class AppointmentCard extends StatelessWidget {
  final DocumentReference appointmentRef;
  final String date;
  final String time;
  final String healthcareFacility;
  final String declineReason;
  final String declinePicUrl;
  final String status;
  final String notes;
  final String prescriptionUrl;
  final bool isCancelled;
  final VoidCallback onCancel;


  const AppointmentCard({
    required this.appointmentRef,
    required this.date,
    required this.time,
    required this.healthcareFacility,
    required this.declineReason,
    required this.declinePicUrl,
    required this.status,
    required this.notes,
   required this.prescriptionUrl,
    required this.isCancelled,
    required this.onCancel,

    Key? key,
  }) : super(key: key);

  Color getStatusColor() {
    if (status == 'pending') {
      return Colors.grey;
    } else if (status == 'booked') {
      return Colors.green;
    } else {
      return Colors.red;
    }
  }

  String getStatusText() {
    if (status == 'pending') {
      return 'Pending';
    } else if (status == 'booked') {
      return 'Booked';
    } else {
      return 'Declined';
    }
  }

  TextStyle getStatusTextStyle() {
    if (status == 'pending') {
      return TextStyle(fontSize: 18, color: Colors.grey);
    } else if (status == 'booked') {
      return TextStyle(fontSize: 18,color: Colors.green);
    } else {
      return TextStyle(fontSize: 18,color: Colors.red);
    }
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Appointment Booked'),
          content: Text('Your prescription refill request has been accepted and can be tracked in the prescription history page.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _cancelAppointment(DocumentReference appointmentRef) async {
    await appointmentRef.update({
      'cancelReason': 'User requested cancellation',
      'status': 'cancelled',
    });
  }

  void _showDeclineDialog(BuildContext context, String declineReason, String declinePic) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Prescription Request Declined', style: TextStyle(
            color: Color(0xFF5D3FD3),
          )
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(declineReason),
              SizedBox(height: 30),
              if(declinePic != null && declinePic.isNotEmpty)
                Image.network(declinePic),
            ],
          ),
          actions: [
            Align(
              alignment: Alignment.center, // Center align the OK button
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close the dialog
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Color(0xFF5D3FD3)),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (status == 'booked') {
          _showBookingDialog(context);
        }
        else if( status == 'declined'){
          _cancelAppointment(appointmentRef);
          print("declinepicurl is $declinePicUrl");
          _showDeclineDialog(context, declineReason, declinePicUrl);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: EdgeInsets.all(1),
        padding: EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.medication, size: 40, color: Color(0xFF5D3FD3)),
                SizedBox(width: 8),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Pharmacy / Dispensor',
              style: TextStyle(fontSize: 18, color: Color(0xFF5D3FD3)),
            ),
            Text(
              healthcareFacility,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Prescription image',
              style: TextStyle(fontSize: 18, color: Color(0xFF5D3FD3)),
            ),

            SizedBox(height: 18),
            if (prescriptionUrl != "" && prescriptionUrl != " ")
              Image.network(prescriptionUrl),
            SizedBox(height: 16),
            Text(
              'Timestamp of request',
              style: TextStyle(fontSize: 18, color: Color(0xFF5D3FD3)),
            ),
            Text(
              date+" - $time",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 16),
            Text(
              'Notes',
              style: TextStyle(fontSize: 18, color: Color(0xFF5D3FD3)),
            ),
            Text(
              notes,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Status',
              style: TextStyle(fontSize: 18, color: Color(0xFF5D3FD3)),
            ),
            Text(
              getStatusText(),
              style: getStatusTextStyle(),
            ),
            if (status == 'pending')
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Color(0xFF5D3FD3)),
                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                  onPressed: onCancel,
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
