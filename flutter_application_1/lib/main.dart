import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/guest_request/guest_request_screen.dart';
import 'screens/custom_request/custom_request_screen.dart';
import 'screens/admin_panel/admin_panel_screen.dart';
import 'screens/qr_code/qr_code_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Future.delayed(const Duration(milliseconds: 100));
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBzWodEQCoiKxigxPrYpvR1w18RU34w7J0',
      appId: '1:866243564535:android:765971cef2c2e3b174d4f2',
      messagingSenderId: '866243564535',
      projectId: 'tableserve-b0183',
    ),
  );

  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
        '/customRequest': (context) => const CustomRequestScreen(tableId: '',),
        '/adminPanel': (context) => const AdminPanel(),
      },
    );
  }
}
