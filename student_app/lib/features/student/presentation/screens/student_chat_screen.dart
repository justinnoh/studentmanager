import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/app_logger.dart';

class StudentChatScreen extends StatefulWidget {
  const StudentChatScreen({super.key});

  @override
  State<StudentChatScreen> createState() => _StudentChatScreenState();
}

class _StudentChatScreenState extends State<StudentChatScreen> {
  final _messageController = TextEditingController();
  String? _roomId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initChatRoom();
  }

  Future<void> _initChatRoom() async {
    final myId = Supabase.instance.client.auth.currentUser!.id;
    AppLogger.debug('Initializing chat room for student: $myId', tag: 'StudentChat');
    
    try {
      // 1. Check if room exists
      final roomResponse = await Supabase.instance.client
          .from('chat_rooms')
          .select('id')
          .eq('student_id', myId)
          .maybeSingle();
      
      if (roomResponse != null) {
        AppLogger.debug('Existing chat room found: ${roomResponse['id']}', tag: 'StudentChat');
        if (mounted) setState(() { _roomId = roomResponse['id']; _isLoading = false; });
      } else {
        AppLogger.debug('No existing room. Searching for an admin...', tag: 'StudentChat');
        // 2. Create room
        final adminResponse = await Supabase.instance.client
            .from('users')
            .select('id')
            .eq('role', 'admin')
            .limit(1)
            .maybeSingle();
        
        if (adminResponse != null) {
          AppLogger.debug('Admin found: ${adminResponse['id']}. Creating room...', tag: 'StudentChat');
          final newRoom = await Supabase.instance.client.from('chat_rooms').insert({
            'student_id': myId,
            'admin_id': adminResponse['id'],
          }).select('id').single();
          
          AppLogger.info('New chat room created: ${newRoom['id']}', tag: 'StudentChat');
          if (mounted) setState(() { _roomId = newRoom['id']; _isLoading = false; });
        } else {
          AppLogger.warning('No admin found to chat with.', tag: 'StudentChat');
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('상담 가능한 선생님이 없습니다. 관리자에게 문의하세요.')),
            );
          }
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to init chat room', error: e, stackTrace: stackTrace, tag: 'StudentChat');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _roomId == null) return;

    final myId = Supabase.instance.client.auth.currentUser!.id;
    await Supabase.instance.client.from('messages').insert({
      'room_id': _roomId,
      'sender_id': myId,
      'content': content,
    });
    
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_roomId == null) return const Scaffold(body: Center(child: Text('채팅방을 생성할 수 없습니다.')));

    return Scaffold(
      appBar: AppBar(title: const Text('선생님과 1:1 상담')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('room_id', _roomId!)
                  .order('created_at', ascending: false),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['sender_id'] == Supabase.instance.client.auth.currentUser!.id;
                    return _buildMessage(msg['content'], isMe);
                  },
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
                    controller: _messageController,
                    decoration: const InputDecoration(hintText: '선생님께 메시지 보내기...'),
                  ),
                ),
                IconButton(icon: const Icon(Icons.send), onPressed: _sendMessage),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String content, bool isMe) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isMe ? 64 : 16, 4, isMe ? 16 : 64, 4),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? Colors.indigo : Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            content,
            style: TextStyle(color: isMe ? Colors.white : Colors.black),
          ),
        ),
      ),
    );
  }
}
