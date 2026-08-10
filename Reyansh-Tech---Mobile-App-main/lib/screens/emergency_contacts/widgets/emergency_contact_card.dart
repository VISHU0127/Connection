import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_dimensions.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_avatar_circle.dart';
import '../models/emergency_contact.dart';

class EmergencyContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onDelete;

  const EmergencyContactCard({
    super.key,
    required this.contact,
    required this.onDelete,
  });

  Color _relationColor(String relation) {
    switch (relation.toLowerCase()) {
      case 'father':
        return AppColors.warning;
      case 'mother':
        return AppColors.accent;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _relationColor(contact.relation);
    final dim = AppDimensions(context);

    return AppCard(
      color: AppColors.cardColor,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 6),
      child: Row(
        children: [
          // Avatar
          AppAvatarCircle(
            icon: Icons.person,
            iconColor: color,
            bgColor: contact.relation.toLowerCase() == 'father'
                ? color.withValues(alpha: 0.25)
                : Colors.transparent,
            border: contact.relation.toLowerCase() == 'mother'
                ? Border.all(color: color, width: 2)
                : null,
            sizeFactor: 0.13,
          ),
          SizedBox(width: AppSpacing.sm + 6),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(contact.name, style: AppTextStyles.body(context).copyWith(fontWeight: FontWeight.w600)),
                    SizedBox(width: AppSpacing.xs + 2),
                    Text('|', style: AppTextStyles.body(context).copyWith(color: AppColors.textMuted)),
                    SizedBox(width: AppSpacing.xs + 2),
                    Text(contact.relation, style: AppTextStyles.body(context).copyWith(color: color, fontWeight: FontWeight.w500)),
                  ],
                ),
                SizedBox(height: AppSpacing.xs),
                Text(contact.phone, style: AppTextStyles.small(context)),
              ],
            ),
          ),
          // Delete
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.delete_outline, color: AppColors.warning, size: dim.fontSizeBody * 1.4),
          ),
        ],
      ),
    );
  }
}