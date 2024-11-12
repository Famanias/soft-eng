import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  final String tableId;

  const NotificationScreen({required this.tableId, super.key});

  @override
  Widget build(BuildContext context) {
    // Debug print to check the value of tableId
    print("NotificationScreen tableId: $tableId");

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('tableId', isEqualTo: tableId)
            .snapshots(),
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
                  print("Notification pressed: ${data}");
                },
              );
            },
          );
        },
      ),
    );
  }
}
