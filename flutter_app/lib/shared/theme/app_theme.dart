import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF0F1720),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(bodyColor: Colors.white),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF081226), elevation: 0),
  );
}
