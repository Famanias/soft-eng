import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationScreen extends StatefulWidget {
  final String tableId;
  final String userName;

  const NotificationScreen({required this.tableId, required this.userName, super.key});

  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  String _selectedStatus = 'all';
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeLocalNotifications();
    _firebaseMessaging.requestPermission();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;
      if (notification != null && android != null) {
        _showLocalNotification(notification);
      }
    });
  }

  void _initializeLocalNotifications() {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  void _showLocalNotification(RemoteNotification notification) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics = AndroidNotificationDetails(
    'high_importance_channel', // Channel ID
    'High Importance Notifications', // Channel name
    channelDescription: 'This channel is used for important notifications.', // Channel description
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );
  const NotificationDetails platformChannelSpecifics = NotificationDetails(android: androidPlatformChannelSpecifics);
  _flutterLocalNotificationsPlugin.show(
    0,
    notification.title,
    notification.body,
    platformChannelSpecifics,
    payload: 'item x',
  );
}

  @override
  Widget build(BuildContext context) {
    print("NotificationScreen tableId: ${widget.tableId}, userName: ${widget.userName}");

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          DropdownButton<String>(
            value: _selectedStatus,
            icon: const Icon(Icons.filter_list, color: Colors.black),
            dropdownColor: const Color.fromARGB(255, 255, 255, 255),
            onChanged: (String? newValue) {
              setState(() {
                _selectedStatus = newValue!;
              });
            },
            items: <String>['all', 'accepted', 'rejected', 'pending', 'done', 'newMessage']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(
                  value,
                  style: const TextStyle(color: Colors.black),
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
            print("Loading notifications...");
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            print("No notifications found.");
            return const Center(child: Text("No notifications"));
          }

          print("Fetched data: ${snapshot.data!.docs}");

          return ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[snapshot.data!.docs.length - 1 - index];
              print("Document data: ${doc.data()}");
              var data = doc.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(data['type'] == 'newMessage'
                    ? "Message from Admin"
                    : "Request: ${data['requestType']}"),
                subtitle: Text(data['type'] == 'newMessage'
                    ? data['message']
                    : "Status: ${data['status']}"),
                onTap: () {
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
        .where('tableId', isEqualTo: widget.tableId)
        .where('userName', isEqualTo: widget.userName);

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
                      .where('userName', isEqualTo: widget.userName)
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