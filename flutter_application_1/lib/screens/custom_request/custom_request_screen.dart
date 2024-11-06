import 'package:flutter/material.dart';

class CustomRequestScreen extends StatelessWidget {
  const CustomRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4CB9D),
      appBar: AppBar(
        title: const Text(
          "TableServe",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFE4CB9D),
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: 4,
              color: Colors.teal.shade800,
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              "How can we help you?",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF316175),
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Colors.black26,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "describe your service request in detail.",
              style: TextStyle(fontSize: 16, color: Color(0xFF316175)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Text Input Field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const TextField(
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: "Type here...",
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Submit Request Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0), backgroundColor: const Color(0xFF316175),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                // Handle custom submit action
              },
              child: const Text("Submit Request", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
