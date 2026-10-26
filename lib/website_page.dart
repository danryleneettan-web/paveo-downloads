import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'brand.dart';
import 'map_page.dart';

class MobileIntroPage extends StatefulWidget {
  const MobileIntroPage({
    super.key,
    required this.onContinue,
    required this.onLogin,
  });
  final VoidCallback onContinue, onLogin;

  @override
  State<MobileIntroPage> createState() => _MobileIntroPageState();
}

class _MobileIntroPageState extends State<MobileIntroPage> {
  int page = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: ivory,
    body: SafeArea(
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _IntroWavePainter()),
          ),
          if (page == 0)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PaveoBrandLockup(iconSize: 78, wordmarkSize: 38),
                  const SizedBox(height: 12),
                  Text(
                    'Report. Respond. Restore.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: gray,
                      letterSpacing: 1.1,
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 50, 34, 38),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: lightGreen,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.location_on_rounded,
                      size: 44,
                      color: green,
                    ),
                  ),
                  const SizedBox(height: 34),
                  Text(
                    'Report.\nRespond.\nRestore.',
                    style: GoogleFonts.poppins(
                      fontSize: 40,
                      height: 1.05,
                      fontWeight: FontWeight.bold,
                      color: charcoal,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'A cleaner, safer, and more sustainable community starts with you.',
                    style: TextStyle(color: gray, fontSize: 15, height: 1.5),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          width: 9,
                          height: 9,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 1 ? green : sage.withValues(alpha: .55),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      TextButton(
                        onPressed: widget.onContinue,
                        child: const Text('Skip'),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: widget.onLogin,
                        child: const Text('Log in'),
                      ),
                      const SizedBox(width: 8),
                      FloatingActionButton(
                        onPressed: widget.onContinue,
                        child: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          if (page == 0)
            Positioned(
              right: 28,
              bottom: 40,
              child: FloatingActionButton(
                onPressed: () => setState(() => page = 1),
                child: const Icon(Icons.arrow_forward),
              ),
            ),
        ],
      ),
    ),
  );
}

class _IntroWavePainter extends CustomPainter {
  const _IntroWavePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = lightGreen.withValues(alpha: .8);
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * .48, 0)
      ..cubicTo(
        size.width * .52,
        size.height * .18,
        size.width * .30,
        size.height * .30,
        0,
        size.height * .34,
      )
      ..close();
    canvas.drawPath(path, paint);
    final lower = Path()
      ..moveTo(size.width, size.height * .68)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * .18, size.height)
      ..cubicTo(
        size.width * .55,
        size.height * .90,
        size.width * .77,
        size.height * .80,
        size.width,
        size.height * .68,
      )
      ..close();
    canvas.drawPath(lower, Paint()..color = sage.withValues(alpha: .18));
    final inner = Path()
      ..moveTo(size.width, size.height * .82)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * .42, size.height)
      ..cubicTo(
        size.width * .75,
        size.height * .92,
        size.width * .80,
        size.height * .88,
        size.width,
        size.height * .82,
      )
      ..close();
    canvas.drawPath(inner, Paint()..color = lightGreen.withValues(alpha: .72));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Public, signed-out website that mirrors the desktop pages in the Paveo
/// website reference. Authenticated users continue into the member workspace.
class WebsitePage extends StatefulWidget {
  const WebsitePage({super.key, required this.onLogin, required this.onReport});

  final VoidCallback onLogin;
  final VoidCallback onReport;

  @override
  State<WebsitePage> createState() => _WebsitePageState();
}

class _WebsitePageState extends State<WebsitePage> {
  int section = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 560;
    return Scaffold(
      backgroundColor: landingCanvas,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _SiteBackdropPainter()),
          ),
          SafeArea(
            child: Column(
              children: [
                _WebsiteNav(
                  compact: compact,
                  section: section,
                  onSelect: (value) => setState(() => section = value),
                  onLogin: widget.onLogin,
                  onReport: widget.onReport,
                ),
                Expanded(
                  child: IndexedStack(
                    index: section,
                    children: [
                      _LandingSurface(
                        compact: compact,
                        onReport: widget.onReport,
                        onLearn: () => setState(() => section = 2),
                        onTrack: () => setState(() => section = 1),
                      ),
                      _TrackSurface(onReport: widget.onReport),
                      _AboutSurface(onReport: widget.onReport),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WebsiteNav extends StatelessWidget {
  const _WebsiteNav({
    required this.compact,
    required this.section,
    required this.onSelect,
    required this.onLogin,
    required this.onReport,
  });

  final bool compact;
  final int section;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogin, onReport;

  @override
  Widget build(BuildContext context) => Container(
    color: landingCanvas.withValues(alpha: .72),
    padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 48, vertical: 14),
    child: Row(
      children: [
        const PaveoBrandLockup(iconSize: 42, wordmarkSize: 23),
        const Spacer(),
        if (!compact) ...[
          _navItem('Home', 0),
          TextButton(onPressed: onReport, child: const Text('Report')),
          _navItem('Track', 1),
          _navItem('About', 2),
          const SizedBox(width: 22),
        ] else
          PopupMenuButton<int>(
            tooltip: 'Open website navigation',
            icon: const Icon(Icons.menu, color: charcoal),
            onSelected: (value) => value == 3 ? onReport() : onSelect(value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 0, child: Text('Home')),
              PopupMenuItem(value: 3, child: Text('Report an issue')),
              PopupMenuItem(value: 1, child: Text('Track')),
              PopupMenuItem(value: 2, child: Text('About')),
            ],
          ),
        OutlinedButton(onPressed: onLogin, child: const Text('Log in')),
      ],
    ),
  );

  Widget _navItem(String label, int index) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: TextButton(
      onPressed: () => onSelect(index),
      style: TextButton.styleFrom(
        foregroundColor: section == index ? charcoal : gray,
        textStyle: TextStyle(
          fontWeight: section == index ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: 24,
            decoration: BoxDecoration(
              color: section == index ? green : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    ),
  );
}

class _LandingSurface extends StatelessWidget {
  const _LandingSurface({
    required this.compact,
    required this.onReport,
    required this.onLearn,
    required this.onTrack,
  });

  final bool compact;
  final VoidCallback onReport, onLearn, onTrack;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 560;
    final compactLayout = width < 900;
    final titleSize = mobile
        ? 32.0
        : compactLayout
        ? 28.0
        : 49.0;
    final leftPadding = mobile
        ? 22.0
        : compactLayout
        ? width * .14
        : 152.0;
    final rightPadding = mobile
        ? 22.0
        : compactLayout
        ? 24.0
        : 72.0;
    return SingleChildScrollView(
      child: Column(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1520),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  leftPadding,
                  mobile
                      ? 22
                      : compactLayout
                      ? 8
                      : 8,
                  rightPadding,
                  mobile
                      ? 28
                      : compactLayout
                      ? 0
                      : 18,
                ),
                child: mobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _heroCopy(
                            context,
                            onReport,
                            onLearn,
                            titleSize,
                            compactLayout: true,
                          ),
                          const SizedBox(height: 30),
                          const _RoadArtwork(compactLayout: true),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 4,
                            child: Padding(
                              padding: EdgeInsets.only(
                                top: compactLayout ? 28 : 20,
                              ),
                              child: _heroCopy(
                                context,
                                onReport,
                                onLearn,
                                titleSize,
                                compactLayout: compactLayout,
                              ),
                            ),
                          ),
                          const SizedBox(width: 26),
                          Expanded(
                            flex: 6,
                            child: _RoadArtwork(compactLayout: compactLayout),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: landingCanvas.withValues(alpha: .72),
            padding: EdgeInsets.symmetric(
              horizontal: mobile
                  ? 22
                  : compactLayout
                  ? 24
                  : 72,
              vertical: 38,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1216),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How Paveo works',
                      style: GoogleFonts.poppins(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        color: charcoal,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: const [
                        _FeatureCard(
                          number: '01',
                          title: 'Report',
                          detail:
                              'Share a photo and pin the road issue on the map.',
                          icon: Icons.add_a_photo_outlined,
                        ),
                        _FeatureCard(
                          number: '02',
                          title: 'Respond',
                          detail:
                              'Local teams review reports and share progress.',
                          icon: Icons.handyman_outlined,
                        ),
                        _FeatureCard(
                          number: '03',
                          title: 'Restore',
                          detail:
                              'Follow repairs and help make roads safer for everyone.',
                          icon: Icons.route_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onTrack,
                        icon: const Icon(Icons.map_outlined),
                        label: const Text('Explore the road issue map'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const _WebsiteFooter(),
        ],
      ),
    );
  }

  Widget _heroCopy(
    BuildContext context,
    VoidCallback onReport,
    VoidCallback onLearn,
    double titleSize, {
    required bool compactLayout,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!compactLayout) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE4ECE3),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Text(
              'COMMUNITY ROAD CARE',
              style: TextStyle(
                color: green,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: .5,
              ),
            ),
          ),
          const SizedBox(height: 18),
        ],
        Text(
          compactLayout
              ? 'Safer\nroads,\nstronger\ncommunities.'
              : 'Safer roads,\nstronger\ncommunities.',
          style: GoogleFonts.poppins(
            fontSize: titleSize,
            height: 1.30,
            fontWeight: FontWeight.bold,
            color: charcoal,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: compactLayout ? 360 : 470),
          child: Text(
            'Report potholes and road issues easily. Help us build safer and more sustainable communities.',
            style: TextStyle(
              fontSize: compactLayout ? 12 : 16,
              height: compactLayout ? 1.35 : 1.55,
              color: gray,
            ),
          ),
        ),
        SizedBox(height: compactLayout ? 16 : 23),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            FilledButton.icon(
              onPressed: onReport,
              style: FilledButton.styleFrom(
                minimumSize: Size(0, compactLayout ? 34 : 46),
                padding: EdgeInsets.symmetric(
                  horizontal: compactLayout ? 14 : 18,
                  vertical: 8,
                ),
                textStyle: TextStyle(
                  fontSize: compactLayout ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: Text(compactLayout ? 'Report Now' : 'Report an issue'),
            ),
            OutlinedButton(
              onPressed: onLearn,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(0, compactLayout ? 34 : 46),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                textStyle: TextStyle(
                  fontSize: compactLayout ? 12 : 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Learn More'),
            ),
          ],
        ),
        if (!compactLayout) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 18, color: green),
              const SizedBox(width: 9),
              Text(
                'Every report helps your local community respond.',
                style: TextStyle(color: gray, fontSize: 13, letterSpacing: .2),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _SiteBackdropPainter extends CustomPainter {
  const _SiteBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // These broad, opaque ribbons echo the soft organic waves in the Paveo
    // landing-page reference. They sit behind both the navigation and content.
    final topRight = Path()
      ..moveTo(size.width * .69, 0)
      ..cubicTo(
        size.width * .76,
        size.height * .12,
        size.width * .79,
        size.height * .19,
        size.width * .91,
        size.height * .22,
      )
      ..cubicTo(
        size.width * .98,
        size.height * .25,
        size.width,
        size.height * .31,
        size.width,
        size.height * .43,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topRight, Paint()..color = const Color(0xFFC5D1C2));

    final topBand = Path()
      ..moveTo(size.width * .80, 0)
      ..cubicTo(
        size.width * .85,
        size.height * .12,
        size.width * .91,
        size.height * .17,
        size.width,
        size.height * .20,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(topBand, Paint()..color = const Color(0xFFDCE4D8));

    final lowerLeft = Path()
      ..moveTo(0, size.height * .42)
      ..cubicTo(
        size.width * .14,
        size.height * .49,
        size.width * .18,
        size.height * .62,
        size.width * .32,
        size.height * .72,
      )
      ..cubicTo(
        size.width * .40,
        size.height * .76,
        size.width * .43,
        size.height * .89,
        size.width * .50,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lowerLeft, Paint()..color = const Color(0xFFCAD6C7));

    final lowerBand = Path()
      ..moveTo(0, size.height * .64)
      ..cubicTo(
        size.width * .13,
        size.height * .70,
        size.width * .18,
        size.height * .82,
        size.width * .28,
        size.height * .88,
      )
      ..cubicTo(
        size.width * .35,
        size.height * .91,
        size.width * .38,
        size.height * .97,
        size.width * .42,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(lowerBand, Paint()..color = const Color(0xFFE0E8DC));
  }

  @override
  bool shouldRepaint(covariant _SiteBackdropPainter oldDelegate) => false;
}

class _RoadArtwork extends StatelessWidget {
  const _RoadArtwork({required this.compactLayout});

  final bool compactLayout;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final artworkHeight = width < 560
        ? 230.0
        : width < 900
        ? 270.0
        : width < 1100
        ? 300.0
        : 480.0;
    return SizedBox(
      height: artworkHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/brand/road-hero-polished.png',
              fit: BoxFit.contain,
              semanticLabel: 'A road winding through a green hillside',
            ),
          ),
          Positioned(
            right: 0,
            bottom: compactLayout ? 18 : 50,
            child: Container(
              width: compactLayout ? 138 : 218,
              padding: EdgeInsets.symmetric(
                horizontal: compactLayout ? 11 : 14,
                vertical: compactLayout ? 9 : 13,
              ),
              decoration: BoxDecoration(
                color: ivory,
                borderRadius: BorderRadius.circular(compactLayout ? 13 : 20),
                boxShadow: [
                  BoxShadow(
                    color: charcoal.withValues(alpha: .10),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.all(
                      Radius.circular(compactLayout ? 9 : 12),
                    ),
                    child: Image.asset(
                      'assets/brand/paveo-app-mark.png',
                      width: compactLayout ? 38 : 50,
                      height: compactLayout ? 38 : 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                  SizedBox(width: compactLayout ? 7 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Report\nRespond\nRestore',
                          style: TextStyle(
                            fontSize: compactLayout ? 11 : 14,
                            height: compactLayout ? 1.18 : 1.24,
                            fontWeight: FontWeight.w700,
                            color: charcoal,
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Icon(
                            Icons.arrow_right_alt,
                            size: compactLayout ? 15 : 20,
                            color: gray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganicClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..moveTo(size.width * .12, 0)
    ..lineTo(size.width * .85, 0)
    ..cubicTo(
      size.width * 1.05,
      size.height * .14,
      size.width * .85,
      size.height * .45,
      size.width,
      size.height * .65,
    )
    ..lineTo(size.width * .88, size.height * .91)
    ..cubicTo(
      size.width * .64,
      size.height * 1.04,
      size.width * .30,
      size.height * .87,
      size.width * .08,
      size.height,
    )
    ..cubicTo(
      -size.width * .02,
      size.height * .74,
      size.width * .12,
      size.height * .23,
      size.width * .12,
      0,
    )
    ..close();

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _RoadPainter extends CustomPainter {
  const _RoadPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFE4ECE1), Color(0xFFCAD8CA), Color(0xFFE8EBDD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(rect),
    );
    final hill = Paint()
      ..color = const Color(0xFF8DA795).withValues(alpha: .52);
    final hillPath = Path()
      ..moveTo(0, size.height * .40)
      ..quadraticBezierTo(
        size.width * .24,
        size.height * .12,
        size.width * .45,
        size.height * .38,
      )
      ..quadraticBezierTo(
        size.width * .74,
        size.height * .12,
        size.width,
        size.height * .30,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(hillPath, hill);
    final farRoad = Path()
      ..moveTo(size.width * .54, size.height * .22)
      ..cubicTo(
        size.width * .48,
        size.height * .42,
        size.width * .68,
        size.height * .55,
        size.width * .49,
        size.height * .75,
      )
      ..cubicTo(
        size.width * .39,
        size.height * .87,
        size.width * .46,
        size.height * .95,
        size.width * .38,
        size.height * 1.1,
      );
    final road = Paint()
      ..color = const Color(0xFF53645B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .28
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(farRoad, road);
    final shoulder = Paint()
      ..color = ivory
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(farRoad, shoulder);
    final dash = Paint()
      ..color = const Color(0xFFE7DCC1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(farRoad, dash);
    for (final point in [
      Offset(size.width * .25, size.height * .58),
      Offset(size.width * .76, size.height * .38),
      Offset(size.width * .75, size.height * .78),
    ]) {
      canvas.drawCircle(
        point,
        13,
        Paint()..color = ivory.withValues(alpha: .9),
      );
      canvas.drawCircle(point, 7, Paint()..color = const Color(0xFFC77A6B));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.number,
    required this.title,
    required this.detail,
    required this.icon,
  });
  final String number, title, detail;
  final IconData icon;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 330,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: ivory,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: green),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    number,
                    style: const TextStyle(
                      fontSize: 11,
                      color: green,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: charcoal,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: gray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TrackSurface extends StatelessWidget {
  const _TrackSurface({required this.onReport});
  final VoidCallback onReport;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(28, 18, 28, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Road issue map',
                    style: GoogleFonts.poppins(
                      fontSize: 25,
                      fontWeight: FontWeight.w600,
                      color: charcoal,
                    ),
                  ),
                  const Text(
                    'See reported road issues and their current status.',
                    style: TextStyle(color: gray),
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Report issue'),
            ),
          ],
        ),
      ),
      Expanded(child: MapPage(embedded: true, onReport: onReport)),
    ],
  );
}

class _AboutSurface extends StatelessWidget {
  const _AboutSurface({required this.onReport});
  final VoidCallback onReport;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Road care starts with community.',
                style: GoogleFonts.poppins(
                  fontSize: 34,
                  height: 1.15,
                  fontWeight: FontWeight.bold,
                  color: charcoal,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Paveo gives residents a simple way to report road issues and gives local teams a clear view of what needs attention. Together, we can make road maintenance more visible, responsive, and community-led.',
                style: TextStyle(fontSize: 16, height: 1.7, color: gray),
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: const [
                  _FeatureCard(
                    number: '01',
                    title: 'Clear reports',
                    detail:
                        'A photo, issue type, and location help teams understand the problem.',
                    icon: Icons.fact_check_outlined,
                  ),
                  _FeatureCard(
                    number: '02',
                    title: 'Visible progress',
                    detail:
                        'Check report status as the issue is reviewed and addressed.',
                    icon: Icons.timeline_outlined,
                  ),
                  _FeatureCard(
                    number: '03',
                    title: 'Shared responsibility',
                    detail:
                        'Residents and local road teams work from the same information.',
                    icon: Icons.groups_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 26),
              FilledButton.icon(
                onPressed: onReport,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Report an issue'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _WebsiteFooter extends StatelessWidget {
  const _WebsiteFooter();
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    color: charcoal,
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 22),
    child: const Center(
      child: Text(
        'paveo.  ·  Report. Respond. Restore.',
        style: TextStyle(color: ivory, fontSize: 12),
      ),
    ),
  );
}
