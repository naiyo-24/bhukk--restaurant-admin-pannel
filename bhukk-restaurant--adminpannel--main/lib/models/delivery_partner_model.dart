// models/delivery_partner_model.dart
enum AssignmentStatus { inProgress, pending, completed, cancelled }

class DeliveryAssignment {
	final String id;
	final String orderId;
	final String? partnerId; // newly added: which partner is handling this assignment
	final String pickup;
	final String drop;
	// Added product details for richer UI
	final List<DeliveredItem> items;
	AssignmentStatus status;
	DateTime? assignedAt;
	final String eta;
	// Cancellation meta
	String? cancelledBy; // customer / restaurant / system
	String? cancelReason;

	DeliveryAssignment({
		required this.id,
		required this.orderId,
		this.partnerId,
		required this.pickup,
		required this.drop,
		this.items = const [],
		this.status = AssignmentStatus.pending,
		this.assignedAt,
		this.eta = '-',
		this.cancelledBy,
		this.cancelReason,
	});

	String get statusLabel {
		switch (status) {
			case AssignmentStatus.inProgress:
				return 'In Progress';
			case AssignmentStatus.pending:
				return 'Pending';
			case AssignmentStatus.completed:
				return 'Completed';
			case AssignmentStatus.cancelled:
				return 'Cancelled';
		}
	}
}

class DeliveryPartnerModel {
	final String id;
	String name;
	String phone;
	String? email;
	String? avatarUrl;
	bool isOnline;
	// Added vehicle & performance metrics
	String? vehicleType; // bike, car, scooter
	String? vehicleNumber;
	int completedDeliveries;
	double rating;
	int cancellations;
	bool isSuspended;

	DeliveryPartnerModel({
		required this.id,
		required this.name,
		required this.phone,
		this.email,
		this.avatarUrl,
		this.isOnline = false,
		this.vehicleType,
		this.vehicleNumber,
		this.completedDeliveries = 0,
		this.rating = 0,
		this.cancellations = 0,
		this.isSuspended = false,
	});
}

class DeliveredItem {
	final String name;
	final int quantity;
	final String? category;
	DeliveredItem({required this.name, required this.quantity, this.category});
}
