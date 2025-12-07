// lib/screens/login_screen.dart
import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../widgets/custom_input_field.dart';
import 'main_screen.dart';
import 'sign_up_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('이메일과 비밀번호를 입력해 주세요.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = await mongoService.loginWithEmail(email, password);
      if (user == null) {
        _showMessage('이메일 또는 비밀번호가 올바르지 않습니다.');
        return;
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(user: user),
        ),
      );
    } catch (e) {
      debugPrint('로그인 오류: $e');
      _showMessage('로그인 중 오류: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              Text(
                '懂慌日誌',
                style: AppFonts.titleStyle,
              ),
              const SizedBox(height: 40),
              CustomInputField(
                label: '이메일',
                controller: _emailController,
                placeholder: '이메일을 입력해주세요.',
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: '비밀번호',
                controller: _passwordController,
                placeholder: '비밀번호를 입력해 주세요',
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          '로그인',
                          style: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            fontWeight: AppFonts.semiBold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SignUpScreen(),
                      ),
                    );
                  },
                  child: Text(
                    '계정이 없으신가요? 회원가입',
                    style: TextStyle(
                      fontSize: AppFonts.bodySmall,
                      fontWeight: AppFonts.medium,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
