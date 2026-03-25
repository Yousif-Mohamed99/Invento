import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class AdminTicketsScreen extends StatelessWidget {
  AdminTicketsScreen({super.key});

  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin & Support Dashboard"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.redAccent,
      ),
      body: Column(
        children: [
          // --- Search and Direct Activation Section ---
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Activate subscription by email...",
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _searchAndActivate(context),
                  icon: const Icon(Icons.person_add_alt_1),
                  style: IconButton.styleFrom(backgroundColor: Colors.purple),
                ),
              ],
            ),
          ),
          const Divider(),

          // --- Tickets List (Support Messages) ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('support_tickets')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No messages currently"));
                }

                final tickets = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: tickets.length,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  itemBuilder: (context, index) {
                    final data = tickets[index].data() as Map<String, dynamic>;
                    final String docId = tickets[index].id;
                    final String email = data['userEmail'] ?? "No Email";
                    final String message = data['message'] ?? "";
                    final Timestamp? timestamp = data['createdAt'];
                    final String status = data['status'] ?? "open";

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ExpansionTile(
                        leading: Icon(
                          status == "open"
                              ? Icons.mark_email_unread
                              : Icons.check_circle,
                          color:
                              status == "open" ? Colors.orange : Colors.green,
                        ),
                        title: Text(
                          email,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          timestamp != null
                              ? timeago.format(timestamp.toDate(), locale: 'en')
                              : "",
                          style: const TextStyle(fontSize: 12),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(15.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Message:",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 5),
                                Text(message),
                                const Divider(height: 30),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildActionButton(
                                      icon: Icons.email,
                                      color: Colors.blue,
                                      onPressed:
                                          () => _replyViaEmail(email, message),
                                    ),
                                    ElevatedButton(
                                      onPressed:
                                          () => _markAsResolved(docId, status),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            status == "open"
                                                ? Colors.green
                                                : Colors.grey,
                                      ),
                                      child: Text(
                                        status == "open"
                                            ? "Resolved"
                                            : "Reopen",
                                      ),
                                    ),
                                    _buildActionButton(
                                      icon: Icons.verified_user,
                                      color: Colors.purple,
                                      onPressed: () {
                                        final String? userId = data['userId'];
                                        if (userId != null) {
                                          _activateMerchantSubscription(
                                            context,
                                            userId,
                                            email,
                                          );
                                        }
                                      },
                                    ),
                                    _buildActionButton(
                                      icon: Icons.delete,
                                      color: Colors.red,
                                      onPressed:
                                          () => _deleteTicket(context, docId),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Helper Methods ---

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return IconButton(icon: Icon(icon, color: color), onPressed: onPressed);
  }

  Future<void> _searchAndActivate(BuildContext context) async {
    final email = _searchController.text.trim();
    if (email.isEmpty) return;

    try {
      // Find merchant by email in merchants collection
      final query =
          await FirebaseFirestore.instance
              .collection('merchants')
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      if (!context.mounted) return;
      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("This email is not registered as a merchant!")),
        );
        return;
      }

      final userId = query.docs.first.id;
      if (!context.mounted) return;
      // Call the activation function written earlier
      await _activateMerchantSubscription(context, userId, email);
      _searchController.clear();
    } catch (e) {
      debugPrint("Search Error: $e");
    }
  }

  Future<void> _activateMerchantSubscription(
    BuildContext context,
    String userId,
    String email,
  ) async {
    try {
      final expiryDate = DateTime.now().add(const Duration(days: 30));
      await FirebaseFirestore.instance
          .collection('merchants')
          .doc(userId)
          .update({
            'isSubscribed': true,
            'subscriptionEndDate': Timestamp.fromDate(expiryDate),
            'trialEndsAt': Timestamp.fromDate(DateTime.now()),
          });

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Subscription for $email activated successfully")));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Activation failed, check data")),
        );
      }
    }
  }

  Future<void> _markAsResolved(String docId, String currentStatus) async {
    final newStatus = currentStatus == "open" ? "resolved" : "open";
    await FirebaseFirestore.instance
        .collection('support_tickets')
        .doc(docId)
        .update({'status': newStatus});
  }

  Future<void> _deleteTicket(BuildContext context, String docId) async {
    await FirebaseFirestore.instance
        .collection('support_tickets')
        .doc(docId)
        .delete();
  }

  void _replyViaEmail(String email, String originalMessage) async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': 'Reply to your inquiry at Invento',
        'body': '\n\n--- Your original message ---\n$originalMessage',
      },
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    }
  }
}
