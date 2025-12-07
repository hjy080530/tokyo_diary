import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';
import '../services/mongo_service.dart';
import '../widgets/custom_input_field.dart';
import '../widgets/link_type_dropdown.dart';

class EditPersonScreen extends StatefulWidget {
  final Map<String, dynamic> adoredPerson;

  const EditPersonScreen({super.key, required this.adoredPerson});

  @override
  State<EditPersonScreen> createState() => _EditPersonScreenState();
}

class _EditPersonScreenState extends State<EditPersonScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final List<LinkItem> _links = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.adoredPerson['name']?.toString());
    _descriptionController = TextEditingController(
      text: widget.adoredPerson['description']?.toString(),
    );
    final rawLinks = widget.adoredPerson['socialLinks'];
    if (rawLinks is List) {
      for (final link in rawLinks) {
        if (link is Map<String, dynamic>) {
          final typeKey = link['type']?.toString();
          final url = link['url']?.toString() ?? '';
          final type = LinkType.values.firstWhere(
            (t) => t.key == typeKey,
            orElse: () => LinkType.link,
          );
          _links.add(
            LinkItem(
              type: type,
              controller: TextEditingController(text: url),
            ),
          );
        }
      }
    }
    if (_links.isEmpty) {
      _links.add(
        LinkItem(
          type: LinkType.link,
          controller: TextEditingController(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    for (final link in _links) {
      link.controller.dispose();
    }
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
    if (_links.length <= 1) return;
    setState(() {
      _links[index].controller.dispose();
      _links.removeAt(index);
    });
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final id = widget.adoredPerson['_id'];
    if (id is! ObjectId) {
      _showMessage('잘못된 사용자 정보입니다.');
      return;
    }
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
            'type': link.type.key,
            'url': url,
          };
        })
        .whereType<Map<String, dynamic>>()
        .toList();

    setState(() => _isSaving = true);
    try {
      final ok = await mongoService.updateAdoredPerson(
        id: id,
        name: name,
        description: description,
        socialLinks: socialLinks,
      );
      if (!ok) {
        _showMessage('수정에 실패했습니다.');
        return;
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      _showMessage('수정 중 오류가 발생했습니다: $e');
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
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                children: [
              Text(
                '동경인물 정보 수정',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: AppFonts.bold,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 24),
              CustomInputField(
                label: '이름',
                placeholder: '이름을 입력하세요',
                controller: _nameController,
              ),
              const SizedBox(height: 24),
              CustomInputField(
                label: '대상의 특징',
                placeholder: '특징을 입력하세요',
                controller: _descriptionController,
                maxLines: 6,
                maxLength: 500,
              ),
              const SizedBox(height: 24),
              Text(
                '링크 추가',
                style: TextStyle(
                  fontSize: AppFonts.bodyMedium,
                  fontWeight: AppFonts.medium,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
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
                      shape: const RoundedRectangleBorder(),
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
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
                          '저장하기',
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

// 링크 입력 행 위젯 (add_person_screen과 동일 스타일)
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
            child: SizedBox(
              width: 40,
              height: 56,
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
