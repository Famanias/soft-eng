import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_request_screen.dart';
import 'notification.dart';
import 'message.dart';
import 'dart:developer';
import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'faq_screen.dart'; // Import the FAQ screen file

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

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _listenForNotifications();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message.data);
    });
    WidgetsBinding.instance.addObserver(this);
    _loadTableId();
    _fetchRequestHistory();
  }

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _listenForNotifications() {
    FirebaseFirestore.instance
        .collection('notifications')
        .where('userName', isEqualTo: userName)
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          var data = change.doc.data() as Map<String, dynamic>;
          _showLocalNotification(data);
        }
      }
    });
  }

  void _showLocalNotification(Map<String, dynamic> data) {
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 10,
        channelKey: 'high_importance_channel',
        title: data['type'] == 'newMessage'
            ? 'Message from Admin'
            : 'Request: ${data['requestType']}',
        body: data['type'] == 'newMessage'
            ? data['message']
            : 'Status: ${data['status']}',
        notificationLayout: NotificationLayout.Default,
        icon: 'resource://drawable/ic_launcher',
      ),
    );
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

  // Rearranged list of request types for better UX/UI flow
  List<String> requestTypes = [
    "Food and Beverage Request", // Immediate need: Food & drinks
    "Request a Staff", // Immediate need: Staff for assistance
    "Kitchenware Request", // Special request: Kitchen items
    "Cottage Cleaning Request", // Service request: Cleaning
    "Checkout Request", // End of stay: Checkout
  ];

  // Updated request information map
  final Map<String, String> requestInformation = {
    'Food and Beverage Request':
        'Request food and drinks to be delivered to your location.',
    'Request a Staff':
        'Request a staff member to come to your location for immediate assistance.',
    'Kitchenware Request':
        'Request additional kitchenware items, such as plates, glasses, utensils, or cooking equipment for your cottage or room.',
    'Cottage Cleaning Request': 'Request for a staff to clean your cottage.',
    'Checkout Request':
        "Notify the staff that you will be checking out and require assistance with the process.",
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

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 13),
                child: const CircularProgressIndicator(),
              ),
              const SizedBox(height: 20),
              const Text("Please wait a moment..."),
            ],
          ),
        );
      },
    );

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

        CollectionReference globalAnalyticsRef =
            FirebaseFirestore.instance.collection('globalAnalytics');
        DocumentReference globalAnalyticsDoc =
            globalAnalyticsRef.doc(requestType);

        await globalAnalyticsDoc.set({
          requestType: FieldValue.increment(1),
        }, SetOptions(merge: true));

        // notify the admin
        await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'newRequest',
          'message':
              'New request "$requestType" from user "$userName" at table "$tableId"',
          'timestamp': FieldValue.serverTimestamp(),
          'viewed': false,
          'userName': userName
        });
      }

      // Notify the user of successful submission
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Requests submitted successfully")),
      );

      // Reset selected items
      setState(() {
        selectedItems = List.generate(5, (index) => false);
      });
    } catch (e) {
      // Show error message if submission fails
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to submit request: $e")),
      );
    } finally {
      // Dismiss the loading dialog
      Navigator.of(context).pop();
    }
  }

  Future<void> _exitRequest() async {
    try {
      // Step 1: Update the activeTables collection
      DocumentReference tableRef =
          FirebaseFirestore.instance.collection('activeTables').doc(tableId);

      // Remove the userName from the array
      await tableRef.update({
        'userNames': FieldValue.arrayRemove([userName]),
      });

      // Fetch the updated document to check the userNames array
      DocumentSnapshot updatedDoc = await tableRef.get();
      List<dynamic> userNames = updatedDoc['userNames'] ?? [];

      // If the userNames array is empty, set the status to inactive
      if (userNames.isEmpty) {
        await tableRef.update({
          'status': 'inactive',
        });
      }

      log("Updated document: ${updatedDoc.data()}"); // Debug: Print the updated document

      // Step 2: Delete notifications for the user
      var notificationSnapshots = await FirebaseFirestore.instance
          .collection('notifications')
          .where('tableId', isEqualTo: tableId)
          .where('userName', isEqualTo: userName)
          .get();

      if (notificationSnapshots.docs.isNotEmpty) {
        log("Deleting ${notificationSnapshots.docs.length} notifications for userName: $userName");
        for (var doc in notificationSnapshots.docs) {
          await doc.reference.delete();
          log("Deleted notification: ${doc.id}");
        }
      } else {
        log("No notifications found for userName: $userName");
      }

      // Step 3: Delete messages in the messages collection
      var messageSnapshots = await FirebaseFirestore.instance
          .collection('messages')
          .where('tableId', isEqualTo: tableId)
          .where('userName', isEqualTo: userName)
          .get();

      if (messageSnapshots.docs.isNotEmpty) {
        log("Deleting ${messageSnapshots.docs.length} messages for userName: $userName");
        for (var doc in messageSnapshots.docs) {
          await doc.reference.delete();
          log("Deleted message: ${doc.id}");
        }
      } else {
        log("No messages found for userName: $userName");
      }

      // Step 4: Notify the user of success
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Thank you for using the service")),
      );

      // Step 5: Reset state and navigate
      setState(() {
        tableId = "";
        selectedItems = List.generate(5, (index) => false);
      });

      // ignore: use_build_context_synchronously
      Navigator.popAndPushNamed(context, '/qrCode');
    } catch (e) {
      // Handle errors and log
      log("Error: $e");
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("TableServe",
                style: TextStyle(
                  color: Color(0xffffffff),
                  fontFamily: "RubikOne",
                )),
            Text(
              '$userName - $tableId',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: Transform.rotate(
            angle: 3.14, // 180 degrees in radians
            child: const Icon(Icons.logout),
          ),
          onPressed: () async {
            bool? confirmExit = await showDialog<bool>(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Confirm Exit"),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Are you sure you want to exit?"),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text("Exit",
                          style: TextStyle(color: Colors.red)),
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => faqScreen(),
                    ),
                  );
                },
                child: const Text(
                  "FAQs",
                  style: TextStyle(
                    color: Color.fromARGB(255, 49, 49, 49),
                    fontSize: 12,
                  ),
                ),
              ),
              // IconButton(
              //   icon: const Icon(Icons.help),
              //     onPressed: () {
              //       Navigator.push(
              //         context,
              //         MaterialPageRoute(
              //           builder: (context) => faqScreen(),
              //         ),
              //       );
              //     },
              //   ),
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
                            // ignore: use_build_context_synchronously
                            context,
                            MaterialPageRoute(
                              builder: (context) => NotificationScreen(
                                  tableId: tableId, userName: userName),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text("No table ID available")),
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
                            const SnackBar(
                                content: Text("No table ID available")),
                          );
                        }
                      },
                    );
                  }
                },
              ),
            ],
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
              height: 5,
              color: Color(0xFF80ACB2),
            ),
            Container(
              height: 5,
              color: Color(0xFFA3C8CE),
            ),
            Container(
              height: 5,
              color: Color(0xFFD9D3C1),
            ),
          ],
        ),
      ),
      body: Stack(children: [
        // Background image that takes the full width and responsive height based on aspect ratio
        Positioned(
          bottom: 0, // Make sure it's at the bottom of the screen
          left: 0,
          right: 0,
          child: Builder(
            builder: (context) {
              // Get the screen width
              double screenWidth = MediaQuery.of(context).size.width;

              // Assuming the image's aspect ratio (width / height) is 16:9 (you can adjust based on your image)
              double aspectRatio = 16 / 9;
              double imageHeight = screenWidth / aspectRatio;

              return Container(
                width: screenWidth,
                height: imageHeight, // Responsive height based on aspect ratio
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'images/bg.png'), // Replace with your background image path
                    fit: BoxFit
                        .cover, // Ensure it covers the width and scales the height responsively
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
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
                child: const Text("Custom Request",
                    style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: _showMessagesScreen,
        // ignore: sort_child_properties_last
        child: const Icon(Icons.message),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      ),
    );
  }
}
