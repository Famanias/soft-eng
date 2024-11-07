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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Scan Table QR Code")),
      body: Column(
        children: [
          Expanded(
            flex: 0,
            child: LayoutBuilder(
              builder: (context, constraints) {
                double width = MediaQuery.of(context).size.width * 0.3; // 80% of the screen width
                double height = MediaQuery.of(context).size.height * 0.3; // 80% of the screen height

                return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: QRView(
                    key: qrKey,
                    onQRViewCreated: _onQRViewCreated,
                  ),
                ),
              );
              },
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

