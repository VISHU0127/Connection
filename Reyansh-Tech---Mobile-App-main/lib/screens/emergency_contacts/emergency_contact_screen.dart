import 'package:flutter/material.dart';
import 'package:my_app/core/utils/app_page_route.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_header.dart';
import 'package:my_app/core/widgets/app_primary_button.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'add_emergency_contact_screen.dart';
import 'widgets/emergency_contact_card.dart';
import 'models/emergency_contact.dart';

class EmergencyContactsScreen extends StatefulWidget {
  final VoidCallback? onNavigateToAddContact;

  const EmergencyContactsScreen({super.key, this.onNavigateToAddContact});

  @override
  State<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends State<EmergencyContactsScreen> {
  final List<EmergencyContact> _contacts = [
    EmergencyContact(name: 'Jhon Doe', relation: 'Father', phone: '+91 62617 01016'),
    EmergencyContact(name: 'Jhon Doe', relation: 'Mother', phone: '+91 62617 01016'),
  ];

  VoidCallback? get onNavigateToAddContact => widget.onNavigateToAddContact;

  void _removeContact(int index) {
    setState(() => _contacts.removeAt(index));
  }

  Future<void> _addContact() async {
    if (onNavigateToAddContact != null) {
      onNavigateToAddContact!();
      return;
    }
    final contact = await Navigator.of(context).push<EmergencyContact>(
      AppPageRoute(builder: (_) => const AddEmergencyContactScreen()),
    );
    if (contact != null) {
      setState(() => _contacts.add(contact));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: AppHeader(
                title: 'Emergency Contacts',
                subtitle: "They'll be notified in case of emergency",
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: [
                  ..._contacts.asMap().entries.map((entry) => Padding(
                        padding:
                            const EdgeInsets.only(bottom: AppSpacing.md),
                        child: EmergencyContactCard(
                          contact: entry.value,
                          onDelete: () => _removeContact(entry.key),
                        ),
                      )),
                  const SizedBox(height: AppSpacing.xs),
                  AppPrimaryButton(
                    label: '+ Add Emergency Contact',
                    onPressed: _addContact,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}