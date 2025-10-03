// screens/chat/customer_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/chat/chat_controller.dart';
import '../../models/chat_message_model.dart';
import '../../utils/phone_helper.dart';

class CustomerChatScreen extends StatelessWidget {
	CustomerChatScreen({super.key});

	final ChatController c = Get.find<ChatController>();

	String _formatTime(DateTime dt) {
		final h = dt.hour.toString().padLeft(2, '0');
		final m = dt.minute.toString().padLeft(2, '0');
		return '$h:$m';
	}

	Widget _buildHeader(BuildContext context, String customerName, String orderId) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
			decoration: BoxDecoration(color: Theme.of(context).appBarTheme.backgroundColor, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]),
			child: Row(
				children: [
					IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.arrow_back)),
					CircleAvatar(radius: 20, child: Text(customerName.isNotEmpty ? customerName.characters.first : 'C')),
					const SizedBox(width: 12),
					Expanded(
						child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
							Text(customerName, style: const TextStyle(fontWeight: FontWeight.w700)),
							const SizedBox(height: 4),
							Text('Order #$orderId', style: const TextStyle(fontSize: 12, color: Colors.grey)),
						]),
					),
					// keep actions compact to avoid overflow on small screens
					Row(mainAxisSize: MainAxisSize.min, children: [
						IconButton(
							onPressed: () => launchPhoneCall(context, (Get.arguments as Map?)?['phone'] ?? ''),
							icon: const Icon(Icons.call),
							tooltip: 'Call',
						),
						IconButton(
							onPressed: () => _showAbout(context, customerName, orderId),
							icon: const Icon(Icons.info_outline),
							tooltip: 'About',
						),
					]),
				],
			),
		);
	}

	void _showAbout(BuildContext context, String customerName, String orderId) {
		final args = Get.arguments ?? {};
		final phone = (args is Map && args['phone'] != null) ? args['phone'] as String : 'Unknown';
		Get.bottomSheet(
			SafeArea(
				child: Container(
					padding: const EdgeInsets.all(16),
					decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
					child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
						Text('Customer', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
						const SizedBox(height: 8),
						Text(customerName),
						const SizedBox(height: 8),
						Text('Phone: $phone'),
						const SizedBox(height: 8),
						Text('Order ID: $orderId'),
						const SizedBox(height: 12),
						Row(children: [
							ElevatedButton.icon(onPressed: () { launchPhoneCall(context, phone); }, icon: const Icon(Icons.call), label: const Text('Call')),
							const SizedBox(width: 12),
							TextButton(onPressed: () => Get.back(), child: const Text('Close')),
						])
					]),
				),
				),
			isScrollControlled: false,
		);
	}

	Widget _dateDivider(DateTime dt) {
		final now = DateTime.now();
		final today = DateTime(now.year, now.month, now.day);
		final msgDay = DateTime(dt.year, dt.month, dt.day);
		String label;
		if (msgDay == today) {
			label = 'Today';
		} else if (msgDay == today.subtract(const Duration(days: 1))) {
			label = 'Yesterday';
		} else {
			label = '${dt.day}/${dt.month}/${dt.year}';
		}

		return Center(
			child: Container(
				margin: const EdgeInsets.symmetric(vertical: 8),
				padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
				decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
				child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
			),
		);
	}

	Widget _messageBubble(ChatMessageModel m) {
		final alignment = m.isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start;
		final bg = m.isAdmin ? LinearGradient(colors: [Colors.red.shade600, Colors.red.shade400]) : LinearGradient(colors: [Colors.grey.shade200, Colors.grey.shade100]);
		final textColor = m.isAdmin ? Colors.white : Colors.black87;

		return Column(
			crossAxisAlignment: alignment,
			children: [
				Container(
					margin: EdgeInsets.symmetric(vertical: 6, horizontal: m.isAdmin ? 12 : 12),
					padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
					constraints: const BoxConstraints(maxWidth: 520),
					decoration: BoxDecoration(
						gradient: bg,
						borderRadius: BorderRadius.only(
							topLeft: const Radius.circular(16),
							topRight: const Radius.circular(16),
							bottomLeft: Radius.circular(m.isAdmin ? 16 : 4),
							bottomRight: Radius.circular(m.isAdmin ? 4 : 16),
						),
						boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
					),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(m.text, style: TextStyle(color: textColor)),
							const SizedBox(height: 6),
							Row(
								mainAxisSize: MainAxisSize.min,
								children: [
									Text(_formatTime(m.timestamp), style: TextStyle(fontSize: 10, color: textColor.withAlpha((0.9 * 255).toInt()))),
								],
							)
						],
					),
				),
			],
		);
	}

	@override
	Widget build(BuildContext context) {
		final dynamic args = Get.arguments;
		final String customerName = (args is Map && args['customerName'] is String && (args['customerName'] as String).isNotEmpty)
			? args['customerName'] as String
			: 'Customer';
		final String orderId = (args is Map && args['orderId'] is String && (args['orderId'] as String).isNotEmpty)
			? args['orderId'] as String
			: '---';

		return LayoutBuilder(builder: (ctx, cons) {
			final isWide = cons.maxWidth >= 900;
			return Scaffold(
				body: Column(
					children: [
						_buildHeader(context, customerName, orderId),
						Expanded(
							child: isWide
									? Row(
											children: [
												Flexible(
													flex: 3,
													child: Container(
														color: Theme.of(context).cardColor.withAlpha((0.04 * 255).toInt()),
														child: Padding(
															padding: const EdgeInsets.all(16.0),
															child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
																const Text('Order details', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
																const SizedBox(height: 8),
																Text('Order ID: $orderId'),
																const SizedBox(height: 8),
																const Text('Instruction: Please ring bell twice and leave at door.'),
																const SizedBox(height: 18),
																const Text('Customer details', style: TextStyle(fontWeight: FontWeight.w700)),
																const SizedBox(height: 8),
																Text(customerName),
																const SizedBox(height: 8),
																const Text('Phone: +91 90000 00000'),
															]),
														),
													),
												),
												Flexible(
													flex: 7,
													child: Column(children: [
														Expanded(child: Obx(() {
															final list = c.messages;
															DateTime? lastDay;
															return ListView.builder(
																controller: c.scrollController,
																padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
																itemCount: list.length,
																itemBuilder: (context, i) {
																	if (i < 0 || i >= list.length) return const SizedBox.shrink();
																	final m = list[i];
																	final mDay = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
																	Widget child = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
																		if (lastDay == null || mDay != lastDay!) _dateDivider(m.timestamp),
																		Align(alignment: m.isAdmin ? Alignment.centerRight : Alignment.centerLeft, child: _messageBubble(m)),
																	]);
																	lastDay = mDay;
																	return child;
																},
															);
														})),
														_buildInputBar(context),
													]),
												),
											],
										)
									: Column(children: [
											Expanded(child: Obx(() {
												final list = c.messages;
												DateTime? lastDay;
												return ListView.builder(
													controller: c.scrollController,
													padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
													itemCount: list.length,
													itemBuilder: (context, i) {
														if (i < 0 || i >= list.length) return const SizedBox.shrink();
														final m = list[i];
														final mDay = DateTime(m.timestamp.year, m.timestamp.month, m.timestamp.day);
														Widget child = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
															if (lastDay == null || mDay != lastDay!) _dateDivider(m.timestamp),
															Align(alignment: m.isAdmin ? Alignment.centerRight : Alignment.centerLeft, child: _messageBubble(m)),
														]);
														lastDay = mDay;
														return child;
													},
												);
											})),
											_buildInputBar(context),
										]),
						),
					],
				),
			);
		});
	}

	Widget _buildInputBar(BuildContext context) {
		return Obx(() {
			return SafeArea(
				top: false,
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						if (c.showEmojiPicker.value)
							Container(
								height: 200,
								color: Theme.of(context).scaffoldBackgroundColor,
								child: GridView.count(
									crossAxisCount: 8,
									padding: const EdgeInsets.all(12),
									children: [
										'🙂','😂','😍','😮','🙏','👍','🎉','🔥','😅','🤝','👏','😴','🤔','😢','😎','🙌'
									].map((e) => InkWell(onTap: () { c.inputController.text += e; }, child: Center(child: Text(e, style: const TextStyle(fontSize: 20))))).toList(),
								),
							),
						Container(
							padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
							color: Theme.of(context).scaffoldBackgroundColor,
							child: Row(children: [
								IconButton(onPressed: c.toggleEmojiPicker, icon: const Icon(Icons.emoji_emotions_outlined)),
								IconButton(onPressed: c.attachFile, icon: const Icon(Icons.attach_file)),
								Expanded(
									child: TextField(
										controller: c.inputController,
										textCapitalization: TextCapitalization.sentences,
										decoration: const InputDecoration(hintText: 'Type a message', border: InputBorder.none),
										minLines: 1,
										maxLines: 5,
										onSubmitted: c.sendMessage,
									),
								),
								IconButton(
									onPressed: () => c.sendMessage(c.inputController.text),
									icon: const Icon(Icons.send, color: Colors.red),
								)
							]),
						),
					],
				),
			);
		});
	}
}
