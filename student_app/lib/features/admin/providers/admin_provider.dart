import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/student_model.dart';
import '../../../core/utils/app_logger.dart';

final studentListProvider = FutureProvider<List<StudentModel>>((ref) async {
  try {
    AppLogger.debug('Fetching student list...', tag: 'StudentProvider');
    final response = await Supabase.instance.client
        .from('users')
        .select()
        .eq('role', 'student')
        .order('name');
    
    final students = (response as List).map((json) => StudentModel.fromJson(json)).toList();
    AppLogger.info('Loaded ${students.length} students', tag: 'StudentProvider');
    return students;
  } catch (e, stackTrace) {
    AppLogger.error('Failed to load students', error: e, stackTrace: stackTrace, tag: 'StudentProvider');
    rethrow;
  }
});

// Dashboard statistics model
class DashboardStats {
  final double attendanceRate;
  final int absentStudentsCount;
  final int unreadMessagesCount;

  DashboardStats({
    required this.attendanceRate,
    required this.absentStudentsCount,
    required this.unreadMessagesCount,
  });
}

// Provider to fetch dashboard statistics
final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  try {
    AppLogger.debug('Fetching dashboard stats...', tag: 'Dashboard');
    
    final supabase = Supabase.instance.client;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    // Get total student count
    final studentsResponse = await supabase
        .from('users')
        .select('id')
        .eq('role', 'student');
    final totalStudents = (studentsResponse as List).length;
    AppLogger.debug('Total students: $totalStudents', tag: 'Dashboard');

    // Get today's attendance records
    final attendanceResponse = await supabase
        .from('attendance')
        .select('student_id, status')
        .eq('check_date', todayStr);
    
    final attendanceRecords = attendanceResponse as List;
    final presentCount = attendanceRecords.where((r) => r['status'] == 'present').length;
    final absentCount = attendanceRecords.where((r) => r['status'] == 'absent').length;
    AppLogger.debug('Attendance: present=$presentCount, absent=$absentCount', tag: 'Dashboard');
    
    // Calculate attendance rate
    final attendanceRate = totalStudents > 0 
        ? (presentCount / totalStudents * 100) 
        : 0.0;

    // Get unread messages count by checking last message in each chat room
    final chatRoomsResponse = await supabase
        .from('chat_rooms')
        .select('id')
        .eq('admin_id', supabase.auth.currentUser!.id);
    
    final rooms = chatRoomsResponse as List;
    int unreadCount = 0;
    
    for (var room in rooms) {
      // Get the last message in each room
      final lastMessage = await supabase
          .from('messages')
          .select('sender_id')
          .eq('room_id', room['id'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      // If last message is from student (not admin), count as unread
      if (lastMessage != null && 
          lastMessage['sender_id'] != supabase.auth.currentUser!.id) {
        unreadCount++;
      }
    }
    
    AppLogger.info('Dashboard stats loaded: rate=${attendanceRate.toStringAsFixed(1)}%, absent=$absentCount, unread=$unreadCount', tag: 'Dashboard');

    return DashboardStats(
      attendanceRate: attendanceRate,
      absentStudentsCount: absentCount,
      unreadMessagesCount: unreadCount,
    );
  } catch (e, stackTrace) {
    AppLogger.error('Failed to load dashboard stats', error: e, stackTrace: stackTrace, tag: 'Dashboard');
    rethrow;
  }
});

