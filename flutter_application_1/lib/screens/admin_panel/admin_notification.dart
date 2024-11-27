import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  AdminNotificationScreenState createState() => AdminNotificationScreenState();
}

class AdminNotificationScreenState extends State<AdminNotificationScreen> {
  String _selectedFilter = 'all';

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
            ? '${data['message']}'
            : 'Request',
        body: data['type'] == 'newMessage'
            ? data['message']
            : '${data['message']}',
        notificationLayout: NotificationLayout.Default,
        icon: 'resource://drawable/ic_launcher',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          DropdownButton<String>(
            value: _selectedFilter,
            icon: const Icon(Icons.filter_list,
                color: Color.fromARGB(255, 97, 97, 97)),
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
            onPressed: () async {
              final bool? confirmDelete = await showDialog<bool>(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Clear Notifications'),
                    content: const Text('Are you sure you want to clear all notifications?'),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(false); // Cancel deletion
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true); // Confirm deletion
                        },
                        child: const Text('Clear',
                        style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  );
                },
              );

              if (confirmDelete == true) {
                _clearNotifications(context);
              }
            },
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
                    : Colors.grey[300], // Change background color based on viewed status
                title: Text(
                  data['message'],
                ),
                subtitle: Text(data['timestamp'].toDate().toString()),
                onTap: () async {
                  // Mark notification as viewed using a WriteBatch
                  WriteBatch batch = FirebaseFirestore.instance.batch();
                  batch.update(doc.reference, {'viewed': true});
                  await batch.commit();
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

  void _markAllAsRead() async {
    var snapshots =
        await FirebaseFirestore.instance.collection('adminNotifications').get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.update(doc.reference, {'viewed': true});
    }
    await batch.commit();
  }

  void _clearNotifications(BuildContext context) async {
    var snapshots = await FirebaseFirestore.instance
        .collection('adminNotifications')
        .get();
    WriteBatch batch = FirebaseFirestore.instance.batch();
    for (var doc in snapshots.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    // Show confirmation message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications have been cleared'),
        duration: Duration(seconds: 2),
      ),
    );
  }

}