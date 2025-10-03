// models/notification_item.dart

enum NotificationType { info, orderUpdate, payment }

class NotificationItem {
  String id;
  String title;
  String description;
  NotificationType type;
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
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} d ago';
  }
}
