import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_request_screen.dart';
import 'notification.dart';
import 'message.dart';
import 'dart:developer';
import 'dart:async';

class GuestRequestScreen extends StatefulWidget {
  const GuestRequestScreen({super.key});
  @override
  GuestRequestScreenState createState() => GuestRequestScreenState();
}

class GuestRequestScreenState extends State<GuestRequestScreen>
    with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? qrController;
  bool isScanning = false; // Prevent multiple scans
  String tableId = ""; // This will store the scanned table ID
  String userName = "Guest";
  List<bool> selectedItems = List.generate(5, (index) => false);
  List<Map<String, dynamic>> requestHistory = [];
  Timer? _exitTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTableId();
    _fetchRequestHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Retrieve the tableId from the arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        tableId = args['tableId'];
        userName = args['userName'];
      });
      _saveTableId(args['tableId'], args['userName']);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Start a timer for 2 minutes
      _exitTimer = Timer(const Duration(minutes: 2), () {
        _exitRequest();
      });
    } else if (state == AppLifecycleState.resumed) {
      // Cancel the timer if the user comes back
      _exitTimer?.cancel();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    qrController?.dispose();
    _exitTimer?.cancel();
    super.dispose();
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
    await prefs.setString('userName', name);
  }

  Future<void> _fetchRequestHistory() async {
    if (tableId.isNotEmpty) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('guestRequests')
          .where('tableId', isEqualTo: tableId)
          .orderBy('timestamp', descending: true)
          .get();

      setState(() {
        requestHistory = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    }
  }

  // Placeholder list of request types (replace "Lorem Ipsum Request" with actual request types)
  List<String> requestTypes = [
    "Frequently Asked Questions",
    "Housekeeping Request",
    "Assistance Request",
    "Checkout Request",
    "Summon a Staff",
  ];

  final Map<String, String> requestInformation = {
    'Frequently Asked Questions':
        'Request for information on common questions and answers',
    'Housekeeping Request':
        'Request for cottage cleaning or other housekeeping services',
    'Assistance Request':
        'Ask for help or support from the staff for various needs.',
    "Checkout Request":
        "Notify the staff that you will be checking out and require assistance with the process.",
    "Summon a Staff":
        "Request a staff member to come to your location for immediate assistance.",
    // Add more request types and their information here
  };

  // Function to get information based on request type
  String getRequestInformation(String requestType) {
    return requestInformation[requestType] ?? 'No information available';
  }

  Future<void> _submitRequest() async {
    // Collect the selected request types
    List<String> selectedRequests = [];

    if (tableId.isEmpty) {
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

    try {
      for (var requestType in selectedRequests) {
        String docName =
            '$tableId-${DateTime.now().millisecondsSinceEpoch}-$requestType';

        await FirebaseFirestore.instance
            .collection('guestRequests')
            .doc(docName)
            .set({
          'tableId': tableId,
          'requestType': requestType,
          'status': 'pending', // Set status to 'pending'
          'timestamp': Timestamp.now(),
          'userName': userName,
        });

        // create a new collection of users for analytics
        CollectionReference analyticsRef =
            FirebaseFirestore.instance.collection('analytics');
        DocumentReference analyticsDoc =
            analyticsRef.doc("$tableId + requestCount");

        await analyticsDoc.set({
          'tableId': tableId,
          'requestCount': FieldValue.increment(1),
        }, SetOptions(merge: true));

        // notify the admin
        await FirebaseFirestore.instance.collection('adminNotifications').add({
          'type': 'newRequest',
          'message':
              'New request "$requestType" from user "$userName" at table "$tableId"',
          'timestamp': FieldValue.serverTimestamp(),
          'viewed': false,
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
      // Update the status and userName in the activeTables collection
      await FirebaseFirestore.instance
          .collection('activeTables')
          .doc(tableId)
          .update({
        'status': 'inactive',
        'userNames': FieldValue.arrayRemove(
            [userName]), // Remove the userName from the array
      });

      // Debug: Verify the update
      DocumentSnapshot updatedDoc = await FirebaseFirestore.instance
          .collection('activeTables')
          .doc(tableId)
          .get();
      log("Updated document: ${updatedDoc.data()}"); // Debug: Print the updated document

      // Notify the user of successful update
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thank you for using the service")),
      );

      // Optionally, reset the state
      setState(() {
        tableId = "";
        selectedItems = List.generate(5, (index) => false);
      });

      // Navigate back to the QR screen
      // ignore: use_build_context_synchronously
      Navigator.popAndPushNamed(context, '/qrCode');
    } catch (e) {
      // Show error message if update fails
      log("Error: $e"); // Debug: Print the error
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update the table status: $e")),
      );
    }
  }

  Future<void> _showMessagesScreen() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MessagesScreen(tableId: tableId, userName: userName),
      ),
    );
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
        actions: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .where('tableId', isEqualTo: tableId)
                .where('userName', isEqualTo: userName)
                .where('viewed',
                    isEqualTo: false) // Only show unviewed notifications
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.notifications),
                      Positioned(
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 12,
                            minHeight: 12,
                          ),
                          child: const Text(
                            '!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onPressed: () async {
                    if (tableId.isNotEmpty) {
                      // Update the status of the notifications to 'viewed'
                      var batch = FirebaseFirestore.instance.batch();
                      for (var doc in snapshot.data!.docs) {
                        batch.update(doc.reference, {'viewed': true});
                      }
                      await batch.commit();

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(
                              tableId: tableId, userName: userName),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No table ID available")),
                      );
                    }
                  },
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    if (tableId.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NotificationScreen(
                              tableId: tableId, userName: userName),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No table ID available")),
                      );
                    }
                  },
                );
              }
            },
          ),
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
                    child: Row(
                      children: [
                        Container(
                          height:
                              60, // Set this to match the height of the white box
                          alignment: Alignment.center,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(30),
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            onTap: () {
                              // Handle information button press
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text('Information'),
                                    content: Text(getRequestInformation(
                                        requestTypes[index])),
                                    actions: <Widget>[
                                      TextButton(
                                        child: Text('Close'),
                                        onPressed: () {
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            child: Icon(
                              Icons.info,
                              size: 50, // Adjust the size as needed
                              color: selectedItems[index]
                                  ? const Color(0xFF316175)
                                  : const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                        const SizedBox(
                            width:
                                10), // Add some space between the button and the container
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8.0),
                            decoration: BoxDecoration(
                              color: selectedItems[index]
                                  ? const Color(0xFF316175)
                                  : Colors.white,
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
                                  const SizedBox(
                                      width:
                                          10), // Add some space between the button and the text
                                  Expanded(
                                    child: Text(
                                      requestTypes[
                                          index], // Display request type name
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: selectedItems[index]
                                            ? Colors.white
                                            : const Color.fromARGB(
                                                255, 49, 97, 117),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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
              child: const Text("Submit Request",
                  style: TextStyle(fontSize: 18, color: Colors.white)),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CustomRequestScreen(
                      tableId: tableId,
                      userName: userName,
                    ),
                  ),
                );
              },
              child:
                  const Text("Custom Request", style: TextStyle(fontSize: 18)),
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
