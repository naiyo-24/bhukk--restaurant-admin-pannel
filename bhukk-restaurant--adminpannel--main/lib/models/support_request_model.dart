// models/support_request_model.dart
enum SupportCategory { bug, billing, general, feature }

enum SupportStatus { open, inProgress, resolved }

class SupportRequest {
  final String id;
  final String fullName;
  final String email;
  final SupportCategory category;
  final String description;
  final List<String> attachments; // file paths or urls
  SupportStatus status;
  final DateTime createdAt;

  SupportRequest({
    required this.id,
    required this.fullName,
    required this.email,
    required this.category,
    required this.description,
    this.attachments = const [],
    this.status = SupportStatus.open,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String formattedDate() {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }
}
