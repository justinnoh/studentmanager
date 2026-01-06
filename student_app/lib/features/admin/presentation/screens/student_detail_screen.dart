import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/student_model.dart';
import '../../providers/admin_provider.dart';
import '../../../../core/utils/app_logger.dart';

class StudentDetailScreen extends ConsumerStatefulWidget {
  final StudentModel student;

  const StudentDetailScreen({super.key, required this.student});

  @override
  ConsumerState<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends ConsumerState<StudentDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _parentNameController;
  late TextEditingController _parentPhoneController;
  late TextEditingController _ageController;
  late String _gender;
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.student.name);
    _phoneController = TextEditingController(text: widget.student.phone);
    _parentNameController = TextEditingController(text: widget.student.parentName);
    _parentPhoneController = TextEditingController(text: widget.student.parentPhone);
    _ageController = TextEditingController(text: widget.student.age?.toString() ?? '');
    _gender = widget.student.gender ?? '남';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    AppLogger.info('Updating student profile: ${widget.student.email}', tag: 'AdminAction');

    try {
      await Supabase.instance.client.from('users').update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'parent_name': _parentNameController.text.trim(),
        'parent_phone': _parentPhoneController.text.trim(),
        'age': int.tryParse(_ageController.text.trim()),
        'gender': _gender,
      }).eq('id', widget.student.id);

      AppLogger.info('Student profile updated successfully', tag: 'AdminAction');
      
      if (mounted) {
        ref.invalidate(studentListProvider);
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학생 정보가 수정되었습니다.')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to update student profile', error: e, stackTrace: stackTrace, tag: 'AdminAction');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('수정 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '학생 정보 수정' : '학생 상세 정보'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoSection('기본 정보', [
                      _buildInfoField('이메일', widget.student.email, enabled: false),
                      const SizedBox(height: 16),
                      _buildTextField('이름', _nameController, enabled: _isEditing),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoSection('연락처', [
                      _buildTextField('폰번호', _phoneController, enabled: _isEditing, keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),
                      _buildTextField('학부모 이름', _parentNameController, enabled: _isEditing),
                      const SizedBox(height: 16),
                      _buildTextField('학부모 폰번호', _parentPhoneController, enabled: _isEditing, keyboardType: TextInputType.phone),
                    ]),
                    const SizedBox(height: 24),
                    _buildInfoSection('기타 정보', [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField('나이', _ageController, enabled: _isEditing, keyboardType: TextInputType.number),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('성별', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                DropdownButton<String>(
                                  value: _gender,
                                  isExpanded: true,
                                  onChanged: _isEditing ? (val) => setState(() => _gender = val!) : null,
                                  items: ['남', '여']
                                      .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ]),
                    if (_isEditing) ...[
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _updateStudent,
                          child: const Text('저장하기'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF3F51B5))),
        const Divider(),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  Widget _buildInfoField(String label, String value, {bool enabled = true}) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(labelText: label, filled: !enabled, fillColor: enabled ? null : Colors.grey[200]),
      enabled: false,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool enabled = true, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: enabled ? const OutlineInputBorder() : InputBorder.none),
      enabled: enabled,
      keyboardType: keyboardType,
      validator: (value) => (enabled && (value == null || value.isEmpty)) ? '필수 입력' : null,
    );
  }
}
