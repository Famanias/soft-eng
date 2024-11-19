import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/guest_request/guest_request_screen.dart';
import 'screens/guest_request/custom_request_screen.dart';
import 'screens/admin_panel/admin_panel_screen.dart';
import 'screens/qr_code/qr_code_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}


void main() async {
  WidgetsFlutterBinding.ensureInitialized();  
  
  // Load environment variables and ensure it completes
  await dotenv.load(fileName: "assets/.env");

  // Debugging print to verify .env loading
  print('Dotenv loaded: ${dotenv.env}');
  print('Loaded API Key: ${dotenv.env['apiKey']}');

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
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  
  runApp(const MyApp());
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
      ),
      
      // Set the initial route to main screen
      initialRoute: '/qrCode',
      // Define routes for navigation
      routes: {
        '/qrCode': (context) => const ScanScreen(),
        '/guestRequest': (context) => const GuestRequestScreen(),
        '/customRequest': (context) => const CustomRequestScreen(tableId: '', userName: '',),
        '/adminPanel': (context) => const AdminPanel(),
      },
    );
  }
}
