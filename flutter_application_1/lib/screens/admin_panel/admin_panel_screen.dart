import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
            return const CircularProgressIndicator();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active tables"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text("Table ID: ${doc.id}"),
                subtitle: Text("Status: ${doc['status']}"),
                trailing: Text("Time: ${doc['timestamp'].toDate()}"),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
