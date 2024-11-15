import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_message.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: StreamBuilder(
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
              return ListTile(
                title: Text("Table ID: ${doc.id}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestDetailsScreen(tableId: doc.id),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class RequestDetailsScreen extends StatefulWidget {
  final String tableId;

  const RequestDetailsScreen({required this.tableId, super.key});

  @override
  _RequestDetailsScreenState createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> with SingleTickerProviderStateMixin {
  String userName = "Guest";
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

    setState(() {
      userName = doc['userName'] ?? "Guest";
    });
  }

  void _updateRequestStatus(String requestId, String status) async {
    try {
      // Debug: Print the request ID and status being updated
      print("Updating request ID: $requestId to status: $status");

      // Fetch the request document to get the requestType
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .get();

      String requestType = requestDoc['requestType'];
      String userName = requestDoc['userName'];

      // Update the status of the request
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .update({'status': status});

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
        builder: (context) => AdminMessagesScreen(tableId: widget.tableId, userName: userName),
      ),
    );
  }

  void _confirmMarkAsDone(String requestId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Mark as Done"),
          content: const Text("Are you sure you want to mark this request as done?"),
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

  Widget _buildRequestList(String status) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('guestRequests')
          .where('tableId', isEqualTo: widget.tableId)
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

            userName = data['userName'] ?? "Guest";

            return ListTile(
              title: Text("Request: $requestTypeText"),
              subtitle: Text("Status: ${doc['status']} : Name: $userName"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      print("Check button pressed for request ID: ${doc.id}"); // Debug: Print when check button is pressed
                      _updateRequestStatus(doc.id, 'accepted');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      print("Close button pressed for request ID: ${doc.id}"); // Debug: Print when close button is pressed
                      _updateRequestStatus(doc.id, 'rejected');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.done, color: Colors.grey),
                    onPressed: () {
                      _confirmMarkAsDone(doc.id);
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Details"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Accepted"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList('pending'),
          _buildRequestList('accepted'),
          _buildRequestList('rejected'),
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