import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'admin_message.dart';

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
            return const Center(
              child: CircularProgressIndicator(),
          );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No active tables"));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              return ListTile(
                title: Text("${doc.id}"),
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
  
  String userName = "Guest";

   @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('activeTables')
        .doc(widget.tableId)
        .get();

    setState(() {
      userName = doc['userName'] ?? "Guest";
    });
  }

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
              var data = doc.data() as Map<String, dynamic>;
              var requestType = doc['requestType'];
              String requestTypeText;
              if (requestType is List) {
                requestTypeText = requestType.join(', ');
              } else {
                requestTypeText = requestType.toString();
              }

               userName = data['userName'] ?? "Guest";


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
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showMessagesScreen(userName),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.message),
      ),
      
    );
  }

  void _updateRequestStatus(String requestId, String status) async {
    await FirebaseFirestore.instance
        .collection('guestRequests')
        .doc(requestId)
        .update({'status': status});
  }

  void _showMessagesScreen(String userName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminMessagesScreen(tableId: widget.tableId, userName: userName),
      ),
    );
  }

  // void _showMessagesPopup() {
  //   showDialog(
  //     context: context,
  //     builder: (context) {
  //       return AlertDialog(
  //         title: const Text("Messages"),
  //         content: SizedBox(
  //           width: double.maxFinite,
  //           child: StreamBuilder(
  //             stream: FirebaseFirestore.instance
  //                 .collection('guestRequests')
  //                 .doc(widget.tableId)
  //                 .collection('messages')
  //                 .orderBy('timestamp', descending: true)
  //                 .snapshots(),
  //             builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
  //               if (snapshot.connectionState == ConnectionState.waiting) {
  //                 return const Center(child: CircularProgressIndicator());
  //               }
  //               if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //                 return const Center(child: Text("No messages"));
  //               }

  //               return ListView(
  //                 reverse: true,
  //                 children: snapshot.data!.docs.map((doc) {
  //                   var message = doc.data() as Map<String, dynamic>;
  //                   bool isAdmin = message['sender'] == 'admin';
  //                   Timestamp? timestamp = message['timestamp'] as Timestamp?;
  //                   return Align(
  //                     alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
  //                     child: Container(
  //                       margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
  //                       padding: const EdgeInsets.all(10.0),
  //                       decoration: BoxDecoration(
  //                         color: isAdmin ? Colors.blue[100] : Colors.grey[300],
  //                         borderRadius: BorderRadius.circular(10.0),
  //                       ),
  //                       child: Column(
  //                         crossAxisAlignment: CrossAxisAlignment.start,
  //                         children: [
  //                           Text(
  //                             message['message'],
  //                             style: TextStyle(
  //                               color: isAdmin ? Colors.black : Colors.black,
  //                             ),
  //                           ),
  //                           if (timestamp != null)
  //                             Text(
  //                               timestamp.toDate().toString(),
  //                               style: const TextStyle(
  //                                 fontSize: 10,
  //                                 color: Colors.black54,
  //                               ),
  //                             ),
  //                         ],
  //                       ),
  //                     ),
  //                   );
  //                 }).toList(),
  //               );
  //             },
  //           ),
  //         ),
  //         actions: [
  //           TextField(
  //             controller: _messageController,
  //             decoration: const InputDecoration(
  //               labelText: 'Message',
  //               border: OutlineInputBorder(),
  //             ),
  //           ),
  //         Container(
  //           margin: const EdgeInsets.only(top: 16.0), // Add margin at the top
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.end,
  //             children: [
  //               TextButton(
  //                 onPressed: () {
  //                   Navigator.of(context).pop();
  //                 },
  //                 child: const Text("Close"),
  //               ),
  //               TextButton(
  //                 onPressed: () {
  //                   _sendMessage(widget.tableId, ''); // Pass the required arguments here
  //                 },
  //                 child: const Text("Send"),
  //               ),
  //             ],
  //           ),
  //         ),
  //         ],
  //       );
  //     },
  //   );
  // }


}