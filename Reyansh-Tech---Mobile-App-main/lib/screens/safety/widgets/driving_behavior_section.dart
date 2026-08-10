import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_section_header.dart';
import '../models/driving_behavior.dart';
import 'behavior_card.dart';

class DrivingBehaviorSection extends StatelessWidget {
  final List<DrivingBehavior> behaviors;

  const DrivingBehaviorSection({super.key, required this.behaviors});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(title: 'Driving Behavior'),
        const SizedBox(height: AppSpacing.sm),
        ...behaviors.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: BehaviorCard(behavior: b),
            )),
      ],
    );
  }
}