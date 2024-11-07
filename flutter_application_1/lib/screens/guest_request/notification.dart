import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationScreen extends StatelessWidget {
  final String tableId;

  const NotificationScreen({required this.tableId, super.key});

  @override
  Widget build(BuildContext context) {
    // Debug print to check the value of tableId
    print("NotificationScreen tableId: $tableId");

    return Scaffold(
      appBar: AppBar(title: const Text("Notifications")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('activeTables')
            .doc(tableId)
            .collection('messages')
            .orderBy('timestamp')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No notifications"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text(doc['message']),
                subtitle: Text(doc['sender']),
                trailing: doc['sender'] == 'admin'
                    ? IconButton(
                        icon: const Icon(Icons.reply, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MessageScreen(requestId: tableId),
                            ),
                          );
                        },
                      )
                    : null,
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class MessageScreen extends StatefulWidget {
  final String requestId;

  const MessageScreen({required this.requestId, super.key});

  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final TextEditingController _replyController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('activeTables')
                  .doc(widget.requestId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages"));
                }

                return ListView(
                  children: snapshot.data!.docs.map((doc) {
                    return ListTile(
                      title: Text(doc['message']),
                      subtitle: Text(doc['sender']),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      labelText: 'Reply',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendReply,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendReply() async {
    if (_replyController.text.isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('activeTables')
          .doc(widget.requestId)
          .collection('messages')
          .add({
        'message': _replyController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'user',
      });
      _replyController.clear();
    }
  }
}