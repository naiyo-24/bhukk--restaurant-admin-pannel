// models/feedback_model.dart

class FeedbackModel {
  final String id;
  final DateTime date;
  final String customerName;
  final String dishName;
  final int rating; // 1-5
  final String review;
  final String? imageUrl;

  FeedbackModel({
    required this.id,
    required this.date,
    required this.customerName,
    required this.dishName,
    required this.rating,
    required this.review,
    this.imageUrl,
  });
}
