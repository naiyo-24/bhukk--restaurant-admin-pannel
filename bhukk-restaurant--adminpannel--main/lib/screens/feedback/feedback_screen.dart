// screens/feedback/feedback_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:bhukk_resturant_admin/widgets/main_scaffold.dart';
import 'package:bhukk_resturant_admin/controller/feedback/feedback_controller.dart';
import 'package:bhukk_resturant_admin/cards/feedback/feedback_card.dart';

class FeedbackScreen extends StatelessWidget {
	const FeedbackScreen({super.key});

	@override
	Widget build(BuildContext context) {
		// Controller is provided by route binding; avoid duplicate registration
		final FeedbackAdminController fc = Get.find<FeedbackAdminController>(tag: 'feedback');
		return MainScaffold(
			title: 'Feedback',
			child: NotificationListener<ScrollNotification>(
				onNotification: (s) {
					if (s.metrics.pixels >= s.metrics.maxScrollExtent - 120 && fc.hasMore.value && !fc.isLoading.value) fc.loadMore();
					return false;
				},
				child: RefreshIndicator(
					onRefresh: () => fc.refresh(),
					child: LayoutBuilder(
						builder: (ctx, constraints) {
							final isWide = constraints.maxWidth >= 900;
							return Obx(() {
								final items = fc.paged;
								return CustomScrollView(
									slivers: [
										// Header content
										SliverToBoxAdapter(
											child: Padding(
												padding: const EdgeInsets.all(12.0),
												child: Column(
													crossAxisAlignment: CrossAxisAlignment.start,
													children: [
														_overview(fc),
														const SizedBox(height: 12),
														_filtersBar(context, fc),
														const SizedBox(height: 12),
													],
												),
											),
										),
										if (items.isEmpty)
											SliverToBoxAdapter(
												child: Padding(
													padding: const EdgeInsets.symmetric(vertical: 48.0),
													child: Center(child: Text('No feedbacks found', style: Theme.of(context).textTheme.bodyLarge)),
												),
											)
										else if (isWide)
											SliverPadding(
												padding: const EdgeInsets.symmetric(horizontal: 12.0),
												sliver: SliverGrid(
													gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
														crossAxisCount: 2,
														mainAxisSpacing: 8,
														crossAxisSpacing: 8,
														mainAxisExtent: constraints.maxWidth >= 1200 ? 236 : 256,
													),
													delegate: SliverChildBuilderDelegate(
														(_, i) {
															final m = items[i];
															return FeedbackCard(model: m, onTap: () => _openDetail(fc, m.id));
														},
														childCount: items.length,
													),
												),
											)
										else
											SliverPadding(
												padding: const EdgeInsets.symmetric(horizontal: 12.0),
												sliver: SliverList.builder(
													itemCount: items.length,
													itemBuilder: (_, i) {
														final m = items[i];
														return Padding(
															padding: const EdgeInsets.only(bottom: 8.0),
															child: FeedbackCard(model: m, onTap: () => _openDetail(fc, m.id)),
														);
													},
												),
											),
								],
								);
							});
						},
					),
				),
			),
		);
	}

	Widget _overview(FeedbackAdminController fc) {
		return Obx(() {
		return Column(
			crossAxisAlignment: CrossAxisAlignment.start,
			children: [
				const Text('Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
				const SizedBox(height: 8),
				_summaryWrap([
					_pill('Today', fc.totalToday.value.toString(), Colors.blue),
					_pill('This Week', fc.totalWeek.value.toString(), Colors.indigo),
					_pill('This Month', fc.totalMonth.value.toString(), Colors.deepPurple),
					_pill('Avg Rating', fc.avgRating.value.toStringAsFixed(1), Colors.teal),
					_pill('Positive %', '${(fc.positiveRatio.value * 100).toStringAsFixed(0)}%', Colors.green),
				]),
				// Best restaurants panel removed as requested
			],
		);
	});
	}

	Widget _pill(String title, String value, Color color) {
		return Chip(
			backgroundColor: color.withValues(alpha: .1),
			label: Row(mainAxisSize: MainAxisSize.min, children: [
				Text('$title: ', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
				Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
			]),
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: color.withValues(alpha: .2))),
		);
	}

	Widget _summaryWrap(List<Widget> children) {
		return Wrap(spacing: 8, runSpacing: 8, children: children);
	}

// Removed unused _keywordsCard()

	Widget _filtersBar(BuildContext context, FeedbackAdminController fc) {
		return Obx(() {
			final f = fc.from.value; final t = fc.to.value;
					return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
						Row(children: [
					Expanded(child: TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search by ID, order or customer'), onChanged: (v) => fc.search.value = v)),
					const SizedBox(width: 8),
					OutlinedButton.icon(onPressed: () => _showDateDialog(context, fc), icon: const Icon(Icons.date_range), label: Text(_dateLabel(f, t))),
				]),
				const SizedBox(height: 8),
				Wrap(spacing: 8, runSpacing: 8, children: [
							DropdownButton<String>(
								value: fc.sortBy.value,
								items: const [
									DropdownMenuItem(value: 'date_desc', child: Text('Sort: Newest')),
									DropdownMenuItem(value: 'date_asc', child: Text('Sort: Oldest')),
									DropdownMenuItem(value: 'rating_desc', child: Text('Sort: Rating high → low')),
									DropdownMenuItem(value: 'rating_asc', child: Text('Sort: Rating low → high')),
								],
								onChanged: (v) { if (v != null) { fc.sortBy.value = v; fc.refresh(); } },
							),
					DropdownButton<String>(
						value: fc.statusFilter.value ?? 'All',
						items: const [
							DropdownMenuItem(value: 'All', child: Text('Status: All')),
							DropdownMenuItem(value: 'New', child: Text('New')),
							DropdownMenuItem(value: 'Reviewed', child: Text('Reviewed')),
							DropdownMenuItem(value: 'Responded', child: Text('Responded')),
							DropdownMenuItem(value: 'Escalated', child: Text('Escalated')),
						],
						onChanged: (v) => fc.statusFilter.value = v == 'All' ? null : v,
					),
					DropdownButton<String>(
						value: fc.orderTypeFilter.value ?? 'All',
						items: const [
							DropdownMenuItem(value: 'All', child: Text('Type: All')),
							DropdownMenuItem(value: 'Delivery', child: Text('Delivery')),
							DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
							DropdownMenuItem(value: 'Dine-in', child: Text('Dine-in')),
						],
						onChanged: (v) => fc.orderTypeFilter.value = v == 'All' ? null : v,
					),

					// Rating filter chips
					...List.generate(5, (i) => FilterChip(
								label: Text('${i+1}★'),
								selected: fc.ratingFilter.contains(i+1),
								onSelected: (_) {
									if (fc.ratingFilter.contains(i+1)) {
										fc.ratingFilter.remove(i+1);
									} else {
										fc.ratingFilter.add(i+1);
									}
								},
							)),
					// Category chips
					...['Food','Delivery','Packaging','Service','Ambiance','Price'].map((c) => FilterChip(
								label: Text(c),
								selected: fc.categoryFilter.contains(c),
								onSelected: (_) {
									if (fc.categoryFilter.contains(c)) {
										fc.categoryFilter.remove(c);
									} else {
										fc.categoryFilter.add(c);
									}
								},
							)),
					TextButton.icon(onPressed: fc.clearFilters, icon: const Icon(Icons.clear), label: const Text('Clear')),
					Obx(() => ElevatedButton.icon(
						onPressed: fc.exporting.value ? null : () async {
							final path = await fc.exportToFile(onlyFiltered: true);
							if (path != null) {
								Get.snackbar('Export', 'Saved: $path', snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
							} else {
								Get.snackbar('Export', 'Export cancelled or failed', snackPosition: SnackPosition.BOTTOM);
							}
						},
						icon: fc.exporting.value ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color: Colors.white)) : const Icon(Icons.download),
						label: Text(fc.exporting.value ? 'Exporting...' : 'Export CSV'),
					)),
				])
			]);
		});
	}

// Removed unused _list()

	void _openDetail(FeedbackAdminController fc, String id) {
		final fb = fc.all.firstWhereOrNull((e) => e.id == id);
		if (fb == null) return;
		final replyCtl = TextEditingController(text: 'Thanks for your feedback!');
		final noteCtl = TextEditingController();
		Get.bottomSheet(
			SafeArea(
				child: Obx(() {
					final meta = fc.meta[id];
					if (meta == null) {
						return const SizedBox.shrink();
					}
					return Container(
						decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
						padding: const EdgeInsets.all(16),
						child: SingleChildScrollView(
							child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
								Row(children: [
									Text('Feedback ${fb.id}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
									const Spacer(),
									IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
								]),
								const SizedBox(height: 8),
								Text('${meta.orderId} • ${meta.orderType} • ${DateFormat('yMMMd – HH:mm').format(fb.date.toLocal())}'),
								const SizedBox(height: 8),
								Row(children: [
									CircleAvatar(child: Text(fb.customerName[0])),
									const SizedBox(width: 8),
									Expanded(child: Text('${fb.customerName} (${meta.customerContact})')),
									IconButton(tooltip: 'Call', onPressed: () => _callCustomer(meta.customerContact), icon: const Icon(Icons.call)),
									IconButton(tooltip: 'Copy', onPressed: () { Clipboard.setData(ClipboardData(text: meta.customerContact)); Get.snackbar('Copied', 'Number copied'); }, icon: const Icon(Icons.copy)),
								]),
								const SizedBox(height: 12),
								Wrap(spacing: 8, runSpacing: 8, children: [
									Chip(label: Text('${fb.rating}★')),
									...meta.categories.map((e) => Chip(label: Text(e))),
									Chip(label: Text(meta.status)),
									Chip(label: Text('Sentiment: ${meta.sentiment}')),
									if (meta.assignedTo != null) Chip(label: Text('Assigned: ${meta.assignedTo}')),
									if (meta.spam) const Chip(label: Text('Spam')),
								]),
								const SizedBox(height: 12),
								Text(fb.review),
								const SizedBox(height: 16),
								// Reply box
								TextField(
									controller: replyCtl,
									decoration: const InputDecoration(labelText: 'Quick reply', border: OutlineInputBorder()),
									minLines: 1,
									maxLines: 3,
								),
								const SizedBox(height: 8),
								Wrap(spacing: 8, runSpacing: 8, children: [
									ElevatedButton.icon(onPressed: () { fc.reply(id, replyCtl.text.trim()); Get.snackbar('Reply', 'Sent'); }, icon: const Icon(Icons.reply), label: const Text('Send Reply')),
									OutlinedButton(onPressed: () { fc.markResolved(id); Get.snackbar('Status', 'Marked resolved'); }, child: const Text('Mark Resolved')),
									OutlinedButton(onPressed: () { fc.markPending(id); Get.snackbar('Status', 'Marked pending'); }, child: const Text('Mark Pending')),
									IconButton(tooltip: 'Flag spam', onPressed: () { fc.flagSpam(id); Get.snackbar('Spam', 'Flagged'); }, icon: const Icon(Icons.flag_outlined)),
									IconButton(tooltip: 'Escalate', onPressed: () { fc.escalate(id); Get.snackbar('Escalated', 'Escalated'); }, icon: const Icon(Icons.escalator_warning_outlined)),
								]),
								const SizedBox(height: 8),
								Wrap(spacing: 8, runSpacing: 8, children: [
									OutlinedButton.icon(onPressed: () { fc.offerCompensation(id, 'Coupon', 50); Get.snackbar('Coupon', '₹50 coupon noted'); }, icon: const Icon(Icons.card_giftcard), label: const Text('Offer coupon')),
									OutlinedButton.icon(onPressed: () { fc.assignTo(id, 'Team A'); Get.snackbar('Assign', 'Assigned to Team A'); }, icon: const Icon(Icons.assignment_ind_outlined), label: const Text('Assign')),
									OutlinedButton.icon(onPressed: () { if (noteCtl.text.trim().isEmpty) { Get.snackbar('Note', 'Enter note text'); return; } fc.addNote(id, noteCtl.text.trim()); noteCtl.clear(); Get.snackbar('Note', 'Added'); }, icon: const Icon(Icons.note_alt_outlined), label: const Text('Add note')),
								]),
								const SizedBox(height: 12),
								TextField(
									controller: noteCtl,
									decoration: const InputDecoration(labelText: 'Internal note', border: OutlineInputBorder()),
									minLines: 1,
									maxLines: 3,
								),
								const SizedBox(height: 16),
								// Notes list
								if (meta.internalNotes.isNotEmpty) ...[
									const Text('Internal Notes', style: TextStyle(fontWeight: FontWeight.w600)),
									const SizedBox(height: 6),
									...meta.internalNotes.map((n) => ListTile(leading: const Icon(Icons.note, size: 18), title: Text(n))),
									const SizedBox(height: 12),
								],
								// History
								if (meta.history.isNotEmpty) ...[
									const Text('History', style: TextStyle(fontWeight: FontWeight.w600)),
									const SizedBox(height: 6),
									...meta.history.reversed.map((h) => ListTile(leading: const Icon(Icons.history, size: 18), title: Text(h))),
								],
							]),
						),
					);
				}),
			),
			isScrollControlled: true,
			enterBottomSheetDuration: const Duration(milliseconds: 150),
			exitBottomSheetDuration: const Duration(milliseconds: 150),
		);
	}

	Future<void> _callCustomer(String number) async {
		final sanitized = number.replaceAll(RegExp(r'\s+'), '');
		final uri = Uri(scheme: 'tel', path: sanitized);
		try {
			final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
			if (!ok) {
				await Clipboard.setData(ClipboardData(text: sanitized));
				Get.snackbar('Call', 'Unable to initiate, number copied');
			}
		} catch (_) {
			await Clipboard.setData(ClipboardData(text: sanitized));
			Get.snackbar('Call', 'Number copied to clipboard');
		}
	}

	String _dateLabel(DateTime? f, DateTime? t) {
		final fmt = DateFormat('yMMMd');
		if (f == null && t == null) return 'Date';
		if (f != null && t != null) return '${fmt.format(f)} → ${fmt.format(t)}';
		if (f != null) return fmt.format(f);
		return fmt.format(t!);
	}

	Future<void> _showDateDialog(BuildContext context, FeedbackAdminController fc) async {
		final now = DateTime.now();
		await showModalBottomSheet(
			context: context,
			shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
			builder: (ctx) => SafeArea(
				child: Padding(
					padding: const EdgeInsets.all(16.0),
					child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
						Row(children: [const Text('Select date range', style: TextStyle(fontWeight: FontWeight.w700)), const Spacer(), TextButton(onPressed: ()=>Get.back(), child: const Text('Close'))]),
						const Divider(),
						Wrap(spacing: 8, runSpacing: 8, children: [
							OutlinedButton(onPressed: () { final s = DateTime(now.year, now.month, now.day); fc.from.value = s; fc.to.value = DateTime(now.year, now.month, now.day, 23,59,59); Get.back(); }, child: const Text('Today')),
							OutlinedButton(onPressed: () { final s = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6)); fc.from.value = s; fc.to.value = DateTime(now.year, now.month, now.day, 23,59,59); Get.back(); }, child: const Text('Last 7 days')),
							OutlinedButton(onPressed: () { final s = DateTime(now.year, now.month, 1); final e = DateTime(now.year, now.month + 1, 0, 23,59,59); fc.from.value = s; fc.to.value = e; Get.back(); }, child: const Text('This month')),
							OutlinedButton(onPressed: () async {
								final picked = await Get.dialog<DateTimeRange>(Dialog(
									insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
									child: ConstrainedBox(
										constraints: const BoxConstraints(maxWidth: 480, maxHeight: 640),
										child: DateRangePickerDialog(
											firstDate: DateTime(now.year - 2),
											lastDate: DateTime(now.year + 1),
											initialDateRange: (fc.from.value != null && fc.to.value != null) ? DateTimeRange(start: fc.from.value!, end: fc.to.value!) : null,
										),
									),
								));
								if (picked != null) { fc.from.value = DateTime(picked.start.year, picked.start.month, picked.start.day); fc.to.value = DateTime(picked.end.year, picked.end.month, picked.end.day, 23,59,59); }
								Get.back();
							}, child: const Text('Custom range…')),
							TextButton.icon(onPressed: () { fc.from.value = null; fc.to.value = null; Get.back(); }, icon: const Icon(Icons.clear), label: const Text('Clear')),
						])
					]),
				),
			),
		);
	}
}
