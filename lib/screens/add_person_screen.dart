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
  static const String _disclaimerText =
      '동경일기는 공개된 정보를 기반으로 개인의 학습과 성장을 돕기 위한 개인 일지 애플리케이션입니다. 본 서비스는 타인을 추적하거나 감시하는 목적으로 설계되지 않았으며 그러한 용도로 사용되어서는 안 됩니다.\n'
      '사용자는 공개적으로 접근 가능한 정보만을 기록해야 하며, 기록된 모든 정보와 그 사용에 대한 법적, 윤리적 책임은 전적으로 사용자에게 있습니다. 관찰 대상자의 사생활, 초상권, 저작권 등 모든 권리를 존중해야 하며, 관찰 대상자에게 불편함이나 피해를 주는 행위는 금지됩니다. 본 애플리케이션은 스토킹, 사이버불링, 개인정보 불법 수집, 명예훼손, 저작권 침해 등 법령을 위반하는 목적으로 사용될 수 없습니다.\n'
      '개발자는 사용자가 기록한 콘텐츠 및 사용자의 부적절한 사용으로 인한 법적 분쟁이나 손해에 대해 어떠한 책임도 지지 않습니다. 사용자는 본 서비스를 이용함으로써 위의 모든 조항을 이해하고 동의한 것으로 간주되며, 윤리적이고 합법적인 방식으로만 서비스를 사용할 책임이 있습니다.';

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
  bool _consentAccepted = false;

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

  Future<bool?> _showConsentDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text(
            '주의 문구',
            style: TextStyle(
              fontSize: AppFonts.bodyLarge,
              fontWeight: AppFonts.bold,
              color: AppColors.textPrimary,
            ),
          ),
          content: SingleChildScrollView(
            child: Text(
              _disclaimerText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: AppFonts.regular,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                '취소',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFonts.bodyMedium,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero,
                ),
              ),
              child: Text(
                '확인',
                style: TextStyle(
                  fontSize: AppFonts.bodyMedium,
                  fontWeight: AppFonts.semiBold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSaveTap() async {
    if (_isSaving) return;
    if (!_consentAccepted) {
      final confirmed = await _showConsentDialog();
      if (confirmed != true) return;
      if (!mounted) return;
      setState(() => _consentAccepted = true);
    }
    await _savePerson();
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
                  }),

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
                  onPressed: _isSaving ? null : _handleSaveTap,
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
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
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
