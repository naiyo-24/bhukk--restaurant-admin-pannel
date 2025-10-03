// models/notification_model.dart

enum NotificationType { info, orderUpdate, payment, system }

class NotificationItem {
  final String id;
  final String title;
  final String description;
  final NotificationType type;
  DateTime timestamp;
  bool read;

  NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    DateTime? timestamp,
    this.read = false,
  }) : timestamp = timestamp ?? DateTime.now();

  String timeAgo() {
    final d = DateTime.now().difference(timestamp);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}
