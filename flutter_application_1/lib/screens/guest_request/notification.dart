import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatefulWidget {
  final String tableId;

  const NotificationScreen({required this.tableId, super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedStatus = 'all';

  @override
  Widget build(BuildContext context) {
    // Debug print to check the value of tableId
    print("NotificationScreen tableId: ${widget.tableId}");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            icon: const Icon(Icons.filter_list, color: Colors.black),
            dropdownColor: const Color.fromARGB(255, 255, 255, 255), // Complementary color to white
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue!;
              });
            },
            items: <String>['all', 'accepted', 'rejected', 'pending', 'done']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black), // Font color set to black
                ),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _clearNotifications(context);
            },
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _getNotificationStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            print("Loading notifications..."); // Debug: Print when loading
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print("No notifications found."); // Debug: Print when no data is found
            return const Center(child: Text("No notifications"));
          }

          // Debug print to see the fetched data
          print("Fetched data: ${snapshot.data!.docs}");

          return ListView.builder(
            padding: EdgeInsets.zero, // Remove default padding
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              // Reverse the order of the documents
              var doc = snapshot.data!.docs[snapshot.data!.docs.length - 1 - index];
              print("Document data: ${doc.data()}");
              var data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text("Request: ${data['requestType']}"),
                subtitle: Text("Status: ${data['status']}"),
                onTap: () {
                  // Debug: Print the data when the notification is pressed
                  print("Notification pressed: $data");
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getNotificationStream() {
    var query = FirebaseFirestore.instance
        .collection('notifications')
        .where('tableId', isEqualTo: widget.tableId);

    if (_selectedStatus != 'all') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }

    return query.snapshots();
  }

  void _clearNotifications(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Clear Notifications"),
          content: const Text("Are you sure you want to clear all notifications?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Clear"),
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  var batch = FirebaseFirestore.instance.batch();
                  var snapshots = await FirebaseFirestore.instance
                      .collection('notifications')
                      .where('tableId', isEqualTo: widget.tableId)
                      .get();
                  for (var doc in snapshots.docs) {
                    batch.delete(doc.reference);
                  }
                  await batch.commit();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Notifications cleared successfully")),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Failed to clear notifications: $e")),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}