import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminMessagesScreen extends StatelessWidget {
  final String tableId;
  final String userName;

  const AdminMessagesScreen({required this.tableId, required this.userName, super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController messageController = TextEditingController();

    void sendMessage() async {
      if (messageController.text.isNotEmpty) {
        String docName = 'Admin Message - ${DateTime.now()}';
        await FirebaseFirestore.instance
            .collection('guestRequests')
            .doc(tableId)
            .collection('messages')
            .doc(docName)
            .set({
          'message': messageController.text,
          'timestamp': FieldValue.serverTimestamp(),
          'sender': 'admin',
        });
        messageController.clear();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(userName), // Set the title to the user's name
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('guestRequests')
                  .doc(tableId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages"));
                }

                return ListView(
                  reverse: true, // Reverse the order of the messages
                  children: snapshot.data!.docs.map((doc) {
                    var message = doc.data() as Map<String, dynamic>;
                    bool isAdmin = message['sender'] == 'admin';
                    Timestamp? timestamp = message['timestamp'] as Timestamp?;
                    return Column(
                      crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 5),
                        Align(
                          alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                            padding: const EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: isAdmin ? Colors.blue[100] : Colors.grey[300],
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message['message'],
                                  style: TextStyle(
                                    color: isAdmin ? Colors.black : Colors.black,
                                  ),
                                ),
                                if (timestamp != null)
                                  Text(
                                    timestamp.toDate().toString(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: messageController,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text("Close"),
                ),
                TextButton(
                  onPressed: () {
                    sendMessage();
                  },
                  child: const Text("Send"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}