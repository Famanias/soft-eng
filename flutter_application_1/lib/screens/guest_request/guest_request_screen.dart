import 'package:flutter/material.dart';


class GuestRequestScreen extends StatefulWidget {
  const GuestRequestScreen({super.key});

  @override
  _GuestRequestScreenState createState() => _GuestRequestScreenState();
}

class _GuestRequestScreenState extends State<GuestRequestScreen> {
  List<bool> selectedItems = List.generate(5, (index) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4CB9D), // Background color
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
        backgroundColor: const Color(0xFFE4CB9D), // Background color to match
        elevation: 0, // Remove shadow
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
            Text(
              "Guest Request",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF316175),
                shadows: const [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              "Common requests of guests, can select multiple.",
              style: TextStyle(fontSize: 16, color: Color(0xFF316175)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 15),

            // Multi-select Options List
            Expanded(
              child: ListView.builder(
                itemCount: selectedItems.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedItems[index] = !selectedItems[index];
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: selectedItems[index] ? const Color(0xFF316175) : Colors.white,
                        borderRadius: BorderRadius.circular(30.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: selectedItems[index] ? Colors.white : Color(0xFF316175)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Lorem Ipsum Request",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: selectedItems[index] ? Colors.white : Colors.teal,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            


            // Submit Request Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0), backgroundColor: const Color(0xFF316175), // Button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                // Handle submit action
              },
              child: const Text("Submit Request", style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 10),

            // Custom Request Button
            ElevatedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF316175), padding: const EdgeInsets.fromLTRB(20.0, 15.0, 20.0, 15.0), backgroundColor: Colors.white,
                side: null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
              ),
              onPressed: () {
                // Handle custom request action
                Navigator.pushNamed(context, '/customRequest');
              },
              child: const Text("Custom Request", style: TextStyle(fontSize: 18)),
            ),

            ElevatedButton(
              onPressed: () {
                String username = 'dave';
                String password = '123';
                
                if (username == 'dave' && password == '123') {
                  Navigator.pushNamed(context, '/adminPanel');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Invalid credentials')),
                  );
                }
              },
              child: Text("Go to Admin Panel"),
            )
          ],
        ),
      ),
    );
  }
}