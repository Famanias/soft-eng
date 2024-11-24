import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_message.dart';
import 'admin_notification.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  AdminPanelState createState() => AdminPanelState();
}

class AdminPanelState extends State<AdminPanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedIndex = 0;

  Future<void> _logout(BuildContext context) async {
    try {
      await _auth.signOut();
      Navigator.pushReplacementNamed(
          context, '/qrCode'); // Redirect to login screen
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
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
              child: Text("Logout"),
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
        title: const Text("TableServe"),
        automaticallyImplyLeading: false,
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
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () =>
                _confirmLogout(context), // Call the logout function
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildActiveTables() : _buildAnalytics(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.table_chart),
            label: 'Tables',
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

        return ListView(
          children: snapshot.data!.docs.map((doc) {
            String tableId = doc.id;
            return ListTile(
              title: Text("Table ID: $tableId"),
              trailing: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('guestRequests')
                    .where('tableId', isEqualTo: tableId)
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder:
                    (context, AsyncSnapshot<QuerySnapshot> requestSnapshot) {
                  if (requestSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  int pendingCount = requestSnapshot.data?.docs.length ?? 0;
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
        );
      },
    );
  }

  Widget _buildAnalytics() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance.collection('analytics').snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No analytics data"));
        }

        // Aggregate data
        Map<String, Map<String, int>> aggregatedData = {};
        for (var doc in snapshot.data!.docs) {
          var data = doc.data() as Map<String, dynamic>;
          String tableId = data['tableId'];
          int requestCount = data['requestCount'] ?? 0;
          int usersCount = data['usersCount'] ?? 0;

          if (!aggregatedData.containsKey(tableId)) {
            aggregatedData[tableId] = {'requestCount': 0, 'usersCount': 0};
          }

          aggregatedData[tableId]!['requestCount'] = (aggregatedData[tableId]!['requestCount'] ?? 0) + requestCount;
          aggregatedData[tableId]!['usersCount'] = (aggregatedData[tableId]!['usersCount'] ?? 0) + usersCount;
        }

        List<_ChartData> requestData = aggregatedData.entries.map((entry) {
          return _ChartData(entry.key, entry.value['requestCount']!);
        }).toList();

        List<_ChartData> userData = aggregatedData.entries.map((entry) {
          return _ChartData(entry.key, entry.value['usersCount']!);
        }).toList();

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                "Request Count",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: <ChartSeries>[
                    ColumnSeries<_ChartData, String>(
                      dataSource: requestData,
                      xValueMapper: (_ChartData data, _) => data.tableId,
                      yValueMapper: (_ChartData data, _) => data.count,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "User Count",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 300,
                child: SfCartesianChart(
                  primaryXAxis: CategoryAxis(),
                  series: <ChartSeries>[
                    ColumnSeries<_ChartData, String>(
                      dataSource: userData,
                      xValueMapper: (_ChartData data, _) => data.tableId,
                      yValueMapper: (_ChartData data, _) => data.count,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        'updatedBy': staffName, // Use staffName for updatedBy
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
        'updatedBy': staffName, // Also use staffName for the notification
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

      // String currentStatus = requestDoc['status'];
      String tableId = requestDoc['tableId'];
      // String userName = requestDoc['userName'];
      String requestType = requestDoc['requestType'];
      String userName = requestDoc['userName'];

      // Only notify the user if the request is not already accepted
      // Update the status to 'done'
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .update({'status': 'done'});

      // Add a notification document

      await FirebaseFirestore.instance
          .collection('notifications')
          .doc('Status of $requestId for $userName')
          .set({
        'tableId': tableId,
        'requestId': requestId,
        'requestType': requestType,
        'status': 'done',
        'viewed': false,
        'timestamp': FieldValue.serverTimestamp(),
        'userName': userName,
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
          title: const Text("Confirm Deletion"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  "Type 'I UNDERSTAND' to confirm deletion of all requests."),
              const SizedBox(height: 10),
              TextField(
                controller: confirmationController,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                  hintText: 'I UNDERSTAND',
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
                if (confirmationController.text == 'I UNDERSTAND') {
                  _deleteAllRequests();
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Incorrect confirmation text")),
                  );
                }
              },
              child: const Text("Delete"),
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

            return ListTile(
              title: Text("Request: $requestTypeText"),
              subtitle: Text("Status: ${doc['status']} : Name: $userName"),
              trailing: _buildTrailingButtons(status, doc.id),
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
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              _updateRequestStatus(requestId, 'accepted');
            },
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              _updateRequestStatus(requestId, 'rejected');
            },
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
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              _updateRequestStatus(requestId, 'accepted');
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              _deleteRequest(requestId);
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
        title: const Text("Details"),
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
                .collection('activeTables')
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }
              var tableIds = snapshot.data!.docs.map((doc) => doc.id).toList();
              return DropdownButton<String>(
                value: _selectedTableId,
                icon: const Icon(Icons.list, color: Colors.black),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedTableId = newValue!;
                  });
                },
                items: tableIds.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              );
            },
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
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteConfirmationDialog,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMessagesScreen(userName),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message),
      ),
    );
  }
}
