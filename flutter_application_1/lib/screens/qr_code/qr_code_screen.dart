import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String tableId = ""; // Store the tableId here
  bool isScanning = false; // Prevent multiple scans

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<User?> _signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: '866243564535-05561go748lr38j905c8pmf1uufgl4nn.apps.googleusercontent.com', // Add your client ID here
    );
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      // The user canceled the sign-in
      return null;
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    return userCredential.user;
  }

  void _showAdminPanel() async {
    // User? user = FirebaseAuth.instance.currentUser;
    // user ??= await _signInWithGoogle();
     Navigator.pushNamed(context, '/adminPanel');
    // if (user != null) {
    //   Navigator.pushNamed(context, '/adminPanel');
    // } else {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text("Sign-in failed")),
    //   );
    // }
  }

  @override
  Widget build(BuildContext context) {
    double scanArea = MediaQuery.of(context).size.width * 0.7; // 70% of the screen width

    return Scaffold(
      appBar: AppBar(
        title: const Text("Scan Table QR Code"),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
          IconButton(
            icon: const Icon(Icons.admin_panel_settings),
            onPressed: _showAdminPanel,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Container(
                width: scanArea,
                height: scanArea,
                child: QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.red,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: scanArea,
                  ),
                ),
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Point the camera at the QR code',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("How to Use the QR Scanner"),
          content: const Text(
            "1. Point the camera at the QR code.\n"
            "2. Ensure the QR code is within the red borders.\n"
            "3. Wait for the scanner to detect the QR code.\n"
            "4. The table ID will be automatically processed.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    // Set up listener for QR code scan
    controller.scannedDataStream.listen((scanData) async {
      if (isScanning) return; // Prevent multiple scans

      setState(() {
        isScanning = true;
      });

      try {
        // Get tableId from scanned QR code
        String tableId = scanData.code ?? '';
        print("Scanned QR code: $tableId");

        // Ensure tableId is not empty
        if (tableId.isNotEmpty) {
          // Send data to Firebase
          await FirebaseFirestore.instance
              .collection('activeTables')
              .doc(tableId)
              .set({
            'status': 'active',
            'timestamp': Timestamp.now(),
          });

          // Show confirmation to user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$tableId marked as active')),
          );

          // Navigate to GuestRequestScreen and pass the tableId
          Navigator.pushReplacementNamed(
            context,
            '/guestRequest',
            arguments: tableId,  // Pass the tableId here
          );
        } else {
          // Show error if tableId is invalid
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid QR code')),
          );
        }
      } catch (e) {
        print("Error saving to Firebase: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error processing QR code')),
        );
      } finally {
        // Allow scanning again after a delay
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          isScanning = false;
        });
      }
    });
  }
}