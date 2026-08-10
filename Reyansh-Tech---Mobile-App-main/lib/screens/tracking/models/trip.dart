class Trip {
  final String? id;
  final String title;
  final String time;
  final String miles;
  final String duration;
  final double? distanceKm;
  final int? durationSeconds;

  const Trip({
    this.id,
    required this.title,
    required this.time,
    required this.miles,
    required this.duration,
    this.distanceKm,
    this.durationSeconds,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    // Handle both FastAPI schema and UI schema
    final startLoc = json['start_location'] as String? ?? '';
    final endLoc = json['end_location'] as String? ?? '';
    final title = json['title'] as String? ?? 
        (startLoc.isNotEmpty && endLoc.isNotEmpty ? '$startLoc to $endLoc' : 'City Trip');

    final distanceKmVal = (json['distance_km'] as num?)?.toDouble();
    final milesVal = json['miles'] as String? ?? 
        (distanceKmVal != null ? '${(distanceKmVal * 0.621371).toStringAsFixed(1)} mi' : '0.0 mi');

    final durationSecs = json['duration_seconds'] as int?;
    final durationVal = json['duration'] as String? ?? 
        (durationSecs != null ? '${(durationSecs / 60).round()} mins' : '0 mins');

    final startTimeStr = json['start_time'] as String? ?? json['time'] as String? ?? 'Today';

    return Trip(
      id: json['id'] as String?,
      title: title,
      time: startTimeStr,
      miles: milesVal,
      duration: durationVal,
      distanceKm: distanceKmVal,
      durationSeconds: durationSecs,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'time': time,
        'miles': miles,
        'duration': duration,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (durationSeconds != null) 'duration_seconds': durationSeconds,
      };
}
