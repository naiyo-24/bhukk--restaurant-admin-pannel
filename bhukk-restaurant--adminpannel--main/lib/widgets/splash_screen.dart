// Clean modern splash screen implementation (fully replaced to fix prior structural issues)
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../theme/branding.dart';
import '../routes/app_routes.dart';

class SplashScreen extends StatefulWidget {
	const SplashScreen({super.key});
	@override
	State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
	late final AnimationController _controller;
	late final Animation<double> _fade;

	@override
	void didChangeDependencies() {
		super.didChangeDependencies();
		// Precache logo so it displays immediately without pop-in.
		precacheImage(const AssetImage('assets/icons/logo.png'), context).ignore();
	}

	@override
	void initState() {
		super.initState();
		_controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
		_fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);
		_controller.forward();
		Future.delayed(const Duration(seconds: 3), () {
			if (mounted && Get.currentRoute == AppRoutes.splash) {
				Get.offAllNamed(AppRoutes.login);
			}
		});
	}

	@override
	void dispose() {
		_controller.dispose();
		super.dispose();
	}

	@override
	Widget build(BuildContext context) {
		final size = MediaQuery.of(context).size;
		return Scaffold(
			body: Stack(
				children: [
					// Gradient background
					Container(
						decoration: const BoxDecoration(
							gradient: LinearGradient(
								colors: [Color(0xFFFCE9EC), Color(0xFFF7F8FB)],
								begin: Alignment.topLeft,
								end: Alignment.bottomRight,
							),
						),
					),
					// Decorative blurred circles
						Positioned(
							top: -80,
							left: -60,
							child: _CircleBlur(
								size: size.width * .55,
									colors: [
										Colors.redAccent.withValues(alpha: 0.28),
										Colors.orange.withValues(alpha: 0.18),
									],
							),
						),
						Positioned(
							bottom: -70,
							right: -40,
							child: _CircleBlur(
								size: size.width * .45,
									colors: [
										Colors.orangeAccent.withValues(alpha: 0.22),
										Colors.pinkAccent.withValues(alpha: 0.15),
									],
							),
						),
					// Center content
					Center(
						child: FadeTransition(
							opacity: _fade,
							child: Column(
								mainAxisSize: MainAxisSize.min,
								children: [
									// Logo image (bhukk)
									TweenAnimationBuilder<double>(
										duration: const Duration(milliseconds: 900),
										curve: Curves.easeOutBack,
										tween: Tween(begin: .85, end: 1),
										builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
										child: Container(
											width: 110,
											height: 110,
											decoration: BoxDecoration(
												shape: BoxShape.circle,
												boxShadow: [
													BoxShadow(color: Colors.redAccent.withValues(alpha: 0.25), blurRadius: 28, offset: const Offset(0, 10)),
												],
												border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 3),
											),
											clipBehavior: Clip.antiAlias,
											child: Image.asset(
												'assets/icons/logo.png',
												fit: BoxFit.cover,
												errorBuilder: (_, __, ___) => const Center(
													child: Icon(Icons.restaurant_menu, color: Colors.redAccent, size: 60),
												),
											),
										),
									),
									const SizedBox(height: 30),
									ShaderMask(
										shaderCallback: (r) => const LinearGradient(
											colors: [Color(0xFFDD2440), Color(0xFFFF824D)],
											begin: Alignment.topLeft,
											end: Alignment.bottomRight,
										).createShader(r),
										child: Text(
											Branding.appName,
											textAlign: TextAlign.center,
											style: const TextStyle(
												fontSize: 52,
												fontWeight: FontWeight.w800,
												letterSpacing: -1.2,
											),
										),
									),
									const SizedBox(height: 26),
									_TaglineGlass(),
								],
							),
						),
					),
				],
			),
		);
	}
}

class _TaglineGlass extends StatelessWidget {
	@override
	Widget build(BuildContext context) {
		return ClipRRect(
			borderRadius: BorderRadius.circular(40),
			child: BackdropFilter(
				filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
				child: Container(
					padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
						decoration: BoxDecoration(
							color: Colors.white.withValues(alpha: 0.55),
							border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
						boxShadow: [
							BoxShadow(
								color: Colors.redAccent.withValues(alpha: 0.12),
								blurRadius: 24,
								offset: const Offset(0, 10),
							),
						],
							gradient: LinearGradient(
								colors: [
									Colors.white.withValues(alpha: 0.65),
									Colors.white.withValues(alpha: 0.4),
								],
							begin: Alignment.topLeft,
							end: Alignment.bottomRight,
						),
					),
					child: Row(
						mainAxisSize: MainAxisSize.min,
						children: const [
							Icon(Icons.restaurant_menu, color: Colors.redAccent, size: 20),
							SizedBox(width: 10),
							Text(
								Branding.tagline,
								style: TextStyle(
									fontSize: 16,
									fontWeight: FontWeight.w600,
									letterSpacing: .4,
								),
							),
						],
					),
				),
			),
		);
	}
}

class _CircleBlur extends StatelessWidget {
	final double size;
	final List<Color> colors;
	const _CircleBlur({required this.size, required this.colors});

	@override
	Widget build(BuildContext context) {
		return Container(
			width: size,
			height: size,
			decoration: BoxDecoration(
				shape: BoxShape.circle,
				gradient: RadialGradient(
					colors: colors,
				),
			),
			child: BackdropFilter(
				filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
				child: const SizedBox(),
			),
		);
	}
}

