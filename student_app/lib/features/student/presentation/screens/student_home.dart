import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../auth/providers/auth_provider.dart';
import 'student_attendance_history_screen.dart';
import 'student_chat_screen.dart';
import 'student_profile_screen.dart';

class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const StudentHomeOverview(),
    const StudentAttendanceHistoryScreen(),
    const StudentChatScreen(),
    const StudentProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: '나의출결'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: '채팅'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '내정보'),
        ],
      ),
    );
  }
}

class StudentHomeOverview extends ConsumerStatefulWidget {
  const StudentHomeOverview({super.key});

  @override
  ConsumerState<StudentHomeOverview> createState() => _StudentHomeOverviewState();
}

class _StudentHomeOverviewState extends ConsumerState<StudentHomeOverview> {
  bool _isChecked = false;
  String _status = '미출석';

  @override
  void initState() {
    super.initState();
    _checkTodayAttendance();
  }

  Future<void> _checkTodayAttendance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final response = await Supabase.instance.client
        .from('attendance')
        .select('status')
        .eq('student_id', user.id)
        .eq('check_date', DateFormat('yyyy-MM-dd').format(DateTime.now()))
        .maybeSingle();
    
    if (mounted && response != null) {
      setState(() {
        _isChecked = true;
        _status = response['status'] == 'present' ? '출석' : (response['status'] == 'late' ? '지각' : '결석');
      });
    }
  }

  Future<void> _doCheckIn() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final checkTime = DateFormat('HH:mm:ss').format(now);
    
    // Logic: Before 09:00 present, 09:00~09:30 late, after that absent?
    // User requested: 09:00 이전 → 출석, 09:00~09:30 → 지각, 이후 → 결석
    String status = 'present';
    if (now.hour > 9 || (now.hour == 9 && now.minute > 30)) {
       status = 'absent';
    } else if (now.hour == 9 && now.minute > 0) {
       status = 'late';
    }

    try {
      await Supabase.instance.client.from('attendance').insert({
        'student_id': user.id,
        'check_date': DateFormat('yyyy-MM-dd').format(now),
        'status': status,
        'check_time': checkTime,
      });
      _checkTodayAttendance();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('출석체크 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('학생 홈'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Supabase.instance.client.auth.signOut(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('yyyy년 MM월 dd일').format(DateTime.now()),
              style: const TextStyle(fontSize: 20, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isChecked ? Colors.green[50] : Colors.blue[50],
              ),
              child: Icon(
                _isChecked ? Icons.check_circle : Icons.timer,
                size: 100,
                color: _isChecked ? Colors.green : Colors.blue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '오늘의 상태: $_status',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 48),
            _isChecked
                ? const Text('이미 출석체크를 완료했습니다.')
                : ElevatedButton(
                    onPressed: _doCheckIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    ),
                    child: const Text('출석체크 하기'),
                  ),
          ],
        ),
      ),
    );
  }
}
