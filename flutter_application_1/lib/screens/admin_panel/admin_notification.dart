import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  AdminNotificationScreenState createState() =>
      AdminNotificationScreenState();
}

class AdminNotificationScreenState extends State<AdminNotificationScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Notifications"),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onChanged: (String? newValue) {
              setState(() {
                _selectedFilter = newValue!;
              });
            },
            items: <String>[
              'all',
              'newTable',
              'newUser',
              'newRequest',
              'newMessage'
            ].map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _clearNotifications,
          ),
        ],
      ),
      body: StreamBuilder(
        stream: _getNotificationStream(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          // Sort notifications by timestamp in descending order
          var sortedDocs = snapshot.data!.docs;
          sortedDocs.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

          return ListView.builder(
            itemCount: sortedDocs.length,
            itemBuilder: (context, index) {
              var doc = sortedDocs[index];
              var data = doc.data() as Map<String, dynamic>;
              return ListTile(
                tileColor: data['viewed']
                    ? Colors.transparent
                    : Colors.grey[
                        300], // Change background color based on viewed status
                title: Text(
                  data['message'],
                ),
                subtitle: Text(data['timestamp'].toDate().toString()),
                onTap: () async {
                  // Mark notification as viewed
                  await FirebaseFirestore.instance
                      .collection('adminNotifications')
                      .doc(doc.id)
                      .update({'viewed': true});
                  setState(() {
                    // Update the specific notification's viewed status locally
                    data['viewed'] = true;
                  });
                },
              );
            },
          );
        },
      ),
    );
  }

  Stream<QuerySnapshot> _getNotificationStream() {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('adminNotifications');
    if (_selectedFilter != 'all') {
      query = query.where('type', isEqualTo: _selectedFilter);
    }
    return query.snapshots();
  }

  void _clearNotifications() async {
    var snapshots =
        await FirebaseFirestore.instance.collection('adminNotifications').get();
    for (var doc in snapshots.docs) {
      await doc.reference.delete();
    }
  }
}
