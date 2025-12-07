// lib/screens/sign_up_screen.dart
import 'package:flutter/material.dart';

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../widgets/custom_input_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('모든 필드를 입력해 주세요.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('비밀번호가 일치하지 않습니다.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await mongoService.createUser(
        name: name,
        email: email,
        password: password,
      );

      if (result == null) {
        _showMessage('이미 가입된 이메일입니다.');
        return;
      }

      _showMessage('회원가입이 완료되었습니다. 로그인해 주세요.');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('회원가입 오류: $e');
      _showMessage('회원가입에 실패했습니다: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '회원가입',
          style: TextStyle(
            fontSize: AppFonts.bodyLarge,
            fontWeight: AppFonts.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomInputField(
                label: '이름',
                controller: _nameController,
                placeholder: '이름을 입력해 주세요',
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: '이메일',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                placeholder: '이메일을 입력해주세요.',
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: '비밀번호',
                controller: _passwordController,
                placeholder: '비밀번호를 입력해 주세요',
                obscureText: true,
              ),
              const SizedBox(height: 16),
              CustomInputField(
                label: '비밀번호 확인',
                controller: _confirmPasswordController,
                placeholder: '비밀번호를 다시 입력해 주세요',
                obscureText: true,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
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
                          '회원가입 완료',
                          style: TextStyle(
                            fontSize: AppFonts.bodyMedium,
                            fontWeight: AppFonts.semiBold,
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
