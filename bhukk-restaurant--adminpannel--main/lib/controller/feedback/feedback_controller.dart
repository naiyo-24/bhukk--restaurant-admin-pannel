// controller/feedback/feedback_controller.dart
import 'dart:math';
import 'export_util_stub.dart'
	if (dart.library.html) 'export_util_web.dart'
	if (dart.library.io) 'export_util_io.dart';
import 'package:get/get.dart';
import 'package:bhukk_resturant_admin/models/feedback_model.dart';

/// Admin Feedback controller (tagged as 'feedback' to avoid Dining collisions)
class FeedbackAdminController extends GetxController {
	// Source data
	final RxList<FeedbackModel> all = <FeedbackModel>[].obs;

	// Meta info beyond FeedbackModel
	final RxMap<String, FeedbackMeta> meta = <String, FeedbackMeta>{}.obs;

	// UI state / filters
	final RxString search = ''.obs;
	final RxSet<int> ratingFilter = <int>{}.obs; // 1..5 (empty => all)
	final Rxn<DateTime> from = Rxn<DateTime>();
	final Rxn<DateTime> to = Rxn<DateTime>();
	final RxnString restaurantFilter = RxnString(); // null => all
	final RxSet<String> categoryFilter = <String>{}.obs; // e.g., Food, Delivery
	final RxnString orderTypeFilter = RxnString(); // Delivery, Pickup, Dine-in
	final RxnString statusFilter = RxnString(); // New, Reviewed, Responded
	final RxBool isLoading = false.obs;

	// Selection / pagination
	final RxList<FeedbackModel> paged = <FeedbackModel>[].obs;
	final RxInt page = 1.obs;
	final int pageSize = 20;
	final RxBool hasMore = false.obs;

	// Derived stats
	final RxDouble avgRating = 0.0.obs;
	final RxInt totalToday = 0.obs;
	final RxInt totalWeek = 0.obs;
	final RxInt totalMonth = 0.obs;
	final RxDouble positiveRatio = 0.0.obs; // 0..1
	final RxMap<String, double> categoryAverages = <String, double>{}.obs;
	final RxList<String> topComplaints = <String>[].obs;
	final RxList<String> topAppreciations = <String>[].obs;
		final RxMap<String, double> restaurantAverages = <String, double>{}.obs;
		final RxString sortBy = 'date_desc'.obs; // date_desc, date_asc, rating_desc, rating_asc

	// Export state
	final RxBool exporting = false.obs;

	// Init
	@override
	void onInit() {
		super.onInit();
		_seedDemo();
		_recompute();
		debounce(search, (_) => _repage(), time: const Duration(milliseconds: 250));
		everAll([ratingFilter, from, to, restaurantFilter, categoryFilter, orderTypeFilter, statusFilter], (_) => _repage());
	}

	// Public API-ready hooks
	Future<void> fetchFeedbacks() async {
		// TODO: Integrate with backend
		// For now, recompute and paginate existing list
		_recompute();
		_repage(reset: true);
	}

		@override
		Future<void> refresh() async {
		await fetchFeedbacks();
	}

	Future<void> loadMore() async {
		if (!hasMore.value) return;
		page.value += 1;
		_repage();
	}

	// Filtering and pagination
	List<FeedbackModel> _applyFilters() {
		final q = search.value.trim().toLowerCase();
		final f = from.value; final t = to.value;
			final filtered = all.where((fb) {
			if (q.isNotEmpty) {
				final m = meta[fb.id];
				if (!fb.id.toLowerCase().contains(q) &&
						!(m?.orderId.toLowerCase().contains(q) ?? false) &&
						!fb.customerName.toLowerCase().contains(q)) {
					return false;
				}
			}
			if (ratingFilter.isNotEmpty && !ratingFilter.contains(fb.rating)) return false;
			if (f != null && fb.date.isBefore(f)) return false;
			if (t != null && fb.date.isAfter(t)) return false;
			final m = meta[fb.id];
			if (restaurantFilter.value != null && m?.restaurant != restaurantFilter.value) return false;
			if (orderTypeFilter.value != null && m?.orderType != orderTypeFilter.value) return false;
			if (statusFilter.value != null && m?.status != statusFilter.value) return false;
			if (categoryFilter.isNotEmpty && m != null && categoryFilter.intersection(m.categories.toSet()).isEmpty) return false;
			return true;
			}).toList();
			// Sorting
			switch (sortBy.value) {
				case 'date_asc':
					filtered.sort((a,b)=>a.date.compareTo(b.date));
					break;
				case 'rating_desc':
					filtered.sort((a,b)=>b.rating.compareTo(a.rating));
					break;
				case 'rating_asc':
					filtered.sort((a,b)=>a.rating.compareTo(b.rating));
					break;
				case 'date_desc':
				default:
					filtered.sort((a,b)=>b.date.compareTo(a.date));
			}
			return filtered;
	}

	void _repage({bool reset = false}) {
		final filtered = _applyFilters();
		hasMore.value = filtered.length > pageSize * (reset ? 1 : page.value);
		if (reset) page.value = 1;
		final end = min(filtered.length, page.value * pageSize);
		paged.assignAll(filtered.sublist(0, end));
	}

	void clearFilters() {
		search.value = '';
		ratingFilter.clear();
		from.value = null; to.value = null;
		restaurantFilter.value = null;
		categoryFilter.clear();
		orderTypeFilter.value = null;
		statusFilter.value = null;
		_repage(reset: true);
	}

	// Actions
	void reply(String id, String message) {
		_log(id, 'Replied: $message');
		_setStatus(id, 'Responded');
	}

	void markResolved(String id) {
		_setStatus(id, 'Reviewed');
		_log(id, 'Marked as Resolved');
	}

	void markPending(String id) {
		_setStatus(id, 'New');
		_log(id, 'Marked as Pending');
	}

	void escalate(String id) {
		_setStatus(id, 'Escalated');
		_log(id, 'Escalated');
	}

	void flagSpam(String id) {
		final m = meta[id]; if (m == null) return;
		m.spam = true; meta[id] = m;
		_log(id, 'Flagged as spam');
	}

	void offerCompensation(String id, String type, double amount) {
		_log(id, 'Compensation offered: $type ₹${amount.toStringAsFixed(2)}');
	}

	void assignTo(String id, String assignee) {
		final m = meta[id]; if (m == null) return;
		m.assignedTo = assignee; meta[id] = m;
		_log(id, 'Assigned to $assignee');
	}

	void addNote(String id, String note) {
		final m = meta[id]; if (m == null) return;
		m.internalNotes.add(note); meta[id] = m;
		_log(id, 'Note added');
	}

	// Export (returns path)
	Future<String> exportCsv({bool onlyFiltered = true}) async {
		final list = onlyFiltered ? paged : all;
		final header = 'FeedbackID,OrderID,Customer,Contact,Rating,Categories,OrderType,Status,Date,Review,Sentiment\n';
		final rows = list.map((fb) {
			final m = meta[fb.id];
			return [
				fb.id,
				m?.orderId ?? '',
				fb.customerName,
				m?.customerContact ?? '',
				fb.rating.toString(),
				(m?.categories ?? []).join('|'),
				m?.orderType ?? '',
				m?.status ?? '',
				fb.date.toIso8601String(),
				fb.review.replaceAll(',', ';').replaceAll('\n', ' '),
				m?.sentiment ?? '',
			].map((v) => '"$v"').join(',');
		}).join('\n');
		return header + rows;
	}

	Future<String?> exportToFile({bool onlyFiltered = true}) async {
		if (exporting.value) return null;
		exporting.value = true;
		try {
			final csv = await exportCsv(onlyFiltered: onlyFiltered);
			final filename = 'feedback_export_${DateTime.now().millisecondsSinceEpoch}.csv';
			final saved = await saveFeedbackCsv(filename, csv);
			return saved;
		} finally {
			exporting.value = false;
		}
	}

	// Stats recompute
	void _recompute() {
		if (all.isEmpty) return;
		final now = DateTime.now();
		final startOfToday = DateTime(now.year, now.month, now.day);
		final startOfWeek = startOfToday.subtract(Duration(days: startOfToday.weekday - 1));
		final startOfMonth = DateTime(now.year, now.month, 1);

		totalToday.value = all.where((e) => !e.date.isBefore(startOfToday)).length;
		totalWeek.value = all.where((e) => !e.date.isBefore(startOfWeek)).length;
		totalMonth.value = all.where((e) => !e.date.isBefore(startOfMonth)).length;
		avgRating.value = all.map((e) => e.rating).fold<double>(0, (p, r) => p + r) / all.length;
		final positives = all.where((e) => e.rating >= 4).length;
		positiveRatio.value = all.isEmpty ? 0 : positives / all.length;

		final Map<String, List<int>> catRatings = {};
			final Map<String, List<int>> restRatings = {};
		for (final e in all) {
			final cats = meta[e.id]?.categories ?? [];
			for (final c in cats) {
				catRatings.putIfAbsent(c, () => []);
				catRatings[c]!.add(e.rating);
			}
				final rest = meta[e.id]?.restaurant;
				if (rest != null) {
					restRatings.putIfAbsent(rest, () => []);
					restRatings[rest]!.add(e.rating);
				}
		}
		final catAvg = <String, double>{};
		catRatings.forEach((k, v) { if (v.isNotEmpty) catAvg[k] = v.reduce((a,b)=>a+b) / v.length; });
		categoryAverages.assignAll(catAvg);
			final restAvg = <String, double>{};
			restRatings.forEach((k, v) { if (v.isNotEmpty) restAvg[k] = v.reduce((a,b)=>a+b) / v.length; });
			restaurantAverages.assignAll(restAvg);

		// Simple keyword-based sentiment buckets for complaints/appreciations
		final complaints = <String, int>{};
		final appreciations = <String, int>{};
		for (final e in all) {
			final text = e.review.toLowerCase();
			for (final kw in _complaintKeywords) {
				if (text.contains(kw)) complaints[kw] = (complaints[kw] ?? 0) + 1;
			}
			for (final kw in _appreciationKeywords) {
				if (text.contains(kw)) appreciations[kw] = (appreciations[kw] ?? 0) + 1;
			}
		}
		final cSorted = complaints.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
		final aSorted = appreciations.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
		topComplaints.assignAll(cSorted.take(5).map((e) => e.key));
		topAppreciations.assignAll(aSorted.take(5).map((e) => e.key));
	}

	// Helpers
	void _setStatus(String id, String status) {
		final m = meta[id]; if (m == null) return;
		m.status = status; meta[id] = m;
	}

	void _log(String id, String action) {
		final m = meta[id]; if (m == null) return;
		m.history.add('${DateTime.now().toIso8601String()} — $action'); meta[id] = m;
	}

	String _deriveSentiment(String text, int rating) {
		final t = text.toLowerCase();
		if (rating >= 4) return 'Positive';
		if (rating == 3) return t.contains('bad') ? 'Negative' : 'Neutral';
		return 'Negative';
	}

	void _seedDemo() {
		// Generate demo feedbacks to showcase UI (API would replace this)
		final cats = ['Food','Delivery','Packaging','Service','Ambiance','Price'];
		final orderTypes = ['Delivery','Pickup','Dine-in'];
		final restaurants = ['Bhukk Downtown','Bhukk Express','Bhukk Lakeside'];
		final random = Random(2);
		for (int i=1; i<=60; i++) {
			final rating = 1 + random.nextInt(5);
			final date = DateTime.now().subtract(Duration(days: random.nextInt(35), hours: random.nextInt(20)));
			final fb = FeedbackModel(
				id: 'FBK${1000+i}',
				date: date,
				customerName: 'Customer $i',
				dishName: 'Dish ${1 + random.nextInt(20)}',
				rating: rating,
			review: _sampleReviews[random.nextInt(_sampleReviews.length)],
			);
			all.add(fb);
			meta[fb.id] = FeedbackMeta(
				orderId: 'ORD${5000+i}',
				customerContact: '+91-98${random.nextInt(99999999).toString().padLeft(8,'0')}',
				categories: List.generate(1+random.nextInt(2), (_) => cats[random.nextInt(cats.length)]),
				orderType: orderTypes[random.nextInt(orderTypes.length)],
				restaurant: restaurants[random.nextInt(restaurants.length)],
				status: ['New','Reviewed','Responded'][random.nextInt(3)],
				sentiment: _deriveSentiment(fb.review, rating),
				assignedTo: random.nextBool() ? 'Agent ${1+random.nextInt(4)}' : null,
			);
		}
		_repage(reset: true);
	}
}

class FeedbackMeta {
	final String orderId;
	final String customerContact;
	final List<String> categories;
	final String orderType; // Delivery, Pickup, Dine-in
	String status; // New, Reviewed, Responded, Escalated
	final String restaurant;
	String sentiment; // Positive/Neutral/Negative
	String? assignedTo;
	bool spam;
	final List<String> internalNotes;
	final List<String> history;

	FeedbackMeta({
		required this.orderId,
		required this.customerContact,
		required this.categories,
		required this.orderType,
		required this.restaurant,
		required this.status,
		required this.sentiment,
		this.assignedTo,
		this.spam = false,
		List<String>? internalNotes,
		List<String>? history,
	}) : internalNotes = internalNotes ?? <String>[],
			 history = history ?? <String>[];
}

const List<String> _complaintKeywords = [
	'late','cold','stale','bad','rude','dirty','leak','spilled','bland','overcooked','undercooked','missing','wrong','delay','slow'
];
const List<String> _appreciationKeywords = [
	'fresh','tasty','delicious','hot','great','amazing','excellent','on time','quick','friendly','perfect','loved'
];

const List<String> _sampleReviews = [
	'Food was delicious and hot. Delivery was on time!',
	'The packaging leaked and food was cold.',
	'Amazing taste and quick service. Loved it!',
	'Delay in delivery and missing item in order.',
	'Ambiance was great, but the service was slow.',
	'Overcooked item and rude delivery partner.',
	'Perfect spice levels and friendly staff.',
	'Stale bread and cold curry. Not satisfied.',
	'Excellent experience. Will order again!',
	'Bland taste and wrong item delivered.'
];

