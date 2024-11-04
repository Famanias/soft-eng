import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'screens/guest_request/guest_request_screen.dart';
import 'screens/custom_request/custom_request_screen.dart';
import 'screens/admin_panel/admin_panel_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
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
      // Set the initial route to GuestRequestScreen
      initialRoute: '/guestRequest',
      // Define routes for navigation
      routes: {
        '/guestRequest': (context) => GuestRequestScreen(),
        '/customRequest': (context) => CustomRequestScreen(),
        '/adminPanel': (context) => AdminPanel(),
      },
    );
  }
}
