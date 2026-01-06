import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/utils/app_logger.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    setState(() => _isLoading = true);
    AppLogger.debug('Starting login...', tag: 'Auth');
    try {
      AppLogger.debug('Calling signInWithPassword...', tag: 'Auth');
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      ).timeout(const Duration(seconds: 10));
      AppLogger.debug('signInWithPassword completed, user: ${response.user?.id}', tag: 'Auth');

      if (response.user != null && mounted) {
        AppLogger.debug('Fetching user role from database...', tag: 'Auth');
        final userData = await Supabase.instance.client
            .from('users')
            .select('role')
            .eq('id', response.user!.id)
            .single()
            .timeout(const Duration(seconds: 10));
        AppLogger.debug('Role fetched: ${userData['role']}', tag: 'Auth');
        
        final role = userData['role'] as String?;
        
        if (mounted) {
          final destination = role == 'admin' ? '/admin/dashboard' : '/student/home';
          AppLogger.info('Login successful, navigating to $destination', tag: 'Auth');
          context.go(destination);
        }
      }
    } on AuthException catch (e) {
      AppLogger.error('Auth Error', error: e, tag: 'Auth');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${e.message}')),
        );
      }
    } on TimeoutException catch (_) { 
      AppLogger.warning('Login timeout', tag: 'Auth');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('서버 응답 시간이 초과되었습니다. 인터넷 연결을 확인해주세요.')),
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('Login Error', error: e, stackTrace: stackTrace, tag: 'Auth');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('알 수 없는 에러가 발생했습니다.')),
        );
      }
    } finally {
      AppLogger.debug('Login cleanup', tag: 'Auth');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.school, size: 80, color: Color(0xFF3F51B5)),
            const SizedBox(height: 16),
            const Text(
              '학생 관리 시스템',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: '이메일'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: '비밀번호'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _signIn,
                    child: const Text('로그인'),
                  ),
          ],
        ),
      ),
    );
  }
}
