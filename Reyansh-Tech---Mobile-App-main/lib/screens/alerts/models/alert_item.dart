enum AlertSeverity { warning, danger, info }

class AlertItem {
  final String? id;
  final String title;
  final String description;
  final String time;
  final AlertSeverity severity;
  bool isRead;

  AlertItem({
    this.id,
    required this.title,
    required this.description,
    required this.time,
    required this.severity,
    this.isRead = false,
  });

  factory AlertItem.fromJson(Map<String, dynamic> json) {
    final rawSeverity = (json['severity'] as String? ?? '').toLowerCase();
    AlertSeverity sev = AlertSeverity.info;
    if (rawSeverity == 'critical' || rawSeverity == 'danger' || rawSeverity == 'high') {
      sev = AlertSeverity.danger;
    } else if (rawSeverity == 'warning' || rawSeverity == 'medium') {
      sev = AlertSeverity.warning;
    }

    final status = (json['status'] as String? ?? '').toLowerCase();
    final isReadVal = json['is_read'] as bool? ?? (status == 'resolved' || status == 'acknowledged');

    final typeStr = json['type'] as String? ?? json['title'] as String? ?? 'Vehicle Alert';
    final descStr = json['description'] as String? ?? 'Alert triggered by device';
    final timestamp = json['timestamp'] as String? ?? json['time'] as String? ?? 'Recent';

    return AlertItem(
      id: json['id'] as String?,
      title: typeStr,
      description: descStr,
      time: timestamp,
      severity: sev,
      isRead: isReadVal,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'time': time,
        'severity': severity.name,
        'is_read': isRead,
      };
}
