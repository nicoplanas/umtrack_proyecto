import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/views/chats_page.dart';
import 'package:intl/intl.dart';

void showMessagesPopup(BuildContext context) async {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null) return;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Conversaciones Recientes",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('chats')
                      .where('users', arrayContains: currentUser.uid)
                      .orderBy('lastTimestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text("Aún no has iniciado ninguna conversación."),
                      );
                    }

                    final chats = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        final users = List<String>.from(chat['users']);
                        final otherUserId = users.firstWhere((id) => id != currentUser.uid);

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('usuarios').doc(otherUserId).get(),
                          builder: (context, userSnapshot) {
                            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                              return const SizedBox();
                            }

                            final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                            final fullName = userData['fullName'] ?? 'Sin nombre';
                            final initials = fullName.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
                            final lastMessage = chat['lastMessage'] ?? '';
                            final timestamp = (chat['lastTimestamp'] as Timestamp?)?.toDate();
                            final timeAgo = timestamp != null ? _formatTimeAgo(timestamp) : '';

                            return StatefulBuilder(
                              builder: (context, setState) {
                                bool isHovered = false;

                                return MouseRegion(
                                  onEnter: (_) => setState(() => isHovered = true),
                                  onExit: (_) => setState(() => isHovered = false),
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () async {
                                      Navigator.of(context).pop(); // Cierra el popup
                                      await Future.delayed(const Duration(milliseconds: 150));
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ChatsPage(
                                            studentId: otherUserId,
                                            studentName: fullName,
                                          ),
                                        ),
                                      );
                                    },
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isHovered ? const Color(0xFFFD8305) : Colors.transparent,
                                          width: 1.5,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          CircleAvatar(
                                            radius: 24,
                                            backgroundColor: Colors.primaries[index % Colors.primaries.length],
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      fullName,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    Text(
                                                      timeAgo,
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  lastMessage,
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: const BoxDecoration(
                                              color: Colors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Text(
                                              '1',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cerrar"),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _formatTimeAgo(DateTime dateTime) {
  final duration = DateTime.now().difference(dateTime);
  if (duration.inMinutes < 1) return 'ahora';
  if (duration.inMinutes < 60) return '${duration.inMinutes} min';
  if (duration.inHours < 24) return '${duration.inHours}h';
  return DateFormat('dd/MM').format(dateTime);
}
