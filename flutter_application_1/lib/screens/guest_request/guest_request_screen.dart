import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification.dart';
import 'message.dart';
import 'dart:developer';

class GuestRequestScreen extends StatefulWidget {
  const GuestRequestScreen({super.key});

  @override
  _GuestRequestScreenState createState() => _GuestRequestScreenState();
}

class _GuestRequestScreenState extends State<GuestRequestScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  bool isScanning = false; // Prevent multiple scans
  String tableId = ""; // This will store the scanned table ID
  String userName = "Guest";
  List<bool> selectedItems = List.generate(5, (index) => false);
  List<Map<String, dynamic>> requestHistory = [];

  @override
  void initState() {
    super.initState();
    _loadTableId();
     _fetchRequestHistory();
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the tableId from the arguments
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        tableId = args['tableId'];
        userName = args['userName'];
      });
        _saveTableId(args['tableId'], args['userName']);
    }
  }

    Future<void> _loadTableId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tableId = prefs.getString('tableId') ?? "";
      userName = prefs.getString('userName') ?? "Guest";
    });
    _fetchRequestHistory();
  }

  Future<void> _saveTableId(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tableId', id);
     await prefs.setString('userName', userName);
  }

  Future<void> _fetchRequestHistory() async {
    if (tableId.isNotEmpty) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('guestRequests')
          .where('tableId', isEqualTo: tableId)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        requestHistory = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    }
  }

  @override
  void dispose() {
    qrController?.dispose();
    super.dispose();
  }

  // Placeholder list of request types (replace "Lorem Ipsum Request" with actual request types)
  List<String> requestTypes = [
    "Eat",
    "Sleep",
    "Play",
    "Rest",
    "Swim",
  ];


  Future<void> _submitRequest() async {
    // Collect the selected request types
    List<String> selectedRequests = [];

    if(tableId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No table ID available")),
      );
      return;
    }

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

    String docName = '$tableId-${DateTime.now().millisecondsSinceEpoch}';

    // Prepare Firestore data for each request
    try {
      for (var requestType in selectedRequests) {
        await FirebaseFirestore.instance.collection('guestRequests').doc(docName).set({
          'tableId': tableId,
          'requestType': requestType,
          'status': 'active',
          'timestamp': Timestamp.now(),
          'userName': userName,
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

 Future<void> _exitRequest() async {
  try {
    // Update the status of the request to 'inactive' in Firestore
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('guestRequests')
        .where('tableId', isEqualTo: tableId)
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in querySnapshot.docs) {
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(doc.id)
          .update({'status': 'inactive'});

      // Debug: Print the document ID being processed
      log("Processing document ID: ${doc.id}");

      // Delete all messages in the messages subcollection
      QuerySnapshot messagesSnapshot = await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(doc.id)
          .collection('messages')
          .get();

      // Debug: Print the number of messages found
      log("Found ${messagesSnapshot.docs.length} messages to delete");

      for (var messageDoc in messagesSnapshot.docs) {
        // Debug: Print the message document ID being deleted
        log("Deleting message ID: ${messageDoc.id}");

        await FirebaseFirestore.instance
            .collection('guestRequests')
            .doc(doc.id)
            .collection('messages')
            .doc(messageDoc.id)
            .delete();
      }
    }

    // Update the status and userName in the activeTables collection
    await FirebaseFirestore.instance
        .collection('activeTables')
        .doc(tableId)
        .update({
          'status': 'inactive',
          'userName': 'null', // Set the userName to 'null'
        });

    // Debug: Verify the update
    DocumentSnapshot updatedDoc = await FirebaseFirestore.instance
        .collection('activeTables')
        .doc(tableId)
        .get();
    print("Updated document: ${updatedDoc.data()}"); // Debug: Print the updated document

    // Notify the user of successful update
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Thank you for using the service")),
    );

    // Optionally, reset the state
    setState(() {
      tableId = "";
      selectedItems = List.generate(5, (index) => false);
    });

    // Navigate back to the QR screen
    Navigator.popAndPushNamed(context, '/qrCode');
  } catch (e) {
    // Show error message if update fails
    print("Error: $e"); // Debug: Print the error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to mark request as inactive: $e")),
    );
  }
}

  void _showRequestHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Request History"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              itemCount: requestHistory.length,
              itemBuilder: (context, index) {
                var request = requestHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      "Request: ${request['requestType'].join(', ')}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Status: ${request['status']}"),
                        Text("Time: ${request['timestamp'].toDate()}"),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _showMessagesScreen() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MessagesScreen(tableId: tableId, userName: userName),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4CB9D),
      appBar: AppBar(
        leading: IconButton(
        icon: const Icon(Icons.exit_to_app),
        onPressed: () async {
          bool? confirmExit = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Confirm Exit"),
                content: const Text("Are you sure you want to exit?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Exit"),
                  ),
                ],
              );
            },
          );
          if (confirmExit == true) {
            _exitRequest();
          }
        },
      ),
        title: const Text(
          "TableServe",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              if (tableId.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NotificationScreen(tableId: tableId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("No table ID available")),
                );
              }
            } 
          )
        ],
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
              "Select your request",
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
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMessagesScreen,
        child: const Icon(Icons.message),
      ),
      
    );
  }
}
