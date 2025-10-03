// cards/auth/phno_cards.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhoneNumberCard extends StatelessWidget {
	final TextEditingController controller;
	final void Function(String)? onChanged;
	final String? errorText;
	const PhoneNumberCard({
		super.key,
		required this.controller,
		this.onChanged,
		this.errorText,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			decoration: BoxDecoration(
				color: Colors.white.withAlpha((0.7 * 255).toInt()),
				borderRadius: BorderRadius.circular(18),
				boxShadow: [
					BoxShadow(
						color: Colors.black12,
						blurRadius: 16,
						offset: Offset(0, 8),
					),
				],
				border: Border.all(color: Colors.grey.shade200, width: 1.2),
			),
			padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
			child: Row(
				children: [
					Container(
						padding: const EdgeInsets.all(10),
						child: Icon(Icons.phone, color: Colors.red.shade400, size: 28),
					),
					const SizedBox(width: 16),
					Expanded(
						child: TextField(
							controller: controller,
							keyboardType: TextInputType.number,
							inputFormatters: [FilteringTextInputFormatter.digitsOnly],
							maxLength: 10,
							style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, letterSpacing: 1.2),
							decoration: InputDecoration(
								labelText: 'Phone Number',
								labelStyle: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
								errorText: errorText,
								counterText: '',
								border: InputBorder.none,
							),
							onChanged: onChanged,
						),
					),
				],
			),
		);
	}
}
