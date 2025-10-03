// models/chat_message_model.dart

class ChatMessageModel {
	final String id;
	final String senderId; // customer/admin id
	final String senderName;
	final String text;
	final DateTime timestamp;
	final bool isAdmin;

	ChatMessageModel({
		required this.id,
		required this.senderId,
		required this.senderName,
		required this.text,
		required this.timestamp,
		this.isAdmin = false,
	});

	ChatMessageModel copyWith({
		String? id,
		String? senderId,
		String? senderName,
		String? text,
		DateTime? timestamp,
		bool? isAdmin,
	}) {
		return ChatMessageModel(
			id: id ?? this.id,
			senderId: senderId ?? this.senderId,
			senderName: senderName ?? this.senderName,
			text: text ?? this.text,
			timestamp: timestamp ?? this.timestamp,
			isAdmin: isAdmin ?? this.isAdmin,
		);
	}
}
