import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';

class AttendanceManagementScreen extends ConsumerStatefulWidget {
  const AttendanceManagementScreen({super.key});

  @override
  ConsumerState<AttendanceManagementScreen> createState() => _AttendanceManagementScreenState();
}

class _AttendanceManagementScreenState extends ConsumerState<AttendanceManagementScreen> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _updateAttendance(String studentId, String status) async {
    try {
      await Supabase.instance.client.from('attendance').upsert({
        'student_id': studentId,
        'check_date': DateFormat('yyyy-MM-dd').format(_selectedDate),
        'status': status,
        'check_time': DateFormat('HH:mm:ss').format(DateTime.now()),
      }, onConflict: 'student_id,check_date');
      
      if (mounted) {
        setState(() {}); // Refresh list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('출결 상태가 업데이트되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('업데이트 실패: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('출결 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              DateFormat('yyyy년 MM월 dd일').format(_selectedDate),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: studentsAsync.when(
              data: (students) => ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  return AttendanceTile(
                    student: student,
                    date: _selectedDate,
                    onStatusChanged: (status) => _updateAttendance(student.id, status),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('오류 발생: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class AttendanceTile extends StatefulWidget {
  final dynamic student;
  final DateTime date;
  final Function(String) onStatusChanged;

  const AttendanceTile({
    super.key,
    required this.student,
    required this.date,
    required this.onStatusChanged,
  });

  @override
  State<AttendanceTile> createState() => _AttendanceTileState();
}

class _AttendanceTileState extends State<AttendanceTile> {
  String? _status;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  @override
  void didUpdateWidget(AttendanceTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.date != widget.date) _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final response = await Supabase.instance.client
        .from('attendance')
        .select('status')
        .eq('student_id', widget.student.id)
        .eq('check_date', DateFormat('yyyy-MM-dd').format(widget.date))
        .maybeSingle();
    
    if (mounted) {
      setState(() => _status = response?['status']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(widget.student.name),
      subtitle: Text(_status ?? '기록 없음'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusChip('present', '출석', Colors.green),
          const SizedBox(width: 4),
          _buildStatusChip('late', '지각', Colors.orange),
          const SizedBox(width: 4),
          _buildStatusChip('absent', '결석', Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label, Color color) {
    final isSelected = _status == status;
    return GestureDetector(
      onTap: () async {
        await widget.onStatusChanged(status);
        _fetchStatus();
      },
      child: Chip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : color, fontSize: 12)),
        backgroundColor: isSelected ? color : Colors.white,
        side: BorderSide(color: color),
      ),
    );
  }
}
