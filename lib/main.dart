import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand.dart';
import 'firebase_options.dart';
import 'member_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PaveoApp());
}

class PaveoApp extends StatelessWidget {
  const PaveoApp({super.key});

  @override
  Widget build(BuildContext context) {
    final inter = GoogleFonts.interTextTheme();
    final poppins = GoogleFonts.poppinsTextTheme();
    final textTheme = inter.copyWith(
      displayLarge: poppins.displayLarge?.copyWith(color: charcoal),
      displayMedium: poppins.displayMedium?.copyWith(color: charcoal),
      displaySmall: poppins.displaySmall?.copyWith(color: charcoal),
      headlineLarge: poppins.headlineLarge?.copyWith(color: charcoal),
      headlineMedium: poppins.headlineMedium?.copyWith(color: charcoal),
      headlineSmall: poppins.headlineSmall?.copyWith(color: charcoal),
      titleLarge: poppins.titleLarge?.copyWith(color: charcoal),
      titleMedium: poppins.titleMedium?.copyWith(color: charcoal),
      titleSmall: poppins.titleSmall?.copyWith(color: charcoal),
    );

    return MaterialApp(
      title: 'Paveo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          primary: green,
          secondary: sage,
          tertiary: peach,
          surface: ivory,
          onPrimary: ivory,
          onSurface: charcoal,
        ),
        scaffoldBackgroundColor: ivory,
        textTheme: textTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: ivory,
          foregroundColor: charcoal,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: charcoal,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: ivory,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: lightGray),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: lightGray),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: green, width: 1.5),
          ),
          labelStyle: const TextStyle(color: gray),
          hintStyle: const TextStyle(color: gray),
        ),
        cardTheme: CardThemeData(
          color: lightGreen,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: lightGray),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: green,
            foregroundColor: ivory,
            minimumSize: const Size(0, 46),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: green,
            minimumSize: const Size(0, 44),
            side: const BorderSide(color: sage),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: green,
          foregroundColor: ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: ivory,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titleTextStyle: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: charcoal,
          ),
        ),
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: ivory,
          surfaceTintColor: Colors.transparent,
          showDragHandle: true,
        ),
      ),
      home: const MemberPage(),
    );
  }
}
