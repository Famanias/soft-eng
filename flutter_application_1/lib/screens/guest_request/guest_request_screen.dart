import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class GuestRequestScreen extends StatefulWidget {
  const GuestRequestScreen({super.key});

  @override
  _GuestRequestScreenState createState() => _GuestRequestScreenState();
}

class _GuestRequestScreenState extends State<GuestRequestScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  String tableId = ""; // This will store the scanned table ID
  List<bool> selectedItems = List.generate(5, (index) => false);

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  // Placeholder list of request types (replace "Lorem Ipsum Request" with actual request types)
  List<String> requestTypes = [
    "Request Type 1",
    "Request Type 2",
    "Request Type 3",
    "Request Type 4",
    "Request Type 5",
  ];

  // Function to scan QR code
  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      qrController = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        tableId = scanData.code ?? ""; // Set the table ID from QR code
      });
      controller.pauseCamera(); // Pause scanning after getting the first result
    });
  }

  Future<void> _submitRequest() async {
    // Collect the selected request types
    List<String> selectedRequests = [];
    for (int i = 0; i < selectedItems.length; i++) {
      if (selectedItems[i]) {
        selectedRequests.add(requestTypes[i]);
      }
    }

    // If no requests are selected, show an error
    if (selectedRequests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select at least one request")),
      );
      return;
    }

    // Prepare Firestore data for each request
    try {
      for (var requestType in selectedRequests) {
        await FirebaseFirestore.instance.collection('guestRequests').add({
          'tableId': 'table_1', // Replace with dynamic table ID if available
          'requestType': requestType,
          'status': 'active',
          'timestamp': Timestamp.now(),
        });
      }

      // Notify the user of successful submission
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Requests submitted successfully")),
      );

      // Reset selected items
      setState(() {
        selectedItems = List.generate(5, (index) => false);
      });
    } catch (e) {
      // Show error message if submission fails
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
              "Guest Request",
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
            ),
            const SizedBox(height: 5),
            const Text(
              "Common requests of guests, can select multiple.",
              style: TextStyle(fontSize: 16, color: Color(0xFF316175)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            // Multi-select Options List
            Expanded(
              child: ListView.builder(
                itemCount: selectedItems.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedItems[index] = !selectedItems[index];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: selectedItems[index] ? const Color(0xFF316175) : Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: selectedItems[index] ? Colors.white : const Color(0xFF316175)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                requestTypes[index], // Display request type name
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selectedItems[index] ? Colors.white : Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
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
              onPressed: _submitRequest, // Call Firestore submission
              child: const Text("Submit Request", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // Custom Request Button
            ElevatedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF316175),
                padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0),
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/customRequest');
              },
              child: const Text("Custom Request", style: TextStyle(fontSize: 18)),
            ),

            ElevatedButton(
              onPressed: () {
                String username = 'dave';
                String password = '123';
                
                if (username == 'dave' && password == '123') {
                  Navigator.pushNamed(context, '/adminPanel');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid credentials')),
                  );
                }
              },
              child: const Text("Go to Admin Panel"),
            )
          ],
        ),
      ),
    );
  }
}
