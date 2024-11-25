import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login/login.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/admin_panel/admin_panel_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:awesome_notifications/awesome_notifications.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables and ensure it completes
  await dotenv.load(fileName: "assets/.env");

  // await Future.delayed(const Duration(milliseconds: 100));

  // Initialize firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: dotenv.env['apiKey']!,
      appId: dotenv.env['appId']!,
      messagingSenderId: dotenv.env['messagingSenderId']!,
      projectId: dotenv.env['projectId']!,
    ),
  );

  AwesomeNotifications().initialize(
    'resource://drawable/ic_launcher', // Default icon for notifications
    [
      NotificationChannel(
        channelKey: 'high_importance_channel',
        channelName: 'High Importance Notifications',
        channelDescription: 'This channel is used for important notifications.',
        defaultColor: Color(0xFF9D50DD),
        ledColor: Colors.white,
        importance: NotificationImportance.High,
      ),
    ],
  );

  // Request notification permissions
  await AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
    if (!isAllowed) {
      // This is just an example. You can show a dialog or any other UI element to request permission.
      AwesomeNotifications().requestPermissionToSendNotifications();
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());

  _setupGlobalNotificationListener();
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  AwesomeNotifications().createNotificationFromJsonData(message.data);
}


void _setupGlobalNotificationListener() {
  FirebaseFirestore.instance
      .collection('notifications')
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
          ? 'Message from Admin'
          : 'Request: ${data['requestType']}',
      body: data['type'] == 'newMessage'
          ? data['message']
          : 'Status: ${data['status']}',
      notificationLayout: NotificationLayout.Default,
      icon: 'resource://drawable/ic_launcher',
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TableServe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => LoginScreen(),
        '/adminPanel': (context) => AdminPanel(),
      },
    );
  }
}
