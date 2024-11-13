import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/screens/guest_request/guest_request_screen.dart';

class CustomRequestScreen extends StatefulWidget {
  final String tableId;
  final String userName;
  const CustomRequestScreen({super.key, required this.tableId, required this.userName});

  @override
  _CustomRequestScreenState createState() => _CustomRequestScreenState();
}

class _CustomRequestScreenState extends State<CustomRequestScreen> {
  final TextEditingController customRequestController = TextEditingController();

  Future<void> _submitCustomRequest() async {
    String customRequestDetails = customRequestController.text.trim();

    if (customRequestDetails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a custom request")),
      );
      return;
    }

    try {
      // Generate a custom document ID using the table ID and timestamp
      String docName = '${widget.tableId}-${DateTime.now().millisecondsSinceEpoch}';

      // Save the custom request to Firestore
      await FirebaseFirestore.instance.collection('guestRequests').doc(docName).set({
        'tableId': widget.tableId,
        'requestType': 'Custom Request',
        'customRequest': customRequestDetails,
        'status': 'active',
        'timestamp': Timestamp.now(),
        'userName': widget.userName,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Custom request submitted successfully")),
      );

      // Clear the text field after submission
      customRequestController.clear();

      // Navigate to the GuestRequestScreen after submission
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const GuestRequestScreen()),
        (Route<dynamic> route) => false
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4CB9D),
      appBar: AppBar(
        title: const Text(
          "TableServe",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE4CB9D),
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 4,
              color: Colors.teal.shade800,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "How can we help you?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF316175),
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Colors.black26,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Describe your service request in detail.",
              style: TextStyle(fontSize: 16, color: Color(0xFF316175)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Text Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: TextField(
                controller: customRequestController,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: "Type here...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Request Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                backgroundColor: const Color(0xFF316175),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: _submitCustomRequest,
              child: const Text("Submit Request", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}