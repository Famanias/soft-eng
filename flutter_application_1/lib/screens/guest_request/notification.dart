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
            .collection('guestRequests')
            .doc(tableId)
            .collection('messages')
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          // Debug print to see the fetched data
          print("Fetched data: ${snapshot.data!.docs}");

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              print("Document data: ${doc.data()}"); 
              return ListTile(
                title: Text("Request: ${doc['requestType'].join(', ')}"),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Status: ${doc['status']}"),
                    if (doc['message'] != null) Text("Message: ${doc['message']}"),
                    Text("Time: ${doc['timestamp'].toDate()}"),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}