// lib/screens/activity_log_screen.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../widgets/custom_input_field.dart';

class ActivityLogScreen extends StatefulWidget {
  final String personName;

  const ActivityLogScreen({
    super.key,
    required this.personName,
  });

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _thoughtsController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 기본 날짜 설정
    _dateController.text = '11/13';
    _activityController.text = '11/13';
    _thoughtsController.text = '11/13';
    _tagsController.text = '#오늘';
  }

  @override
  void dispose() {
    _dateController.dispose();
    _activityController.dispose();
    _thoughtsController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = '${picked.month}/${picked.day}';
      });
    }
  }

  void _saveActivityLog() {
    // TODO: 활동일지 저장 로직
    print('날짜: ${_dateController.text}');
    print('오늘의 활동: ${_activityController.text}');
    print('내 생각: ${_thoughtsController.text}');
    print('태그: ${_tagsController.text}');

    // 저장 후 이전 화면으로 돌아가기
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      size: 24,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    height: 40,
                    child: Image.asset(
                      'tokyo_diary_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),

            // 메인 콘텐츠
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
                  // 제목
                  Text(
                    '${widget.personName}님의\n오늘의 활동은 어땠나요?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: AppFonts.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 날짜 입력
                  CustomInputField(
                    label: '날짜',
                    placeholder: 'MM/DD',
                    controller: _dateController,
                    readOnly: true,
                    onTap: _selectDate,
                  ),

                  const SizedBox(height: 24),

                  // 오늘의 활동 입력
                  CustomInputField(
                    label: '오늘의 활동',
                    placeholder: '활동 내용을 입력하세요',
                    controller: _activityController,
                    maxLines: 5,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 24),

                  // 내 생각, 느낀 점 입력
                  CustomInputField(
                    label: '내 생각, 느낀 점',
                    placeholder: '생각이나 느낀 점을 입력하세요',
                    controller: _thoughtsController,
                    maxLines: 7,
                    maxLength: 1000,
                  ),

                  const SizedBox(height: 24),

                  // 태그 입력
                  CustomInputField(
                    label: '태그',
                    placeholder: '#태그를 입력하세요',
                    controller: _tagsController,
                    maxLines: 1,
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // 저장 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveActivityLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder()
                  ),
                  child: Text(
                    '오늘의 일기 추가',
                    style: TextStyle(
                      fontSize: AppFonts.bodyLarge,
                      fontWeight: AppFonts.semiBold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}