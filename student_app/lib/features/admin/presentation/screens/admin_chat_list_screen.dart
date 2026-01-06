import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'admin_chat_detail_screen.dart';

class AdminChatListScreen extends ConsumerWidget {
  const AdminChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('채팅 관리')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('chat_rooms')
            .stream(primaryKey: ['id'])
            .order('last_message_at', ascending: false),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rooms = snapshot.data!;
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return FutureBuilder<Map<String, dynamic>>(
                future: Supabase.instance.client
                    .from('users')
                    .select('name')
                    .eq('id', room['student_id'])
                    .single(),
                builder: (context, userSnapshot) {
                  final studentName = userSnapshot.data?['name'] ?? 'Loading...';
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(studentName),
                    subtitle: const Text('최근 메시지 내용...'),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminChatDetailScreen(
                          roomId: room['id'],
                          studentName: studentName,
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
