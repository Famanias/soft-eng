import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ScanScreen extends StatefulWidget {
  @override
  _ScanScreenState createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scan Table QR Code")),
      body: QRView(
        key: qrKey,
        onQRViewCreated: _onQRViewCreated,
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      // Assuming the QR code contains "table_1", "table_2", etc.
      String tableId = scanData.code!;

      // Send to Firebase
      await FirebaseFirestore.instance
          .collection('activeTables')
          .doc(tableId)
          .set({'status': 'active', 'timestamp': DateTime.now()});

      // Notify the user and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$tableId marked as active')),
      );
      Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
