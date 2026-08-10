import 'package:flutter/material.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'widgets/policy_section.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String _lorem =
      'Lorem ipsum is a dummy or placeholder text commonly used in graphic design, '
      'publishing, and web development. Lorem ipsum is a dummy or placeholder text '
      'commonly used in graphic design, publishing, and web development.';

  static const List<Map<String, dynamic>> _sections = [
    {
      'heading': 'Heading goes here from here',
      'paragraphs': [_lorem, _lorem],
    },
    {
      'heading': 'Heading goes here from here',
      'paragraphs': [_lorem],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 🔝 Header
              AppHeader(
                title: 'Privacy Policies',
                subtitle: 'How we collect and use your data',
              ),

              const SizedBox(height: AppSpacing.xl),

              /// 📄 Policy Sections
              ..._sections.map((section) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: PolicySection(
                      heading: section['heading'] as String,
                      paragraphs:
                          List<String>.from(section['paragraphs'] as List),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}