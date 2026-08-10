import 'package:flutter/material.dart';
import 'package:my_app/core/theme/app_colors.dart';
import 'package:my_app/core/theme/app_text_styles.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'package:my_app/core/widgets/app_card.dart';
import 'package:my_app/core/widgets/app_icon_box.dart';
import 'package:my_app/core/widgets/app_section_header.dart';
import '../models/trip.dart';

class TodaysTrips extends StatelessWidget {
  final List<Trip> trips;

  const TodaysTrips({super.key, required this.trips});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeader(
          title: "Today's Trip",
          actionLabel: 'View all',
          onAction: () {},
        ),
        const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
        ...trips.map((trip) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.sm + AppSpacing.xs),
                radius: AppSpacing.sm.toDouble(),
                child: Row(
                  children: [
                    AppIconBox(
                      icon: Icons.location_on,
                      iconColor: AppColors.success,
                      bgColor: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.title,
                          style: AppTextStyles.label(context).copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${trip.time} • ${trip.miles} • ${trip.duration}',
                          style: AppTextStyles.caption(context).copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}