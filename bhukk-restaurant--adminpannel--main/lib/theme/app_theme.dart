// theme/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
	static const Color cherryRed = Color(0xFFD2042D);
	static const Color white = Colors.white;

		static ThemeData get themeData => ThemeData(
					useMaterial3: true,
				primaryColor: cherryRed,
				scaffoldBackgroundColor: white,
				colorScheme: ColorScheme.fromSwatch().copyWith(
					primary: cherryRed,
					secondary: cherryRed,
					surface: white,
				),
				textTheme: const TextTheme(
					headlineLarge: TextStyle(
						fontSize: 32,
						fontWeight: FontWeight.bold,
						color: cherryRed,
					),
					bodyLarge: TextStyle(
						fontSize: 18,
						color: Colors.black87,
					),
					labelLarge: TextStyle(
						fontSize: 16,
						color: cherryRed,
						fontWeight: FontWeight.w600,
					),
				),
				inputDecorationTheme: InputDecorationTheme(
					filled: true,
					fillColor: Colors.white,
					border: OutlineInputBorder(
						borderRadius: BorderRadius.circular(12),
						borderSide: const BorderSide(color: cherryRed),
					),
					focusedBorder: OutlineInputBorder(
						borderRadius: BorderRadius.circular(12),
						borderSide: const BorderSide(color: cherryRed, width: 2),
					),
				),
				elevatedButtonTheme: ElevatedButtonThemeData(
					style: ElevatedButton.styleFrom(
						backgroundColor: cherryRed,
						foregroundColor: white,
						minimumSize: const Size(180, 48),
						shape: RoundedRectangleBorder(
							borderRadius: BorderRadius.circular(12),
						),
						textStyle: const TextStyle(
							fontSize: 18,
							fontWeight: FontWeight.bold,
						),
					),
				),
			);
}
