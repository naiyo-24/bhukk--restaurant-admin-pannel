// screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import '../../controller/auth/auth_controller.dart';
// Removed unused theme import after redesign

class SignupScreen extends StatelessWidget {
	const SignupScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final AuthController controller = Get.find<AuthController>();

		return LayoutBuilder(builder: (context, constraints) {
			final wide = constraints.maxWidth > 900;
			return Scaffold(
				body: Container(
					decoration: const BoxDecoration(
						gradient: LinearGradient(
							colors: [Color(0xFFFCE9EC), Color(0xFFF7F8FB)],
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
						),
					),
					child: SafeArea(
						child: Center(
							child: ConstrainedBox(
								constraints: BoxConstraints(maxWidth: wide ? 1100 : 640),
								child: Padding(
									padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
									child: wide
										? SingleChildScrollView(
											padding: const EdgeInsets.only(top: 8, bottom: 32),
											child: Row(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Expanded(child: _MarketingPanel()),
													const SizedBox(width: 32),
													Expanded(child: _SignupForm(controller: controller)),
												],
											),
										) : _SignupForm(controller: controller),
								),
							),
						),
					),
				),
			);
		});
	}
}

class _MarketingPanel extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		return LayoutBuilder(builder: (ctx, c) {
			return ClipRRect(
				borderRadius: BorderRadius.circular(32),
				child: Stack(
					children: [
						// Decorative blurred circles
						Positioned(
							top: -60,
							left: -40,
							child: _DecorBlob(size: 180, colors: [Colors.redAccent.withValues(alpha: 0.28), Colors.orangeAccent.withValues(alpha: 0.15)]),
						),
						Positioned(
							bottom: -70,
							right: -40,
							child: _DecorBlob(size: 220, colors: [Colors.pinkAccent.withValues(alpha: 0.18), Colors.redAccent.withValues(alpha: 0.10)]),
						),
						Container(
							decoration: BoxDecoration(
								color: Colors.white.withValues(alpha: 0.55),
								backgroundBlendMode: BlendMode.lighten,
						),
							padding: const EdgeInsets.fromLTRB(40, 40, 40, 32),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									// Brand + Title
									Row(
										children: [
											Container(
												width: 54,
												height: 54,
												decoration: const BoxDecoration(
													shape: BoxShape.circle,
													gradient: LinearGradient(colors: [Color(0xFFFF6B6B), Color(0xFFFE8C68)], begin: Alignment.topLeft, end: Alignment.bottomRight),
													boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0,4))],
												),
												child: const Icon(Icons.restaurant_menu, color: Colors.white),
											),
											const SizedBox(width: 16),
											Expanded(
												child: ShaderMask(
													shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFDD2440), Color(0xFFFF824D)]).createShader(r),
													child: Text('Bhukk Partner', style: theme.textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white)),
											),
											),
									],
									),
									const SizedBox(height: 28),
									Text.rich(
										TextSpan(
											style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, height: 1.35, color: Colors.black87),
											children: const [
												TextSpan(text: 'Grow your restaurant with '),
												TextSpan(text: 'powerful delivery', style: TextStyle(fontWeight: FontWeight.w600)),
												TextSpan(text: ', '),
												TextSpan(text: 'dining', style: TextStyle(fontWeight: FontWeight.w600)),
												TextSpan(text: ' & '),
												TextSpan(text: 'insightful analytics', style: TextStyle(fontWeight: FontWeight.w600)),
												TextSpan(text: '.'),
											],
										),
									),
									const SizedBox(height: 34),
									_FeatureGrid(),
									const SizedBox(height: 28),
									Row(children: [
										Icon(Icons.support_agent_outlined, size: 18, color: Colors.redAccent.shade200),
										const SizedBox(width: 6),
										Text('Need help?  support@bhukk.app', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
									]),
								],
							),
						),
					],
				),
			);
		});
	}
}

class _DecorBlob extends StatelessWidget {
	final double size; final List<Color> colors; const _DecorBlob({required this.size, required this.colors});
	@override
	Widget build(BuildContext context) {
		return IgnorePointer(
			child: Container(
				width: size,
				height: size,
				decoration: BoxDecoration(
					shape: BoxShape.circle,
						gradient: RadialGradient(colors: colors, center: Alignment.topLeft),
				),
			),
		);
	}
}

class _FeatureGrid extends StatelessWidget {
	final features = const [
		(Icons.speed, 'Fast setup', 'Start receiving orders quickly'),
		(Icons.shopping_bag_outlined, 'Order management', 'Central dashboard for all orders'),
		(Icons.payments_outlined, 'Unified billing', 'Streamlined settlements & payouts'),
		(Icons.insights_outlined, 'Insights & reports', 'Real-time performance metrics'),
		(Icons.store_mall_directory_outlined, 'Dining tools', 'Manage tables & reservations'),
		(Icons.delivery_dining, 'Smart delivery', 'Optimize partner performance'),
	];

	@override
	Widget build(BuildContext context) {
		final isWide = MediaQuery.of(context).size.width > 640;
		return Wrap(
			spacing: 18,
			runSpacing: 18,
			children: features.take(isWide ? 6 : 4).map((f) => _FeatureCard(icon: f.$1, title: f.$2, subtitle: f.$3, width: isWide ? 220 : double.infinity)).toList(),
		);
	}
}

class _FeatureCard extends StatelessWidget {
	final IconData icon; final String title; final String subtitle; final double width; const _FeatureCard({required this.icon, required this.title, required this.subtitle, required this.width});
	@override
	Widget build(BuildContext context) {
		return AnimatedContainer(
			duration: const Duration(milliseconds: 350),
			width: width,
			padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
			decoration: BoxDecoration(
				borderRadius: BorderRadius.circular(22),
				color: Colors.white.withValues(alpha: 0.78),
				border: Border.all(color: Colors.redAccent.withValues(alpha: 0.20)),
				boxShadow: [
					BoxShadow(color: Colors.redAccent.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0,4)),
				],
			),
			child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
				Container(
					width: 38, height: 38,
					decoration: BoxDecoration(
						shape: BoxShape.circle,
						gradient: LinearGradient(colors: [Colors.redAccent.shade200, Colors.orangeAccent.shade100]),
						boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0,4))],
					),
					child: Icon(icon, size: 20, color: Colors.white),
				),
				const SizedBox(width: 12),
				Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
					Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
					const SizedBox(height: 4),
					Text(subtitle, style: const TextStyle(fontSize: 11.5, height: 1.2, color: Colors.black54)),
				])),
			]),
		);
	}
}

class _SignupForm extends StatelessWidget {
	final AuthController controller; const _SignupForm({required this.controller});
	@override
	Widget build(BuildContext context) {
		return Card(
			elevation: 6,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
			child: Padding(
				padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
				child: SingleChildScrollView(
					child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
						Text('Create Account', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.redAccent)),
						const SizedBox(height: 8),
						Text('Join the Bhukk partner network in a few quick steps.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
						const SizedBox(height: 24),
						Obx(() => TextField(
							keyboardType: TextInputType.number,
							inputFormatters: [FilteringTextInputFormatter.digitsOnly],
							maxLength: 10,
							decoration: InputDecoration(
								labelText: 'Phone Number',
								prefixIcon: const Icon(Icons.phone),
								filled: true,
								fillColor: Colors.redAccent.withValues(alpha: 0.04),
								errorText: controller.phoneNumber.value.length == 10 || controller.phoneNumber.value.isEmpty ? null : 'Enter 10 digit number',
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
							),
							onChanged: controller.setPhoneNumber,
						)),
						const SizedBox(height: 12),
						Obx(() => Align(
							alignment: Alignment.centerLeft,
							child: ElevatedButton.icon(
								style: ElevatedButton.styleFrom(
									backgroundColor: controller.phoneNumber.value.length == 10 ? Colors.redAccent : Colors.grey.shade300,
									foregroundColor: controller.phoneNumber.value.length == 10 ? Colors.white : Colors.black45,
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
								),
								icon: Icon(Icons.sms_outlined, color: controller.phoneNumber.value.length == 10 ? Colors.white : Colors.black45),
								label: Text(controller.showOtpField.value ? 'OTP Sent' : 'Generate OTP'),
								onPressed: controller.phoneNumber.value.length == 10 && !controller.isLoading.value ? controller.generateOtp : null,
							),
						)),
						AnimatedSwitcher(
							duration: const Duration(milliseconds: 250),
							child: Obx(() => controller.showOtpField.value ? Padding(
								padding: const EdgeInsets.only(top: 12),
								child: TextField(
									keyboardType: TextInputType.number,
									inputFormatters: [FilteringTextInputFormatter.digitsOnly],
									maxLength: 6,
									decoration: InputDecoration(
										labelText: 'OTP',
										prefixIcon: const Icon(Icons.lock),
										border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
										filled: true,
										fillColor: Colors.redAccent.withValues(alpha: 0.04),
										errorText: controller.otp.value.isEmpty || controller.otp.value.length == 6 ? null : '6 digits required',
									),
									onChanged: controller.setOtp,
								),
							) : const SizedBox.shrink()),
						),
						const SizedBox(height: 20),
						// Email
						Obx(() => TextField(
							keyboardType: TextInputType.emailAddress,
							decoration: InputDecoration(
								labelText: 'Business Email',
								prefixIcon: const Icon(Icons.email_outlined),
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
								filled: true,
								fillColor: Colors.redAccent.withValues(alpha: 0.04),
								errorText: controller.email.value.isEmpty || RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(controller.email.value) ? null : 'Enter valid email',
							),
							onChanged: controller.setEmail,
						)),
						const SizedBox(height: 20),
						// Password
						Obx(() => TextField(
							obscureText: !controller.showPassword.value,
							decoration: InputDecoration(
								labelText: 'Password (min 6 chars)',
								prefixIcon: const Icon(Icons.lock_outline),
								suffixIcon: IconButton(icon: Icon(controller.showPassword.value ? Icons.visibility_off : Icons.visibility), onPressed: controller.toggleShowPassword),
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
								filled: true,
								fillColor: Colors.redAccent.withValues(alpha: 0.04),
								errorText: controller.password.value.isEmpty || controller.password.value.length >= 6 ? null : 'Min 6 chars',
							),
							onChanged: controller.setPassword,
						)),
						const SizedBox(height: 20),
						// Confirm Password
						Obx(() => TextField(
							obscureText: !controller.showConfirmPassword.value,
							decoration: InputDecoration(
								labelText: 'Confirm Password',
								prefixIcon: const Icon(Icons.lock_person_outlined),
								suffixIcon: IconButton(icon: Icon(controller.showConfirmPassword.value ? Icons.visibility_off : Icons.visibility), onPressed: controller.toggleShowConfirmPassword),
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
								filled: true,
								fillColor: Colors.redAccent.withValues(alpha: 0.04),
								errorText: controller.confirmPassword.value.isEmpty || controller.confirmPassword.value == controller.password.value ? null : 'Passwords do not match',
							),
							onChanged: controller.setConfirmPassword,
						)),
						const SizedBox(height: 20),
						TextField(
							decoration: InputDecoration(
								labelText: 'Restaurant Name',
								prefixIcon: const Icon(Icons.restaurant),
								border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
								filled: true,
								fillColor: Colors.redAccent.withValues(alpha: 0.04),
							),
							onChanged: controller.setRestaurantName,
						),
						const SizedBox(height: 20),
						Row(children: [
							Expanded(child: Obx(() => SwitchListTile.adaptive(
								title: const Text('Dining'),
								value: controller.hasDining.value,
								onChanged: controller.toggleDining,
								activeTrackColor: Colors.redAccent,
							))),
							Expanded(child: Obx(() => SwitchListTile.adaptive(
								title: const Text('Liquor'),
								value: controller.hasLiquor.value,
								onChanged: controller.toggleLiquor,
								activeTrackColor: Colors.redAccent,
							))),
						]),
						const SizedBox(height: 28),
						Text('Documents', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
						const SizedBox(height: 12),
						Obx(() => Wrap(spacing: 12, runSpacing: 12, children: [
							_SlimDocTile(label: 'GSTIN', value: controller.gstin.value, onUpload: () => controller.setGstin('GSTIN.pdf'), onApply: () => controller.applyForDocument('GSTIN', notes: 'Please assist in applying for GSTIN')),
							_SlimDocTile(label: 'VAT', value: controller.vat.value, onUpload: () => controller.setVat('VAT.pdf'), onApply: () => controller.applyForDocument('VAT', notes: 'Please assist in applying for VAT')),
							_SlimDocTile(label: 'FSSAI', value: controller.fssai.value, onUpload: () => controller.setFssai('FSSAI.pdf'), onApply: () => controller.applyForDocument('FSSAI', notes: 'Please assist in applying for FSSAI')),
							_SlimDocTile(label: 'Other', value: controller.otherDocs.value, onUpload: () => controller.setOtherDocs('Other.pdf'), onApply: () => controller.applyForDocument('Other', notes: 'Help me get required documents')),
						])),
						const SizedBox(height: 16),
						Obx(() => controller.applications.isEmpty ? const SizedBox.shrink() : Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text('Applications', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600)),
								const SizedBox(height: 8),
								...controller.applications.map((a) => Container(
									margin: const EdgeInsets.only(bottom: 8),
									padding: const EdgeInsets.all(12),
									decoration: BoxDecoration(
										color: Colors.grey.shade50,
										borderRadius: BorderRadius.circular(12),
										border: Border.all(color: Colors.grey.shade200),
									),
									child: Row(children: [
										const Icon(Icons.assignment_outlined, size: 18),
										const SizedBox(width: 8),
										Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
											Text('${a.type} — ${a.status}', style: const TextStyle(fontWeight: FontWeight.w600)),
											Text('Ref: ${a.reference}${a.notes != null ? '\n${a.notes!}' : ''}', style: const TextStyle(fontSize: 12)),
										])),
									]),
								)),
							],
						)),
						const SizedBox(height: 32),
						Obx(() => SizedBox(
							width: double.infinity,
							child: ElevatedButton(
								style: ElevatedButton.styleFrom(
									backgroundColor: controller.isSignupValid ? Colors.redAccent : Colors.grey.shade300,
									foregroundColor: controller.isSignupValid ? Colors.white : Colors.black54,
									padding: const EdgeInsets.symmetric(vertical: 16),
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
									textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: .5),
								),
								onPressed: controller.isSignupValid && !controller.isLoading.value ? controller.signup : null,
								child: controller.isLoading.value ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Create Account'),
							),
						)),
					]),
				),
				), // end SingleChildScrollView
				); // end Card
	}
}

class _SlimDocTile extends StatelessWidget {
	final String label; final String value; final VoidCallback onUpload; final VoidCallback onApply; const _SlimDocTile({required this.label, required this.value, required this.onUpload, required this.onApply});
	@override
	Widget build(BuildContext context) {
		final uploaded = value.isNotEmpty;
		return Container(
			width: 240,
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
			decoration: BoxDecoration(
				color: Colors.white,
				borderRadius: BorderRadius.circular(18),
				border: Border.all(color: Colors.grey.shade200),
				boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0,2))],
			),
			child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
				Row(children: [Icon(uploaded ? Icons.check_circle : Icons.description_outlined, size: 20, color: uploaded ? Colors.green : Colors.grey), const SizedBox(width: 6), Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)))]),
				const SizedBox(height: 6),
				Text(uploaded ? 'Uploaded: $value' : 'No file', style: TextStyle(fontSize: 12, color: uploaded ? Colors.green : Colors.black54)),
				const SizedBox(height: 10),
				Row(children: [
					Expanded(child: OutlinedButton(onPressed: uploaded ? null : onApply, style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)), child: const Text('Apply'))),
					const SizedBox(width: 8),
					Expanded(child: ElevatedButton(onPressed: onUpload, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 10)), child: Text(uploaded ? 'Change' : 'Upload'))),
				]),
			]),
		);
	}
}

