import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_message.dart';
import 'admin_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/intl.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  AdminPanelState createState() => AdminPanelState();
}

class AdminPanelState extends State<AdminPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;
  DateTime selectedWeek = DateTime.now();
  List<DateTime> weeks = [];

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(
          context, '/login'); // Redirect to login screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _listenForNotifications();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message.data);
    });
  }

  void _listenForNotifications() {
    FirebaseFirestore.instance
        .collection('adminNotifications')
        .where('viewed', isEqualTo: false)
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
        title: data['type'] == 'newMessage' ? '${data['message']}' : 'Request',
        body: data['type'] == 'newMessage'
            ? data['message']
            : '${data['message']}',
        notificationLayout: NotificationLayout.Default,
        icon: 'resource://drawable/ic_launcher',
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    bool? shouldLogout = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Logout"),
          content: Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text("Logout",
                  style: TextStyle(
                      color: Colors.red)), // Set the text color to red
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      _logout(context);
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        title: const Text("TableServe",
            style: TextStyle(
              color: Color(0xffD4C4AB),
              fontSize: 32,
              fontFamily: "RubikOne",
            )),
        centerTitle: true,
        leading: IconButton(
          icon: Transform.rotate(
            angle: 3.14, // 180 degrees in radians
            child: Icon(Icons.logout),
          ),
          onPressed: () => _confirmLogout(context), // Call the logout function
        ),
        actions: [
          if (_selectedIndex == 2)
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('adminNotifications')
                .where('viewed', isEqualTo: false)
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
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminNotificationScreen(),
                      ),
                    );
                  },
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminNotificationScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
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
      body: _selectedIndex == 0
          ? _buildActiveTables()
          : _selectedIndex == 1
              ? _buildRequestList()
              : _buildAnalytics(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Tables',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.room_service_rounded),
            label: 'Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildActiveTables() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('activeTables').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No active tables"));
        }

        return Column(
          children: [
            Text(
              'Tables',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF316175),
                fontSize: 32,
                fontFamily: 'RubikOne',
              ),
            ),
            Expanded(
              child: ListView(
                children: snapshot.data!.docs.map((doc) {
                  String tableId = doc.id;
                  return ListTile(
                    title: Text(
                      {
                            "table_1": "Table 1",
                            "table_2": "Table 2",
                            "table_3": "Table 3",
                            "table_4": "Table 4",
                            "table_5": "Table 5",
                          }[tableId] ??
                          tableId, // Default to tableId if not found in the map
                    ),
                    // title: Text("$tableId"), // Display the tableId as the title
                    trailing: StreamBuilder(
                      stream: FirebaseFirestore.instance
                          .collection('guestRequests')
                          .where('tableId', isEqualTo: tableId)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context,
                          AsyncSnapshot<QuerySnapshot> requestSnapshot) {
                        if (requestSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        }
                        int pendingCount =
                            requestSnapshot.data?.docs.length ?? 0;
                        return Stack(
                          children: [
                            const Icon(Icons.table_restaurant, size: 30),
                            if (pendingCount > 0)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '$pendingCount',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RequestDetailsScreen(tableId: tableId),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            )
          ],
        );
      },
    );
  }

  Widget _buildRequestList() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('requestList').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AddRequestDialog();
                        },
                      );
                    },
                    child: Row(
                      children: [
                        Icon(Icons.add, color: Colors.blue),
                        SizedBox(
                            width:
                                8), // Optional: Adds space between icon and text
                        Text('Add Request'),
                      ],
                    ),
                  )
                ],
              ),
            ],
          );
        }

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Request List',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF316175),
                    fontSize: 22,
                    fontFamily: 'RubikOne',
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.add, color: Colors.blue),
                  label: Text(
                    'Add Request',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AddRequestDialog();
                      },
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 5.0),
                  child: TextButton.icon(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    label: const Text(
                      'Edit FAQ',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      _showFaqEditDialog();
                    },
                  ),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                children: snapshot.data!.docs.map((doc) {
                  // Extracting the request details
                  String requestType = doc['type'] ?? 'Unknown';
                  String information =
                      doc['information'] ?? 'No information provided';
                  List<String> items = List<String>.from(doc['items']);
                  String itemsJoined = items.join(',');

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    elevation: 4,
                    child: ListTile(
                      title: Text(requestType,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(information),
                          if (itemsJoined != "") ...[
                            const SizedBox(height: 8),
                            Text("Items: ${items.join(', ')}"),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit icon
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.orange),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return EditRequestDialog(
                                      doc: doc.data() as Map<String, dynamic>);
                                },
                              );
                            },
                          ),
                          // Delete icon
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteRequestConfirmationDialog(
                                  context, doc.id);
                            },
                          ),
                        ],
                      ),
                      onTap: () {
                        // Add navigation or actions on tap if necessary
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showFaqEditDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit FAQs"),
          content: Container(
            width: double.maxFinite,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('faqs').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final faqs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    var faq = faqs[index];
                    var data = faq.data() as Map<String, dynamic>;

                    return ListTile(
                      title: Text(data['title'] ?? 'No Title'),
                      subtitle: Text(data['content'] ?? 'No Content'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              _showEditDialog(faq.id, data);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteFaqConfirmationDialog(context, faq.id);
                            },
                          ),
                        ],
                      ),
                    );
                  },
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
            ElevatedButton(
              onPressed: () {
                _showAddFaqDialog();
              },
              child: const Text("Add FAQ"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteFaqConfirmationDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete FAQ"),
          content: const Text("Are you sure you want to delete this FAQ?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('faqs')
                    .doc(docId)
                    .delete()
                    .then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQ deleted successfully')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete FAQ: $error')),
                  );
                });
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(String docId, Map<String, dynamic> data) {
    TextEditingController titleController =
        TextEditingController(text: data['title']);
    TextEditingController contentController =
        TextEditingController(text: data['content']);
    TextEditingController detailsController =
        TextEditingController(text: data['details']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit FAQ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('faqs')
                    .doc(docId)
                    .update({
                  'title': titleController.text,
                  'content': contentController.text,
                  'details': detailsController.text,
                }).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQ updated successfully')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update FAQ: $error')),
                  );
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showAddFaqDialog() {
    TextEditingController titleController = TextEditingController();
    TextEditingController contentController = TextEditingController();
    TextEditingController detailsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add FAQ"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(labelText: 'Content'),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(labelText: 'Details'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                FirebaseFirestore.instance.collection('faqs').add({
                  'title': titleController.text,
                  'content': contentController.text,
                  'details': detailsController.text,
                }).then((_) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FAQ added successfully')),
                  );
                }).catchError((error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add FAQ: $error')),
                  );
                });
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteRequestConfirmationDialog(
      BuildContext context, String docId) {
    TextEditingController confirmationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Request"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Type 'DELETE' to confirm deleting this request."),
              const SizedBox(height: 10),
              TextField(
                controller: confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                  hintText: 'DELETE',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmationController.text == 'DELETE') {
                  FirebaseFirestore.instance
                      .collection('requestList')
                      .doc(docId)
                      .delete()
                      .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Request deleted successfully')));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to delete request')));
                  });
                  FirebaseFirestore.instance
                      .collection('globalAnalytics')
                      .doc(docId)
                      .delete()
                      .then((_) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Request From Analytics Successfully')));
                  }).catchError((error) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content:
                            Text('Failed to delete request from Analytics')));
                  });
                  Navigator.of(context)
                      .pop(); // Close the dialog after deletion
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Incorrect confirmation text")),
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
              ),
              child:
                  const Text("DELETE", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // analytics
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Widget _buildAnalytics() {
    DateTime startOfDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    DateTime endOfDay = startOfDay.add(Duration(days: 1));

    return Column(
      children: [
        Expanded(
          child: StreamBuilder(
            stream:
                FirebaseFirestore.instance.collection('analytics').snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> analyticsSnapshot) {
              if (analyticsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!analyticsSnapshot.hasData ||
                  analyticsSnapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No analytics data"));
              }

              return StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('globalAnalytics')
                    .where('timestamp',
                        isGreaterThanOrEqualTo:
                            startOfDay) // Filter by timestamp
                    .where('timestamp',
                        isLessThan: endOfDay) // Filter by timestamp
                    .snapshots(),
                builder: (context,
                    AsyncSnapshot<QuerySnapshot> globalAnalyticsSnapshot) {
                  if (globalAnalyticsSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!globalAnalyticsSnapshot.hasData ||
                      globalAnalyticsSnapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("No global analytics data"));
                  }

                  // Aggregate data for analytics collection
                  Map<String, Map<String, int>> aggregatedData = {};
                  int totalUsersCount = 0;
                  int totalRequestsCount = 0;

                  for (var doc in analyticsSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    String tableId = data['tableId'] ?? 'Unknown';
                    int requestCount = data['requestCount'] ?? 0;
                    int usersCount = data['usersCount'] ?? 0;

                    if (!aggregatedData.containsKey(tableId)) {
                      aggregatedData[tableId] = {
                        'requestCount': 0,
                        'usersCount': 0
                      };
                    }

                    aggregatedData[tableId]!['requestCount'] =
                        (aggregatedData[tableId]!['requestCount'] ?? 0) +
                            requestCount;
                    aggregatedData[tableId]!['usersCount'] =
                        (aggregatedData[tableId]!['usersCount'] ?? 0) +
                            usersCount;

                    totalRequestsCount += requestCount;
                    totalUsersCount += usersCount;
                  }

                  List<_ChartData> requestData =
                      aggregatedData.entries.map((entry) {
                    return _ChartData(entry.key, entry.value['requestCount']!);
                  }).toList();

                  List<_ChartData> userData =
                      aggregatedData.entries.map((entry) {
                    return _ChartData(entry.key, entry.value['usersCount']!);
                  }).toList();

                  // Aggregate data for globalAnalytics collection
                  List<_ChartData> requestTypeData = [];
                  for (var doc in globalAnalyticsSnapshot.data!.docs) {
                    var data = doc.data() as Map<String, dynamic>;
                    // Iterate over each field in the document
                    data.forEach((key, value) {
                      if (value is int) {
                        // Ensure the value is an integer
                        requestTypeData.add(_ChartData(key, value));
                      }
                    });
                  }

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 10),
                        // Display Total Counts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Total Requests
                            Container(
                              // width: 200,
                              padding: const EdgeInsets.all(8),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.blue),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$totalRequestsCount",
                                    style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue),
                                  ),
                                  const Text(
                                    "Total Requests",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                            // Total Users
                            Container(
                              // width: 200,
                              padding: const EdgeInsets.all(8),
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.green[50],
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.green),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "$totalUsersCount",
                                    style: const TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                  const Text(
                                    "Total Users",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "Request Count by Table",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 300,
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            series: <ChartSeries>[
                              ColumnSeries<_ChartData, String>(
                                dataSource: requestData,
                                xValueMapper: (_ChartData data, _) =>
                                    data.tableId,
                                yValueMapper: (_ChartData data, _) =>
                                    data.count,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "User Count by Table",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 300,
                          child: SfCartesianChart(
                            primaryXAxis: CategoryAxis(),
                            series: <ChartSeries>[
                              ColumnSeries<_ChartData, String>(
                                dataSource: userData,
                                xValueMapper: (_ChartData data, _) =>
                                    data.tableId,
                                yValueMapper: (_ChartData data, _) =>
                                    data.count,
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Request Type Frequency",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        SizedBox(
                          height: 400,
                          child: SfCircularChart(
                            legend: Legend(
                              isVisible: true,
                              alignment: ChartAlignment
                                  .center, // Aligns the legend to the center
                              position: LegendPosition
                                  .bottom, // Places the legend below the chart
                              orientation: LegendItemOrientation.vertical,
                              overflowMode: LegendItemOverflowMode
                                  .wrap, // Allows wrapping for long legends
                              itemPadding: 10,
                            ),
                            series: <CircularSeries>[
                              PieSeries<_ChartData, String>(
                                dataSource: requestTypeData,
                                xValueMapper: (_ChartData data, _) =>
                                    data.tableId,
                                yValueMapper: (_ChartData data, _) =>
                                    data.count,
                                dataLabelSettings:
                                    const DataLabelSettings(isVisible: true),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class AddRequestDialog extends StatefulWidget {
  const AddRequestDialog({super.key});

  @override
  AddRequestDialogState createState() => AddRequestDialogState();
}

// add request for admin
class AddRequestDialogState extends State<AddRequestDialog> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _informationController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  List<String> _items = [];

  void _addItem() {
    setState(() {
      if (_itemController.text.isNotEmpty) {
        _items.add(_itemController.text);
        _itemController.clear();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create New Request",
          style: TextStyle(
            color: Color(0xFF316175),
            fontFamily: "RubikOne",
          )),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _typeController,
              decoration: InputDecoration(labelText: 'Request'),
            ),
            TextField(
              controller: _informationController,
              decoration: InputDecoration(labelText: 'Information'),
            ),
            TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  labelText: 'Add Item',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.add),
                    onPressed: _addItem,
                  ),
                )),
            SizedBox(height: 10),
            Column(
              children: _items.map((item) {
                int index = _items.indexOf(item);
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => _removeItem(index),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            String type = _typeController.text;
            String information = _informationController.text;
            List<String> items = List.from(_items);
            if (_items.isEmpty) {
              items = [];
            }

            if (type.isEmpty || information.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text("Request type and information cannot be empty")));
              return;
            }

            var existingDoc = await FirebaseFirestore.instance
                .collection('requestList')
                .doc(type)
                .get();

            if (existingDoc.exists) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("A request with this type already exists")));
            } else {
              // Add request with 'type' as document ID
              FirebaseFirestore.instance
                  .collection('requestList')
                  .doc(type)
                  .set({
                'type': type,
                'information': information,
                'items': items.isEmpty ? [] : items,
              }).then((_) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Request added successfully')));
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to add request')));
              });
              // add request to the analytics
              FirebaseFirestore.instance
                  .collection('globalAnalytics')
                  .doc(type)
                  .set({
                type: 0,
              }).then((_) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Request added to Analytics')));
              }).catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Failed to add request to Analytics')));
              });
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class EditRequestDialog extends StatefulWidget {
  final Map<String, dynamic> doc; // Accept doc as a parameter

  const EditRequestDialog({super.key, required this.doc});

  @override
  EditRequestDialogState createState() => EditRequestDialogState();
}

class EditRequestDialogState extends State<EditRequestDialog> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _informationController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  List<String> _items = [];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with current doc values
    _typeController.text = widget.doc['type'];
    _informationController.text = widget.doc['information'];
    _items = List<String>.from(widget.doc['items'] ?? []);
  }

  void _addItem() {
    setState(() {
      if (_itemController.text.isNotEmpty) {
        _items.add(_itemController.text);
        _itemController.clear();
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Request",
          style: TextStyle(
            color: Color(0xFF316175),
            fontFamily: "RubikOne",
          )),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _typeController,
              decoration: InputDecoration(labelText: 'Request'),
            ),
            TextField(
              controller: _informationController,
              decoration: InputDecoration(labelText: 'Information'),
            ),
            TextField(
              controller: _itemController,
              decoration: InputDecoration(
                labelText: 'Add Item',
                suffixIcon: IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addItem,
                ),
              ),
            ),
            SizedBox(height: 10),
            Column(
              children: _items.map((item) {
                int index = _items.indexOf(item);
                return ListTile(
                  title: Text(item),
                  trailing: IconButton(
                    icon: Icon(Icons.remove),
                    onPressed: () => _removeItem(index),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            String type = _typeController.text;
            String information = _informationController.text;
            List<String> items = List.from(_items);

            if (type.isEmpty || information.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text("Request type and information cannot be empty")));
              return;
            }

            // Logic to update existing document with new data
            await FirebaseFirestore.instance
                .collection('requestList')
                .doc(widget.doc['type']) // Use old type as doc ID
                .delete(); // Delete old document

            // Add the updated request to Firestore
            FirebaseFirestore.instance.collection('requestList').doc(type).set({
              'type': type,
              'information': information,
              'items': items.isEmpty ? [] : items,
            }).then((_) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Request updated successfully')));
            }).catchError((error) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update request')));
            });

            // Update global analytics
            var oldDoc = await FirebaseFirestore.instance
                .collection('globalAnalytics')
                .doc(widget.doc['type'])
                .get();

            if (oldDoc.exists) {
              var requestTypeValue = oldDoc.data()?[widget.doc['type']];
              // Now delete the old document
              await FirebaseFirestore.instance
                  .collection('globalAnalytics')
                  .doc(widget.doc['type'])
                  .delete();
              await FirebaseFirestore.instance
                  .collection('globalAnalytics')
                  .doc(type) // Set the new type in global analytics
                  .set({type: requestTypeValue});
            }
          },
          child: Text("Save"),
        ),
      ],
    );
  }
}

class _ChartData {
  _ChartData(this.tableId, this.count);

  final String tableId;
  final int count;
}

class RequestDetailsScreen extends StatefulWidget {
  final String tableId;

  const RequestDetailsScreen({required this.tableId, super.key});

  @override
  RequestDetailsScreenState createState() => RequestDetailsScreenState();
}

class RequestDetailsScreenState extends State<RequestDetailsScreen>
    with SingleTickerProviderStateMixin {
  String userName = "Guest";
  late TabController _tabController;
  String? _selectedTableId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedTableId = widget.tableId;
    _fetchUserName();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('activeTables')
        .doc(widget.tableId)
        .get();

    if (doc.exists &&
        doc.data() != null &&
        (doc.data() as Map<String, dynamic>).containsKey('userName')) {
      setState(() {
        userName = doc['userName'] ?? "Guest";
      });
    } else {
      setState(() {
        userName = "Guest";
      });
    }
  }

  void _updateRequestStatus(String requestId, String status) async {
    try {
      // Fetch the current user's email (admin's email)
      String? adminEmail = FirebaseAuth.instance.currentUser?.email;

      if (adminEmail == null) {
        print("No admin email found.");
        return;
      }

      // Debug: Print the request ID and status being updated
      print("Updating request ID: $requestId to status: $status");

      // Fetch the staffName using the admin email from staffCredentials
      DocumentSnapshot staffDoc = await FirebaseFirestore.instance
          .collection('staffCredentials')
          .where('email', isEqualTo: adminEmail)
          .limit(1) // Limit to one result
          .get()
          .then((querySnapshot) => querySnapshot.docs.isNotEmpty
              ? querySnapshot.docs.first as DocumentSnapshot<Object?>
              : throw Exception("No staff document found"));

      String staffName =
          staffDoc['staffName']; // Retrieve staffName from staffCredentials

      // Fetch the request document to get the requestType and userName
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        print("Request document does not exist.");
        return;
      }

      String requestType = requestDoc['requestType'];
      String userName = requestDoc['userName']; // Get the userName of the guest

      // Update the status of the request and set updatedBy to staffName
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .update({
        'status': status,
        'updatedBy': staffName,
      });

      // Add a notification document
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('Status of $requestId for $userName')
          .set({
        'tableId': widget.tableId,
        'requestId': requestId,
        'requestType': requestType,
        'status': status,
        'viewed': false,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': userName,
        'sendTo': 'user',
        'updatedBy': staffName,
      });

      // Notify the user of successful update
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request status updated to $status"),
          duration: Duration(seconds: 3), // Set the duration for the SnackBar
        ),
      );
    } catch (e) {
      // Show error message if update fails
      print("Error updating request status: $e"); // Debug: Print the error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update request status: $e"),
          duration: Duration(seconds: 3), // Set the duration for the SnackBar
        ),
      );
    }
  }

  void _showMessagesScreen(String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AdminMessagesScreen(tableId: widget.tableId, userName: userName),
      ),
    );
  }

  void _confirmMarkAsDone(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Mark as Done"),
          content:
              const Text("Are you sure you want to mark this request as done?"),
          actions: [
            TextButton(
              child: const Text("Not yet"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Done"),
              onPressed: () {
                _markAsDone(requestId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAsDone(String requestId) async {
    try {
      // Fetch the request document to get the current status and requestType
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .get();

      String tableId = requestDoc['tableId'];
      String requestType = requestDoc['requestType'];
      String userName = requestDoc['userName'];

      // add to guest request
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .update({
        'status': 'done',
      });

      // add the guest request to the done collection
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .update({
        'status': 'done',
      });

      // Add a new notification document
      await FirebaseFirestore.instance.collection('notifications').add({
        'tableId': tableId,
        'requestId': requestId,
        'requestType': requestType,
        'status': 'done',
        'viewed': false,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': userName,
        'sendTo': 'user',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request marked as done successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to mark request as done: $e")),
      );
    }
  }

  void _showDeleteConfirmationDialog() {
    TextEditingController confirmationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Clear Table Requests"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Type 'CLEAR' to confirm clearing of all requests."),
              const SizedBox(height: 10),
              TextField(
                controller: confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                  hintText: 'CLEAR',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (confirmationController.text == 'CLEAR') {
                  _deleteAllRequests();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Incorrect confirmation text")),
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.white),
              ),
              child: const Text("CLEAR"),
            ),
          ],
        );
      },
    );
  }

  void _deleteAllRequests() async {
    var snapshots = await FirebaseFirestore.instance
        .collection('guestRequests')
        .where('tableId', isEqualTo: widget.tableId)
        .get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }

  Widget _buildRequestList(String status) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('guestRequests')
          .where('tableId', isEqualTo: _selectedTableId)
          .where('status', isEqualTo: status)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No requests for this table"));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: snapshot.data!.docs.map((doc) {
            var data = doc.data() as Map<String, dynamic>;

            var requestType = doc['requestType'];
            String requestTypeText;
            if (requestType is List) {
              requestTypeText = requestType.join(', ');
            } else {
              requestTypeText = requestType.toString();
            }

            String userName = data['userName'] ?? "Guest";
            String staffName = data['updatedBy'] ?? "Unassigned";
            String itemName;
            if (data['items'] is List) {
              itemName = data['items'].join(', ');
            } else {
              itemName = data['items'].toString();
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requestTypeText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (itemName != "null")
                    Text(
                      "Items: $itemName",
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    "Time of Request: ${DateFormat('MMMM d, y h:mm a').format(data['timestamp'].toDate())}",
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        "Requested by: $userName",
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Status: ${doc['status']}",
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (doc['status'] == 'rejected')
                    Text(
                      "Rejected by: $staffName",
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (doc['status'] == 'accepted')
                    Text(
                      "Accepted by: $staffName",
                      style: const TextStyle(fontSize: 14),
                    ),
                  if (doc['status'] == 'done')
                    Text(
                      "Done by: $staffName",
                      style: const TextStyle(fontSize: 14),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildTrailingButtons(status, doc.id) ?? Container(),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget? _buildTrailingButtons(String status, String requestId) {
    if (status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: () {
              // Handle reject button
              _updateRequestStatus(requestId, 'rejected');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[300],
            ),
            child: const Text(
              "Reject",
              style: TextStyle(color: Colors.black),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              // Handle accept button
              _updateRequestStatus(requestId, 'accepted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              "Accept",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    } else if (status == 'accepted') {
      return IconButton(
        icon: const Icon(Icons.checklist, color: Colors.grey),
        onPressed: () {
          _confirmMarkAsDone(requestId);
        },
      );
    } else if (status == 'rejected') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: const Text(
                        "Are you sure you want to delete this request?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          _deleteRequest(
                              requestId); // Perform the delete action
                        },
                        child: const Text("Delete",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () {
              // Handle accept button
              _updateRequestStatus(requestId, 'accepted');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text(
              "Accept",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      );
    } else if (status == 'done') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text("Confirm Deletion"),
                    content: const Text(
                        "Are you sure you want to delete this request?"),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                        },
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          _deleteRequest(
                              requestId); // Perform the delete action
                        },
                        child: const Text("Delete",
                            style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      );
    } else {
      return null;
    }
  }

  Future<void> _deleteRequest(String requestId) async {
    try {
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Request deleted successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete request: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              {
                    "table_1": "Table 1",
                    "table_2": "Table 2",
                    "table_3": "Table 3",
                    "table_4": "Table 4",
                    "table_5": "Table 5",
                  }[widget.tableId] ??
                  widget.tableId, // Default to tableId if not found in the map
            ),
            TextButton(
              onPressed: _showDeleteConfirmationDialog,
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey,
                backgroundColor: Colors.transparent, // Set icon color to grey
              ),
              child: const Text("CLEAR"),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Accepted"),
            Tab(text: "Rejected"),
            Tab(text: "Done")
          ],
        ),
        actions: [
          StreamBuilder(
            stream: FirebaseFirestore.instance
                .collection('adminNotifications')
                .where('viewed', isEqualTo: false)
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
                        ),
                      ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminNotificationScreen(),
                      ),
                    );
                  },
                );
              } else {
                return IconButton(
                  icon: const Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminNotificationScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('pending'),
          _buildRequestList('accepted'),
          _buildRequestList('rejected'),
          _buildRequestList('done'),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomLeft,
        child: Padding(
          padding: const EdgeInsets.all(30.0), // Adjust the padding as needed
          child: FloatingActionButton(
            onPressed: () => _showMessagesScreen(userName),
            backgroundColor: Colors.white,
            child: const Icon(Icons.message),
          ),
        ),
      ),
    );
  }
}
