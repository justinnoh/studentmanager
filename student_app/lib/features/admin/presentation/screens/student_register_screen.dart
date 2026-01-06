import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../providers/admin_provider.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/config/supabase_config.dart';

class StudentRegisterScreen extends ConsumerStatefulWidget {
  const StudentRegisterScreen({super.key});

  @override
  ConsumerState<StudentRegisterScreen> createState() => _StudentRegisterScreenState();
}

class _StudentRegisterScreenState extends ConsumerState<StudentRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = '남';
  bool _isLoading = false;

  // Email validation regex
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    
    AppLogger.info('Starting student registration for: $email', tag: 'Registration');
    
    try {
      // 1. Check if we have a valid session
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        AppLogger.error('No active session found. User might be logged out.', tag: 'Registration');
        throw Exception('관리자 세션이 만료되었습니다. 다시 로그인해주세요.');
      }
      
      AppLogger.debug('Invoking create-student function with current session...', tag: 'Registration');
      
      final response = await Supabase.instance.client.functions.invoke(
        'create-student',
        body: {
          'email': email,
          'password': password,
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'parent_name': _parentNameController.text.trim(),
          'parent_phone': _parentPhoneController.text.trim(),
          'age': int.tryParse(_ageController.text.trim()),
          'gender': _gender,
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data['error'] ?? '등록 처리 중 오류가 발생했습니다.';
        throw Exception(errorMsg);
      }

      AppLogger.info('Student registration completed successfully', tag: 'Registration');
      
      if (mounted) {
        ref.invalidate(studentListProvider);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('학생이 등록되었습니다.')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'Student registration failed',
        error: e,
        stackTrace: stackTrace,
        tag: 'Registration',
      );
      
      if (mounted) {
        String errorMessage = '등록 실패';
        final errorStr = e.toString().toLowerCase();
        
        if (errorStr.contains('already registered') || errorStr.contains('user already exists')) {
          errorMessage = '이미 등록된 이메일입니다.';
        } else if (errorStr.contains('weak_password')) {
          errorMessage = '비밀번호가 너무 약합니다. 6자 이상으로 설정해주세요.';
        } else {
          errorMessage = '등록 실패: ${e.toString().replaceAll('Exception:', '').trim()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('신규 학생 등록')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: '이메일 (ID)',
                        hintText: 'example@email.com',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return '이메일을 입력해주세요';
                        }
                        if (!_isValidEmail(value)) {
                          return '유효한 이메일 형식이 아닙니다 (예: name@email.com)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: '비밀번호'),
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6 ? '6자 이상 입력' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: '이름'),
                      validator: (value) => value == null || value.isEmpty ? '필수 입력' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(labelText: '폰번호'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _parentNameController,
                      decoration: const InputDecoration(labelText: '학부모 이름'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _parentPhoneController,
                      decoration: const InputDecoration(labelText: '학부모 폰번호'),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _ageController,
                            decoration: const InputDecoration(labelText: '나이'),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        DropdownButton<String>(
                          value: _gender,
                          items: ['남', '여']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                              .toList(),
                          onChanged: (val) => setState(() => _gender = val!),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _register,
                      child: const Text('등록하기'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
