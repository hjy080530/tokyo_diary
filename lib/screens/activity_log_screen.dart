// lib/screens/activity_log_screen.dart
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../widgets/custom_input_field.dart';

class ActivityLogScreen extends StatefulWidget {
  final String personName;
  final ObjectId adoredPersonId;
  final ObjectId userId;

  const ActivityLogScreen({
    super.key,
    required this.personName,
    required this.adoredPersonId,
    required this.userId,
  });

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _activityController = TextEditingController();
  final TextEditingController _thoughtsController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dateController.text = _formatDate(_selectedDate);
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
      initialDate: _selectedDate,
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
        _selectedDate = picked;
        _dateController.text = _formatDate(_selectedDate);
      });
    }
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  List<String> _parseTags(String input) {
    return input
        .split(RegExp(r'[ ,#]+'))
        .where((tag) => tag.trim().isNotEmpty)
        .map((tag) => '#$tag')
        .toList();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _saveActivityLog() async {
    final activity = _activityController.text.trim();
    final thoughts = _thoughtsController.text.trim();
    final tags = _parseTags(_tagsController.text.trim());

    if (activity.isEmpty || thoughts.isEmpty) {
      _showMessage('활동과 생각을 모두 입력해 주세요.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await mongoService.createObservationLog(
        userId: widget.userId,
        adoredPersonId: widget.adoredPersonId,
        date: _selectedDate,
        activity: activity,
        thoughts: thoughts,
        tags: tags,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('저장 실패: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
                  onPressed: _isSaving ? null : _saveActivityLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder()
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(
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
