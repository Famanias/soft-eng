import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  void _showAdminPanel() {
    Navigator.pushNamed(context, '/adminPanel');
  }

  @override
  Widget build(BuildContext context) {
    double scanArea = MediaQuery.of(context).size.width * 0.75; // 75% of the screen width

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
              child: SizedBox(
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

  Future<String?> _promptForName() async {
    TextEditingController nameController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Your Name"),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(nameController.text);
              },
              child: const Text("OK"),
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
        String? userName = await _promptForName();
        if (userName == null || userName.isEmpty) {
          userName = "Guest";
        }
        // Send data to Firebase
        await FirebaseFirestore.instance
            .collection('activeTables')
            .doc(tableId)
            .set({
          'status': 'active',
          'timestamp': Timestamp.now(),
          'userName': userName,
        });

        // Show confirmation to user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$tableId marked as active')),
        );

        // Navigate to GuestRequestScreen and pass the tableId and userName
        Navigator.pushReplacementNamed(
          context,
          '/guestRequest',
          arguments: {'tableId': tableId, 'userName': userName},  // Pass the tableId and userName here
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