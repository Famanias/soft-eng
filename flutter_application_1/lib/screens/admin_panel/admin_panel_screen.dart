import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('activeTables').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active tables"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text("Table ID: ${doc.id}"),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RequestDetailsScreen(tableId: doc.id),
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class RequestDetailsScreen extends StatefulWidget {
  final String tableId;

  const RequestDetailsScreen({required this.tableId, super.key});

  @override
  _RequestDetailsScreenState createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Request Details")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('guestRequests')
            .where('tableId', isEqualTo: widget.tableId)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No requests for this table"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var requestType = doc['requestType'];
              String requestTypeText;
              if (requestType is List) {
                requestTypeText = requestType.join(', ');
              } else {
                requestTypeText = requestType.toString();
              }

              return ListTile(
                title: Text("Request: $requestTypeText"),
                subtitle: Text("Status: ${doc['status']}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check, color: Colors.green),
                      onPressed: () => _updateRequestStatus(doc.id, 'accepted'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _updateRequestStatus(doc.id, 'rejected'),
                    ),
                    IconButton(
                      icon: const Icon(Icons.message, color: Colors.blue),
                      onPressed: () => _showMessageDialog(doc.id, requestTypeText),
                    ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'Send a message',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send),
              onPressed: _sendComment,
            ),
          ],
        ),
      ),
    );
  }

  void _updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('guestRequests')
        .doc(requestId)
        .update({'status': status});
  }

  void _sendComment() async {
  if (_commentController.text.isNotEmpty) {
    
    String docName = '${widget.tableId} - Message';
    await FirebaseFirestore.instance
        .collection('activeTables')
        .doc(widget.tableId)
        .collection('messages')
        .doc(docName)
        .set({
      'message': _commentController.text,
      'timestamp': FieldValue.serverTimestamp(),
      'sender': 'admin',
    });
    _commentController.clear();
  }
}

  void _showMessageDialog(String requestId, String requestType) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Send Message"),
        content: TextField(
          controller: _messageController,
          decoration: const InputDecoration(
            labelText: 'Message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              _sendMessage(requestId, requestType);
              Navigator.of(context).pop();
            },
            child: const Text("Send"),
          ),
        ],
      );
    },
  );
}

  void _sendMessage(String requestId, String requestType) async {
    if (_messageController.text.isNotEmpty) {

      String docName = '${widget.tableId} Request Message - ${DateTime.now()}';
      await FirebaseFirestore.instance
          .collection('guestRequests')
          .doc(requestId)
          .collection('messages')
          .doc(docName)
          .set({
        'tableId': widget.tableId,
        'requestType': requestType,
        'message': _messageController.text,
        'timestamp': FieldValue.serverTimestamp(),
        'sender': 'admin',
      });
      _messageController.clear();
    }
  }
}