class SafetyAlert {
  final String title;
  final String time;
  final String miles;
  final String duration;

  const SafetyAlert({
    required this.title,
    required this.time,
    required this.miles,
    required this.duration,
  });

  factory SafetyAlert.fromJson(Map<String, dynamic> json) => SafetyAlert(
        title: json['title'] as String,
        time: json['time'] as String,
        miles: json['miles'] as String,
        duration: json['duration'] as String,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'time': time,
        'miles': miles,
        'duration': duration,
      };
}