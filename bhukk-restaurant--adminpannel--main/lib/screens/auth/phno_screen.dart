// screens/auth/phno_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:ui';
import '../../controller/auth/auth_controller.dart';
// Removed old phone number card import; using unified styled TextFields
import 'package:flutter/services.dart';

class PhnoScreen extends StatelessWidget {
	const PhnoScreen({super.key});

	@override
	Widget build(BuildContext context) {
		final controller = Get.find<AuthController>();
		return LayoutBuilder(
			builder: (context, constraints) {
				final wide = constraints.maxWidth > 880;
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
									constraints: BoxConstraints(maxWidth: wide ? 1080 : 620),
									child: Padding(
										padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
										child: wide
											? Row(
												crossAxisAlignment: CrossAxisAlignment.start,
												children: [
													Expanded(child: _LoginMarketing()),
													const SizedBox(width: 36),
													Expanded(child: _LoginForm(controller: controller)),
												],
											)
											: _LoginForm(controller: controller),
										),
									),
								),
							),
						),
					);
			},
		);
	}
}

class _LoginMarketing extends StatefulWidget {
	@override
	State<_LoginMarketing> createState() => _LoginMarketingState();
}

class _LoginMarketingState extends State<_LoginMarketing> {
	double _anim = 0;
	@override
	void initState() {
		super.initState();
		// Staggered entrance
		Future.delayed(const Duration(milliseconds: 60), () => setState(() => _anim = 1));
	}

	@override
	Widget build(BuildContext context) {
		final theme = Theme.of(context);
		final heading = ShaderMask(
			shaderCallback: (r) => const LinearGradient(
				colors: [Color(0xFFDD2440), Color(0xFFFF824D)],
				begin: Alignment.topLeft,
				end: Alignment.bottomRight,
			).createShader(r),
			child: Text(
				'Welcome Back',
				style: theme.textTheme.displaySmall?.copyWith(
					fontWeight: FontWeight.w800,
					color: Colors.white,
					letterSpacing: -.5,
				),
			),
		);

		final featureChips = Wrap(
			spacing: 12,
			runSpacing: 12,
			children: const [
				_Tag(text: 'Unified platform', icon: Icons.hub),
				_Tag(text: 'Realtime insights', icon: Icons.speed),
				_Tag(text: 'Secure OTP login', icon: Icons.verified_user),
				_Tag(text: 'Grow revenue', icon: Icons.trending_up),
			],
		);

		return AnimatedOpacity(
			opacity: _anim,
			duration: const Duration(milliseconds: 600),
			curve: Curves.easeOut,
			child: Stack(
				children: [
					// Decorative blurred blobs
					Positioned(
						top: -30,
						left: -40,
						child: _DecorBlob(size: 180, colors: [Colors.redAccent.withValues(alpha: 0.28), Colors.orange.withValues(alpha: 0.18)]),
					),
					Positioned(
						bottom: 40,
						right: -30,
						child: _DecorBlob(size: 140, colors: [Colors.orangeAccent.withValues(alpha: 0.22), Colors.pinkAccent.withValues(alpha: 0.15)]),
					),
					Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							heading,
							const SizedBox(height: 20),
							_FrostCard(
								child: Column(
									crossAxisAlignment: CrossAxisAlignment.start,
									children: [
										Text(
											'Access your dashboard and keep orders moving.',
											style: theme.textTheme.titleMedium?.copyWith(color: Colors.black87, height: 1.35),
										),
										const SizedBox(height: 22),
										featureChips,
									],
								),
							),
							const Spacer(),
							GestureDetector(
								onTap: () => Get.toNamed('/signup'),
								child: Row(
									mainAxisSize: MainAxisSize.min,
									children: [
										Text('Need an account? ', style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
										Text('Create one', style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent, fontWeight: FontWeight.w600)),
										const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.redAccent),
									],
								),
							),
						],
					),
				],
			),
		);
	}
}

class _Tag extends StatelessWidget {
	final String text;
	final IconData icon;
	const _Tag({required this.text, required this.icon});
	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
			decoration: BoxDecoration(
				color: Colors.white.withValues(alpha: 0.85),
				borderRadius: BorderRadius.circular(28),
				border: Border.all(color: Colors.redAccent.withValues(alpha: 0.18)),
				boxShadow: [
					BoxShadow(
						color: Colors.redAccent.withValues(alpha: 0.07),
						blurRadius: 10,
						offset: const Offset(0, 4),
					),
				],
			),
			child: Row(
				mainAxisSize: MainAxisSize.min,
				children: [
					Icon(icon, size: 16, color: Colors.redAccent),
					const SizedBox(width: 6),
					Text(
						text,
						style: const TextStyle(fontWeight: FontWeight.w600),
					),
				],
			),
		);
	}
}

class _FrostCard extends StatelessWidget {
	final Widget child;
	const _FrostCard({required this.child});
	@override
	Widget build(BuildContext context) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(28),
			child: BackdropFilter(
				filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
				child: Container(
					width: double.infinity,
					padding: const EdgeInsets.fromLTRB(28, 28, 28, 30),
					decoration: BoxDecoration(
						borderRadius: BorderRadius.circular(28),
						border: Border.all(color: Colors.white.withValues(alpha: 0.65), width: 1.2),
						gradient: LinearGradient(
							colors: [
								Colors.white.withValues(alpha: 0.78),
								Colors.white.withValues(alpha: 0.55),
							],
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
						),
						boxShadow: [
							BoxShadow(
								color: Colors.redAccent.withValues(alpha: 0.08),
								blurRadius: 22,
								offset: const Offset(0, 14),
							),
						],
					),
					child: child,
				),
			),
		);
	}
}

class _DecorBlob extends StatelessWidget {
	final double size;
	final List<Color> colors;
	const _DecorBlob({required this.size, required this.colors});
	@override
	Widget build(BuildContext context) {
		return IgnorePointer(
			child: Container(
				width: size,
				height: size,
				decoration: BoxDecoration(
					shape: BoxShape.circle,
					gradient: RadialGradient(
						colors: colors,
						center: Alignment.center,
						radius: .85,
					),
				),
			),
		);
	}
}

class _LoginForm extends StatelessWidget {
	final AuthController controller; const _LoginForm({required this.controller});
	@override
	Widget build(BuildContext context) {
		return Card(
			elevation: 6,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
			child: Padding(
				padding: const EdgeInsets.fromLTRB(30, 36, 30, 34),
				child: SingleChildScrollView(
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							Text(
								'Login',
								style: Theme.of(context).textTheme.headlineSmall?.copyWith(
									fontWeight: FontWeight.bold,
									color: Colors.redAccent,
								),
							),
							const SizedBox(height: 6),
							Text(
								'Enter phone to receive OTP',
								style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
							),
							const SizedBox(height: 28),
							Obx(() => TextField(
								keyboardType: TextInputType.number,
								inputFormatters: [FilteringTextInputFormatter.digitsOnly],
								maxLength: 10,
								decoration: InputDecoration(
									labelText: 'Phone Number',
									prefixIcon: const Icon(Icons.phone),
									border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
									filled: true,
									fillColor: Colors.redAccent.withValues(alpha: 0.04),
									errorText: controller.phoneNumber.value.isEmpty || controller.phoneNumber.value.length == 10 ? null : 'Enter 10 digit number',
								),
								onChanged: controller.setPhoneNumber,
							)),
							const SizedBox(height: 14),
							Obx(() => ElevatedButton.icon(
								style: ElevatedButton.styleFrom(
									backgroundColor: controller.phoneNumber.value.length == 10 ? Colors.redAccent : Colors.grey.shade300,
									foregroundColor: controller.phoneNumber.value.length == 10 ? Colors.white : Colors.black45,
									shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
									padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
								),
								icon: Icon(
									Icons.sms_outlined,
									color: controller.phoneNumber.value.length == 10 ? Colors.white : Colors.black45,
									size: 20,
								),
								label: Text(controller.showOtpField.value ? 'OTP Sent' : 'Generate OTP'),
								onPressed: controller.phoneNumber.value.length == 10 && !controller.isLoading.value
									? controller.generateOtp
									: null,
							)),
							AnimatedSwitcher(
								duration: const Duration(milliseconds: 300),
								child: Obx(
									() => controller.showOtpField.value
										? Padding(
											padding: const EdgeInsets.only(top: 14),
											child: TextField(
												keyboardType: TextInputType.number,
												inputFormatters: [FilteringTextInputFormatter.digitsOnly],
												maxLength: 6,
												decoration: InputDecoration(
													labelText: 'OTP',
													prefixIcon: const Icon(Icons.lock),
													border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
													filled: true,
													fillColor: Colors.redAccent.withValues(alpha: 0.04),
													errorText: controller.otp.value.isEmpty || controller.otp.value.length == 6
														? null
														: '6 digits required',
												),
												onChanged: controller.setOtp,
											),
										)
										: const SizedBox.shrink(),
								),
							),
							const SizedBox(height: 30),
							Obx(() => SizedBox(
								width: double.infinity,
								child: ElevatedButton(
									style: ElevatedButton.styleFrom(
										backgroundColor: controller.phoneNumber.value.length == 10 && controller.otp.value.length == 6
											? Colors.redAccent
											: Colors.grey.shade300,
										foregroundColor: controller.phoneNumber.value.length == 10 && controller.otp.value.length == 6
											? Colors.white
											: Colors.black45,
										padding: const EdgeInsets.symmetric(vertical: 16),
										shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
										textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: .6),
									),
									onPressed: controller.phoneNumber.value.length == 10 && controller.otp.value.length == 6 && !controller.isLoading.value
										? controller.loginWithPhone
										: null,
									child: controller.isLoading.value
										? const SizedBox(
											width: 26,
											height: 26,
											child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
										)
										: const Text('Login'),
								),
							)),
							const SizedBox(height: 18),
							Row(
								mainAxisAlignment: MainAxisAlignment.center,
								children: [
									Text("Don't have an account? ", style: const TextStyle(color: Colors.black54)),
									GestureDetector(
										onTap: () => Get.toNamed('/signup'),
										child: const Text(
											'Sign Up',
											style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
										),
									),
								],
							),
							const SizedBox(height: 24),
							Text(
								'Protected by secure verification. Your number stays private.',
								style: Theme.of(context).textTheme.bodySmall?.copyWith(
									color: Colors.black38,
									fontStyle: FontStyle.italic,
								),
							),
						],
					),
				),
			),
		);
	}
}
