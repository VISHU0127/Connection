import 'package:flutter/material.dart';
import 'package:my_app/core/widgets/app_scaffold.dart';
import 'package:my_app/core/constants/app_spacing.dart';
import 'models/trip.dart';
import 'widgets/tracking_map_view.dart';
import 'widgets/tracking_location_header.dart';
import 'widgets/tracking_stats_row.dart';
import 'widgets/live_tracking_card.dart';
import 'widgets/todays_trips.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  bool _isTrackingActive = true;

  final List<Trip> _trips = const [
    Trip(
      title: 'Home to Office',
      time: '8:30 AM',
      miles: '12.3 miles',
      duration: '25 mins',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      body: Column(
        children: [
          /// 🗺️ Map — edge to edge, above SafeArea
          const TrackingMapView(),

          /// 📜 Scrollable content
          Expanded(
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TrackingLocationHeader(),
                    const SizedBox(height: AppSpacing.xl),
                    const TrackingStatsRow(),
                    const SizedBox(height: AppSpacing.lg),
                    LiveTrackingCard(
                      isActive: _isTrackingActive,
                      onPauseResume: () =>
                          setState(() => _isTrackingActive = !_isTrackingActive),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    TodaysTrips(trips: _trips),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}