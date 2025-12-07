// lib/widgets/link_type_dropdown.dart
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/fonts.dart';

enum LinkType {
  instagram('인스타그램', 'assets/icons/instagram_icon.png'),
  github('깃허브', 'assets/icons/github_icon.png'),
  velog('벨로그', 'assets/icons/velog_logo.jpg'),
  link('링크', 'assets/icons/link_icon.png');

  const LinkType(this.displayName, this.iconPath);
  final String displayName;
  final String iconPath;
}

extension LinkTypeKey on LinkType {
  String get key {
    switch (this) {
      case LinkType.instagram:
        return 'instagram';
      case LinkType.github:
        return 'github';
      case LinkType.velog:
        return 'velog';
      case LinkType.link:
        return 'link';
    }
  }
}

class LinkTypeDropdown extends StatelessWidget {
  final LinkType selectedType;
  final ValueChanged<LinkType?> onChanged;

  const LinkTypeDropdown({
    super.key,
    required this.selectedType,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<LinkType>(
          value: selectedType,
          isExpanded: true,
          icon: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.primary,
          ),
          style: TextStyle(
            fontSize: AppFonts.bodyMedium,
            fontWeight: AppFonts.regular,
            color: AppColors.textPrimary,
          ),
          items: LinkType.values.map((LinkType type) {
            return DropdownMenuItem<LinkType>(
              value: type,
              child: Row(
                children: [
                  Image.asset(
                    type.iconPath,
                    width: 24,
                    height: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(type.displayName),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
