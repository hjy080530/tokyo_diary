// lib/screens/add_person_screen.dart
import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/link_type_dropdown.dart';

class AddPersonScreen extends StatefulWidget {
  final ObjectId userId;

  const AddPersonScreen({super.key, required this.userId});

  @override
  State<AddPersonScreen> createState() => _AddPersonScreenState();
}

class _AddPersonScreenState extends State<AddPersonScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // 링크 목록 관리
  final List<LinkItem> _links = [
    LinkItem(
      type: LinkType.link,
      controller: TextEditingController(),
    ),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (var link in _links) {
      link.controller.dispose();
    }
    super.dispose();
  }

  void _addLink() {
    setState(() {
      _links.add(
        LinkItem(
          type: LinkType.link,
          controller: TextEditingController(),
        ),
      );
    });
  }

  void _removeLink(int index) {
    if (_links.length > 1) {
      setState(() {
        _links[index].controller.dispose();
        _links.removeAt(index);
      });
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _savePerson() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      _showMessage('이름을 입력해 주세요.');
      return;
    }

    final socialLinks = _links
        .map((link) {
          final url = link.controller.text.trim();
          if (url.isEmpty) return null;
          return {
            '_id': ObjectId(),
            'type': link.type.key,
            'url': url,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    setState(() => _isSaving = true);
    try {
      await mongoService.createAdoredPerson(
        userId: widget.userId,
        name: name,
        description: description,
        socialLinks: socialLinks,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('동경인물 추가에 실패했습니다: $e');
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
                      'assets/tokyo_diary_logo.png',
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
                    '당신의 동경대상은?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: AppFonts.bold,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // 이름 입력
                  CustomInputField(
                    label: '이름',
                    placeholder: '이름을 입력하세요',
                    controller: _nameController,
                  ),

                  const SizedBox(height: 24),

                  // 대상의 특징 입력
                  CustomInputField(
                    label: '대상의 특징',
                    placeholder: '특징을 입력하세요',
                    controller: _descriptionController,
                    maxLines: 6,
                    maxLength: 500,
                  ),

                  const SizedBox(height: 24),

                  // 링크 추가 섹션
                  Text(
                    '링크 추가',
                    style: TextStyle(
                      fontSize: AppFonts.bodyMedium,
                      fontWeight: AppFonts.medium,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // 링크 목록
                  ..._links.asMap().entries.map((entry) {
                    final index = entry.key;
                    final link = entry.value;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _LinkInputRow(
                        linkItem: link,
                        onTypeChanged: (newType) {
                          if (newType != null) {
                            setState(() {
                              link.type = newType;
                            });
                          }
                        },
                        onRemove: _links.length > 1
                            ? () => _removeLink(index)
                            : null,
                      ),
                    );
                  }).toList(),

                  // 링크 추가 버튼
                  Center(
                    child: SizedBox(
                      width: 150,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _addLink,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '링크 추가',
                              style: TextStyle(
                                fontSize: AppFonts.bodyMedium,
                                fontWeight: AppFonts.semiBold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white, width: 2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.add,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),

            // 동경인물 추가 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _savePerson,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                    ),
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
                          '동경인물 추가',
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

// 링크 데이터 모델
class LinkItem {
  LinkType type;
  TextEditingController controller;

  LinkItem({
    required this.type,
    required this.controller,
  });
}

// 링크 입력 행 위젯
class _LinkInputRow extends StatelessWidget {
  final LinkItem linkItem;
  final ValueChanged<LinkType?> onTypeChanged;
  final VoidCallback? onRemove;

  const _LinkInputRow({
    required this.linkItem,
    required this.onTypeChanged,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 드롭다운
        SizedBox(
          width: 140,
          child: LinkTypeDropdown(
            selectedType: linkItem.type,
            onChanged: onTypeChanged,
          ),
        ),

        const SizedBox(width: 12),

        // URL 입력 필드
        Expanded(
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.primary,
                width: 2,
              ),
            ),
            child: TextField(
              controller: linkItem.controller,
              style: TextStyle(
                fontSize: AppFonts.bodyMedium,
                fontWeight: AppFonts.regular,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'https://',
                hintStyle: TextStyle(
                  fontSize: AppFonts.bodyMedium,
                  fontWeight: AppFonts.regular,
                  color: AppColors.textSecondary.withOpacity(0.5),
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),

        // 삭제 버튼 (2개 이상일 때만 표시)
        if (onRemove != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 40,
              height: 56,
              decoration: BoxDecoration(),
              child: const Icon(
                Icons.close,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
