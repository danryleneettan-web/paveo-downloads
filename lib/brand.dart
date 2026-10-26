import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const green = Color(0xFF426B58);
const sage = Color(0xFF92AD9A);
const lightGreen = Color(0xFFE5EDE4);
const ivory = Color(0xFFF7F8F3);
const landingCanvas = Color(0xFFEEF1E9);
const peach = Color(0xFFE7C3BA);
const charcoal = Color(0xFF263E33);
const gray = Color(0xFF6B6B6B);
const lightGray = Color(0xFFD9D9D9);

// Status colors from the Paveo brand sheet.
const statusPending = Color(0xFFF2A900);
const statusInProgress = Color(0xFF4385F5);
const statusResolved = Color(0xFF2E8B57);
const statusFlagged = peach;

const statusColors = {
  'pending': statusPending,
  'in_progress': statusInProgress,
  'resolved': statusResolved,
  'flagged': statusFlagged,
};

class PaveoBrandLockup extends StatelessWidget {
  final double iconSize;
  final double wordmarkSize;
  final bool showTagline;

  const PaveoBrandLockup({
    super.key,
    this.iconSize = 44,
    this.wordmarkSize = 22,
    this.showTagline = true,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(iconSize * 0.2),
        child: Image.asset(
          'assets/brand/paveo-app-mark.png',
          width: iconSize,
          height: iconSize,
          fit: BoxFit.cover,
        ),
      ),
      const SizedBox(width: 10),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'paveo.',
            style: GoogleFonts.poppins(
              fontSize: wordmarkSize,
              fontWeight: FontWeight.bold,
              color: charcoal,
              height: 1.05,
            ),
          ),
          if (showTagline)
            Text(
              'Report. Respond. Restore.',
              style: GoogleFonts.inter(fontSize: 10, color: gray),
            ),
        ],
      ),
    ],
  );
}
