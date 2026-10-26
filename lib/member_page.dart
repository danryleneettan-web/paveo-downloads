import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map/flutter_map.dart';

import 'admin_page.dart';
import 'brand.dart';
import 'download_link_stub.dart'
    if (dart.library.js_interop) 'download_link_web.dart'
    as paveo_download;
import 'login_page.dart';
import 'map_page.dart' show MapPage, reports;
import 'similarity.dart';
import 'website_page.dart';

class MemberPage extends StatefulWidget {
  const MemberPage({super.key});

  @override
  State<MemberPage> createState() => _MemberPageState();
}

class _MemberPageState extends State<MemberPage> {
  int selected = 0;
  bool isAdmin = false;
  bool reporting = false;
  bool introComplete = false;
  StreamSubscription<User?>? authSubscription;
  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      currentUser,
    ) async {
      var roleIsAdmin = false;
      if (currentUser != null) {
        final profile = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        roleIsAdmin = profile.data()?['role'] == 'admin';
      }
      if (FirebaseAuth.instance.currentUser?.uid != currentUser?.uid) return;
      if (mounted) setState(() => isAdmin = roleIsAdmin);
    });
  }

  @override
  void dispose() {
    authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _login() async {
    final authenticated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
    if (!mounted) return;
    final currentUser = user;
    var roleIsAdmin = false;
    if (authenticated == true && currentUser != null) {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();
      roleIsAdmin = profile.data()?['role'] == 'admin';
    }
    if (!mounted) return;
    setState(() => isAdmin = roleIsAdmin);
    if (roleIsAdmin) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AdminPage()),
      );
    }
  }

  Future<void> _startReport() async {
    if (user == null) {
      await _login();
      if (user == null || isAdmin || !mounted) return;
    }
    if (MediaQuery.sizeOf(context).width >= 900) {
      setState(() => reporting = true);
      return;
    }
    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ReportWizardPage(
          onNavigate: (destination) {
            Navigator.pop(context);
            if (mounted) setState(() => selected = destination);
          },
        ),
      ),
    );
    if (submitted == true && mounted) setState(() => selected = 2);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    if (user == null && (isWide || kIsWeb)) {
      return WebsitePage(onLogin: _login, onReport: _startReport);
    }
    if (!kIsWeb && !isWide && user == null && !introComplete) {
      return MobileIntroPage(
        onContinue: () => setState(() => introComplete = true),
        onLogin: _login,
      );
    }
    return Scaffold(
      backgroundColor: ivory,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: isWide
                  ? Row(
                      children: [
                        _SideNav(
                          selected: reporting ? -1 : selected,
                          showBrand: true,
                          onSelect: (i) => setState(() {
                            selected = i;
                            reporting = false;
                          }),
                          onReport: _startReport,
                        ),
                        Expanded(
                          child: reporting
                              ? ReportWizardPage(
                                  embedded: true,
                                  onNavigate: (destination) => setState(() {
                                    selected = destination;
                                    reporting = false;
                                  }),
                                  onComplete: (submitted) => setState(() {
                                    reporting = false;
                                    if (submitted) selected = 2;
                                  }),
                                )
                              : _surface(),
                        ),
                      ],
                    )
                  : _surface(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: isWide
          ? null
          : _MobileNavBar(
              selected: selected,
              onSelect: (i) => setState(() => selected = i),
              onReport: _startReport,
            ),
    );
  }

  Widget _surface() => IndexedStack(
    index: selected,
    children: [
      _HomeSurface(
        user: user,
        onReport: _startReport,
        onMap: () => setState(() => selected = 1),
        onReports: () => setState(() => selected = 2),
        onProfile: () => setState(() => selected = 3),
        onNotifications: () => setState(() => selected = 4),
      ),
      MapPage(embedded: true, onReport: _startReport),
      _ReportsSurface(user: user, onReport: _startReport),
      _ProfileSurface(
        user: user,
        onLogin: _login,
        onHome: () => setState(() => selected = 0),
      ),
      _NotificationsSurface(user: user),
    ],
  );
}

class _MemberHeader extends StatelessWidget {
  const _MemberHeader({
    required this.user,
    required this.isAdmin,
    required this.isWide,
    this.showBrand = true,
    required this.onLogin,
    required this.onReport,
    required this.onAdmin,
    this.showReportAction = true,
  });
  final User? user;
  final bool isAdmin;
  final bool isWide;
  final bool showBrand;
  final VoidCallback onLogin, onReport, onAdmin;
  final bool showReportAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(isWide ? 30 : 16, 12, isWide ? 30 : 16, 12),
    child: Row(
      children: [
        if (showBrand)
          const PaveoBrandLockup(
            iconSize: 40,
            wordmarkSize: 21,
            showTagline: false,
          ),
        if (isWide) ...[
          const Spacer(),
          if (user != null)
            Text(
              'Welcome, ${user!.displayName?.split(' ').first ?? user!.email?.split('@').first ?? 'there'}',
              style: const TextStyle(color: gray),
            ),
          const SizedBox(width: 16),
          if (user == null)
            TextButton(onPressed: onLogin, child: const Text('Log in')),
          if (isAdmin)
            TextButton.icon(
              onPressed: onAdmin,
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Admin portal'),
            ),
          if (showReportAction)
            FilledButton.icon(
              onPressed: onReport,
              icon: const Icon(Icons.add_a_photo_outlined, size: 18),
              label: const Text('Report an issue'),
            ),
        ] else ...[
          const Spacer(),
          IconButton(
            onPressed: isAdmin
                ? onAdmin
                : user == null
                ? onLogin
                : null,
            tooltip: isAdmin
                ? 'Admin portal'
                : user == null
                ? 'Log in'
                : null,
            icon: Icon(
              user == null ? Icons.login : Icons.account_circle_outlined,
              color: green,
            ),
          ),
        ],
      ],
    ),
  );
}

class _MobileNavBar extends StatelessWidget {
  const _MobileNavBar({
    required this.selected,
    required this.onSelect,
    required this.onReport,
  });

  final int selected;
  final ValueChanged<int> onSelect;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ivory,
        border: Border(top: BorderSide(color: sage.withValues(alpha: .32))),
      ),
      child: Row(
        children: [
          _MobileNavItem(
            icon: Icons.home_outlined,
            label: 'Home',
            active: selected == 0,
            onTap: () => onSelect(0),
          ),
          _MobileNavItem(
            icon: Icons.map_outlined,
            label: 'Map',
            active: selected == 1,
            onTap: () => onSelect(1),
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                width: 58,
                height: 58,
                child: FloatingActionButton(
                  heroTag: 'mobile-report-action',
                  onPressed: onReport,
                  backgroundColor: green,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  child: const Icon(Icons.add, size: 32),
                ),
              ),
            ),
          ),
          _MobileNavItem(
            icon: Icons.description_outlined,
            label: 'Reports',
            active: selected == 2,
            onTap: () => onSelect(2),
          ),
          _MobileNavItem(
            icon: Icons.person_outline,
            label: 'Profile',
            active: selected == 3,
            onTap: () => onSelect(3),
          ),
        ],
      ),
    ),
  );
}

class _MobileNavItem extends StatelessWidget {
  const _MobileNavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 23, color: active ? charcoal : sage),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? charcoal : gray,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.selected,
    required this.showBrand,
    required this.onSelect,
    required this.onReport,
  });
  final int selected;
  final bool showBrand;
  final ValueChanged<int> onSelect;
  final VoidCallback onReport;
  static const items = [
    (Icons.dashboard_outlined, 'Dashboard', 0),
    (Icons.edit_note_outlined, 'Report Issue', -1),
    (Icons.description_outlined, 'My Reports', 2),
    (Icons.map_outlined, 'Map View', 1),
    (Icons.notifications_none, 'Notifications', 4),
    (Icons.person_outline, 'Profile', 3),
  ];
  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    decoration: const BoxDecoration(
      color: Color(0xFFF0F1EE),
      border: Border(right: BorderSide(color: Color(0xFFD9DED9))),
    ),
    padding: const EdgeInsets.fromLTRB(14, 16, 12, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBrand) ...[
          const Padding(
            padding: EdgeInsets.only(left: 8, bottom: 22),
            child: PaveoBrandLockup(
              iconSize: 40,
              wordmarkSize: 21,
              showTagline: true,
            ),
          ),
        ],
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: selected == items[i].$3 ? green : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                selected: selected == items[i].$3,
                selectedTileColor: Colors.transparent,
                selectedColor: Colors.white,
                dense: true,
                visualDensity: const VisualDensity(
                  horizontal: -1,
                  vertical: -2,
                ),
                minVerticalPadding: 2,
                minLeadingWidth: 20,
                horizontalTitleGap: 10,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                leading: Icon(
                  items[i].$1,
                  size: 21,
                  color: selected == items[i].$3 ? Colors.white : green,
                ),
                title: Text(
                  items[i].$2,
                  style: TextStyle(
                    color: selected == items[i].$3 ? Colors.white : charcoal,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                onTap: () =>
                    items[i].$3 == -1 ? onReport() : onSelect(items[i].$3),
              ),
            ),
          ),
      ],
    ),
  );
}

class _HomeSurface extends StatelessWidget {
  const _HomeSurface({
    required this.user,
    required this.onReport,
    required this.onMap,
    required this.onReports,
    required this.onProfile,
    required this.onNotifications,
  });
  final User? user;
  final VoidCallback onReport, onMap, onReports, onProfile, onNotifications;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: reports
        .orderBy('createdAt', descending: true)
        .limit(30)
        .snapshots(),
    builder: (context, snapshot) {
      final docs = (snapshot.data?.docs ?? [])
          .where(
            (d) => d.data() is Map<String, dynamic> && d['status'] != 'flagged',
          )
          .toList();
      final mine = docs
          .where((d) => user != null && d['userId'] == user!.uid)
          .toList();
      final first =
          user?.displayName?.split(' ').first ??
          user?.email?.split('@').first ??
          'neighbor';
      if (MediaQuery.sizeOf(context).width < 600) {
        return _mobileHome(
          context,
          docs,
          first,
          loading: !snapshot.hasData && !snapshot.hasError,
          hasError: snapshot.hasError,
          hasData: snapshot.hasData,
        );
      }
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: sage.withValues(alpha: .6)),
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 24,
                    runSpacing: 18,
                    children: [
                      SizedBox(
                        width: 440,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Good day, $first!',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Safer roads start with us.',
                              style: GoogleFonts.poppins(
                                fontSize: 30,
                                height: 1.15,
                                fontWeight: FontWeight.bold,
                                color: charcoal,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Report road hazards in your community and follow every update as crews respond.',
                              style: TextStyle(color: gray, height: 1.5),
                            ),
                            const SizedBox(height: 18),
                            Wrap(
                              spacing: 10,
                              runSpacing: 8,
                              children: [
                                FilledButton.icon(
                                  onPressed: onReport,
                                  icon: const Icon(Icons.add_a_photo_outlined),
                                  label: const Text('Report an issue'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: onMap,
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Explore map'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 200,
                        height: 150,
                        decoration: BoxDecoration(
                          color: ivory.withValues(alpha: .75),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.route_rounded,
                          size: 84,
                          color: green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your impact',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: charcoal,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: onReports,
                      child: const Text('View reports'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      label: 'Total reports',
                      value: '${mine.length}',
                      icon: Icons.flag_outlined,
                      color: green,
                    ),
                    _StatCard(
                      label: 'In progress',
                      value:
                          '${mine.where((d) => d['status'] == 'in_progress').length}',
                      icon: Icons.handyman_outlined,
                      color: const Color(0xFFAA7834),
                    ),
                    _StatCard(
                      label: 'Resolved',
                      value:
                          '${mine.where((d) => d['status'] == 'resolved').length}',
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFF527D70),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent community reports',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: charcoal,
                        ),
                      ),
                    ),
                    TextButton(onPressed: onMap, child: const Text('See map')),
                  ],
                ),
                const SizedBox(height: 8),
                if (snapshot.hasError)
                  const _EmptyMessage(
                    text: 'Reports are temporarily unavailable.',
                  ),
                if (!snapshot.hasData && !snapshot.hasError)
                  const LinearProgressIndicator(),
                if (snapshot.hasData && docs.isEmpty)
                  const _EmptyMessage(
                    text:
                        'No reports yet. Be the first to help your community.',
                  ),
                for (final d in docs.take(4))
                  _ReportTile(
                    doc: d,
                    onTap: () => _showReportDetails(context, d),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );

  Widget _mobileHome(
    BuildContext context,
    List<QueryDocumentSnapshot<Object?>> docs,
    String first, {
    required bool loading,
    required bool hasError,
    required bool hasData,
  }) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Good day,',
                    style: TextStyle(color: gray, fontSize: 17),
                  ),
                  Text(
                    '$first!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      color: charcoal,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: onNotifications,
              icon: const Icon(Icons.notifications_none, color: charcoal),
            ),
            InkWell(
              onTap: onProfile,
              borderRadius: BorderRadius.circular(40),
              child: CircleAvatar(
                radius: 25,
                backgroundColor: lightGreen,
                backgroundImage: user?.photoURL == null
                    ? null
                    : NetworkImage(user!.photoURL!),
                child: user?.photoURL != null
                    ? null
                    : Text(
                        first.isEmpty ? 'P' : first[0].toUpperCase(),
                        style: const TextStyle(
                          color: green,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        TextField(
          readOnly: true,
          onTap: onMap,
          decoration: InputDecoration(
            hintText: 'Search location...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: sage),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: sage),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton.icon(
            onPressed: onReport,
            icon: const Icon(Icons.add_a_photo_outlined),
            label: const Text('Report an issue'),
            style: FilledButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 26),
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Reports',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: charcoal,
                ),
              ),
            ),
            TextButton(onPressed: onReports, child: const Text('See all')),
          ],
        ),
        const SizedBox(height: 6),
        if (loading)
          const LinearProgressIndicator()
        else if (hasError)
          const _EmptyMessage(text: 'Reports are temporarily unavailable.')
        else if (hasData && docs.isEmpty)
          const _EmptyMessage(
            text: 'No reports yet. Be the first to help your community.',
          ),
        for (final doc in docs.take(4))
          _MobileHomeReportCard(
            doc: doc,
            onTap: () => _showReportDetails(context, doc),
          ),
      ],
    ),
  );
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 220,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: charcoal,
                  ),
                ),
                Text(label, style: const TextStyle(color: gray, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _MobileHomeReportCard extends StatelessWidget {
  const _MobileHomeReportCard({required this.doc, required this.onTap});
  final QueryDocumentSnapshot<Object?> doc;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final photo = data['photo'] as String?;
    final created = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final dateLabel = created == null
        ? 'Recently reported'
        : '${created.day} ${_monthName(created.month)} · ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: sage.withValues(alpha: .52)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: photo == null || photo.isEmpty
                    ? Container(
                        width: 78,
                        height: 92,
                        color: lightGreen,
                        child: const Icon(Icons.image_outlined, color: green),
                      )
                    : Image.memory(
                        base64Decode(photo),
                        width: 78,
                        height: 92,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 78,
                          height: 92,
                          color: lightGreen,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['issueType']?.toString() ?? 'Road issue',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        color: charcoal,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['location']?.toString() ?? 'Reported location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: gray,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: gray, fontSize: 11),
                    ),
                    const SizedBox(height: 7),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _StatusPill(
                        status: data['status'] as String? ?? 'pending',
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

  String _monthName(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];
}

class _ReportsSurface extends StatefulWidget {
  const _ReportsSurface({required this.user, required this.onReport});
  final User? user;
  final VoidCallback onReport;
  @override
  State<_ReportsSurface> createState() => _ReportsSurfaceState();
}

class _ReportsSurfaceState extends State<_ReportsSurface> {
  String filter = 'all';
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: widget.user == null
        ? null
        : reports.where('userId', isEqualTo: widget.user!.uid).snapshots(),
    builder: (context, snapshot) {
      final docs = (snapshot.data?.docs ?? [])
          .where((d) => filter == 'all' || d['status'] == filter)
          .toList();
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'My reports',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: charcoal,
            ),
          ),
          const Text(
            'Track the progress of the issues you have reported.',
            style: TextStyle(color: gray),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            children: [
              for (final item in const [
                ('all', 'All'),
                ('pending', 'Pending'),
                ('in_progress', 'In progress'),
                ('resolved', 'Resolved'),
              ])
                ChoiceChip(
                  label: Text(item.$2),
                  selected: filter == item.$1,
                  onSelected: (_) => setState(() => filter = item.$1),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.user == null) _SignInPrompt(onTap: widget.onReport),
          if (widget.user != null && !snapshot.hasData && !snapshot.hasError)
            const Center(child: CircularProgressIndicator()),
          if (snapshot.hasError)
            const _EmptyMessage(
              text: 'Your reports could not be loaded. Please try again later.',
            ),
          if (widget.user != null && snapshot.hasData && docs.isEmpty)
            _EmptyMessage(text: 'No reports in this view yet.'),
          for (final d in docs)
            _ReportTile(doc: d, onTap: () => _showReportDetails(context, d)),
        ],
      );
    },
  );
}

class _NotificationsSurface extends StatelessWidget {
  const _NotificationsSurface({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot>(
    stream: user == null
        ? null
        : reports.where('userId', isEqualTo: user!.uid).snapshots(),
    builder: (context, snapshot) {
      final docs = [...?snapshot.data?.docs]
        ..sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>)['createdAt'];
          final bTime = (b.data() as Map<String, dynamic>)['createdAt'];
          final aDate = aTime is Timestamp ? aTime.toDate() : DateTime(2000);
          final bDate = bTime is Timestamp ? bTime.toDate() : DateTime(2000);
          return bDate.compareTo(aDate);
        });
      return ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Notifications',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: charcoal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Updates about the road issues you have reported.',
            style: TextStyle(color: gray),
          ),
          const SizedBox(height: 20),
          if (user == null)
            const _EmptyMessage(
              text: 'Log in to receive updates about your reports.',
            ),
          if (user != null && !snapshot.hasData && !snapshot.hasError)
            const Center(child: CircularProgressIndicator()),
          if (snapshot.hasError)
            const _EmptyMessage(
              text: 'Notifications could not be loaded right now.',
            ),
          if (user != null && snapshot.hasData && docs.isEmpty)
            const _EmptyMessage(
              text:
                  'You are all caught up. Updates to your reports will appear here.',
            ),
          for (final doc in docs) _ReportNotification(doc: doc),
        ],
      );
    },
  );
}

class _ReportNotification extends StatelessWidget {
  const _ReportNotification({required this.doc});
  final QueryDocumentSnapshot doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'pending';
    final title = switch (status) {
      'in_progress' => 'A crew is working on your report',
      'resolved' => 'Your reported issue was resolved',
      'flagged' => 'Your report is being reviewed',
      _ => 'Your report was received',
    };
    final message = switch (status) {
      'in_progress' =>
        'The maintenance team has started addressing this issue.',
      'resolved' => 'The maintenance team marked this issue as resolved.',
      'flagged' => 'The team is checking this report for a possible duplicate.',
      _ => 'Your report is in the queue for review.',
    };
    final color = statusColors[status] ?? statusPending;
    final timestamp = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final timeLabel = timestamp == null
        ? 'Just now'
        : '${timestamp.day}/${timestamp.month}/${timestamp.year} · ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    final issue = data['issueType'] ?? 'Road issue';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .25),
          child: Icon(
            status == 'resolved'
                ? Icons.check_circle_outline
                : status == 'in_progress'
                ? Icons.handyman_outlined
                : status == 'flagged'
                ? Icons.fact_check_outlined
                : Icons.assignment_turned_in_outlined,
            color: charcoal,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, color: charcoal),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '$issue · $message\n$timeLabel',
            style: const TextStyle(color: gray, height: 1.5),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.doc, required this.onTap});
  final QueryDocumentSnapshot doc;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final status = doc.data() is Map<String, dynamic>
        ? (doc['status'] as String? ?? 'pending')
        : 'pending';
    final data = doc.data() as Map<String, dynamic>;
    final photo = data['photo'] as String?;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: photo == null || photo.isEmpty
              ? Container(
                  width: 64,
                  height: 64,
                  color: lightGreen,
                  child: const Icon(Icons.broken_image_outlined, color: sage),
                )
              : Image.memory(
                  base64Decode(photo),
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: lightGreen,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
                ),
        ),
        title: Text(
          data['description']?.toString().trim().isNotEmpty == true
              ? data['description']
              : (data['issueType'] ?? 'Road issue'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, color: charcoal),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, size: 14, color: gray),
              const SizedBox(width: 3),
              Expanded(
                child: Text(
                  '${data['lat'] ?? 'Location'}${data['lat'] != null ? ', ${data['lng']}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: gray),
                ),
              ),
              const SizedBox(width: 8),
              _StatusPill(status: status),
            ],
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: gray),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;
  @override
  Widget build(BuildContext context) {
    final color = statusColors[status] ?? lightGreen;
    final label =
        {
          'pending': 'Reported',
          'in_progress': 'In progress',
          'resolved': 'Resolved',
          'flagged': 'Under review',
        }[status] ??
        status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),
    );
  }
}

class _ProfileSurface extends StatefulWidget {
  const _ProfileSurface({
    required this.user,
    required this.onLogin,
    required this.onHome,
  });
  final User? user;
  final VoidCallback onLogin;
  final VoidCallback onHome;

  @override
  State<_ProfileSurface> createState() => _ProfileSurfaceState();
}

class _ProfileSurfaceState extends State<_ProfileSurface> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  bool editing = false;
  bool saving = false;
  bool emailUpdates = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void didUpdateWidget(covariant _ProfileSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.uid != widget.user?.uid) _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = widget.user;
    name.text = user?.displayName ?? '';
    phone.clear();
    address.clear();
    if (user != null) {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted || widget.user?.uid != user.uid) return;
      final data = profile.data() ?? {};
      name.text = (data['name'] ?? user.displayName ?? '').toString();
      phone.text = (data['contactNumber'] ?? '').toString();
      address.text = (data['address'] ?? '').toString();
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    address.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final user = widget.user;
    if (user == null) return;
    setState(() => saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
            'name': name.text.trim(),
            'contactNumber': phone.text.trim(),
            'address': address.text.trim(),
          });
      await user.updateDisplayName(name.text.trim());
      if (mounted) setState(() => editing = false);
      if (mounted) _message(context, 'Profile saved.');
    } catch (_) {
      if (mounted)
        _message(context, 'Could not save your profile. Please try again.');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _changePassword() async {
    final email = widget.user?.email;
    if (email == null) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted)
        _message(context, 'Password reset instructions were sent to $email.');
    } on FirebaseAuthException catch (error) {
      if (mounted)
        _message(context, error.message ?? 'Could not send a reset email.');
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 720;
      final displayName = name.text.trim().isNotEmpty
          ? name.text.trim()
          : widget.user?.displayName ?? 'Paveo member';
      if (MediaQuery.sizeOf(context).width < 600) {
        return _mobileProfile(context, displayName);
      }
      final details = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: lightGreen,
                  child: Text(
                    (displayName.isNotEmpty ? displayName[0] : 'P')
                        .toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      color: green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: charcoal,
                        ),
                      ),
                      Text(
                        widget.user?.email ?? 'Sign in to manage your account',
                        style: const TextStyle(color: gray, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _profileField('Full name', name),
            const SizedBox(height: 12),
            _emailProfileField(),
            const SizedBox(height: 12),
            _profileField(
              'Contact number',
              phone,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _profileField('Address', address),
            if (widget.user != null && editing) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: saving ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: Text(saving ? 'Saving…' : 'Save profile'),
              ),
            ],
          ],
        ),
      );
      final accountStatus = widget.user == null
          ? const SizedBox.shrink()
          : StreamBuilder<QuerySnapshot>(
              stream: reports
                  .where('userId', isEqualTo: widget.user!.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final inProgress = docs
                    .where((d) => d['status'] == 'in_progress')
                    .length;
                final resolved = docs
                    .where((d) => d['status'] == 'resolved')
                    .length;
                return Card(
                  color: Colors.white,
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: green.withValues(alpha: .18)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Status',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: charcoal,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: _profileMetric(
                                '${docs.length}',
                                'Total reports',
                                green,
                              ),
                            ),
                            Expanded(
                              child: _profileMetric(
                                '$inProgress',
                                'In progress',
                                const Color(0xFFE9BF7D),
                              ),
                            ),
                            Expanded(
                              child: _profileMetric(
                                '$resolved',
                                'Resolved',
                                const Color(0xFF8FA893),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

      return ListView(
        padding: EdgeInsets.fromLTRB(
          wide ? 32 : 14,
          wide ? 24 : 14,
          wide ? 32 : 14,
          wide ? 32 : 14,
        ),
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: constraints.maxWidth * 0.96,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Profile',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: charcoal,
                              ),
                            ),
                            Text(
                              'Manage your account information.',
                              style: const TextStyle(color: gray, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      if (widget.user != null)
                        OutlinedButton.icon(
                          onPressed: () => setState(() => editing = !editing),
                          style: OutlinedButton.styleFrom(
                            visualDensity: const VisualDensity(
                              horizontal: -2,
                              vertical: -2,
                            ),
                            textStyle: const TextStyle(fontSize: 14),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                          ),
                          icon: Icon(
                            editing ? Icons.close : Icons.edit_outlined,
                            size: 16,
                          ),
                          label: Text(editing ? 'Cancel' : 'Edit Profile'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 10, child: details),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 9,
                          child: Column(
                            children: [
                              accountStatus,
                              const SizedBox(height: 14),
                              _profileActions(context),
                            ],
                          ),
                        ),
                      ],
                    )
                  else ...[
                    details,
                    const SizedBox(height: 16),
                    accountStatus,
                    const SizedBox(height: 12),
                    _profileActions(context),
                  ],
                ],
              ),
            ),
          ),
        ],
      );
    },
  );

  Widget _mobileProfile(BuildContext context, String displayName) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
    children: [
      Row(
        children: [
          IconButton(
            tooltip: 'Back to home',
            onPressed: widget.onHome,
            icon: const Icon(Icons.arrow_back, color: charcoal),
          ),
          const Spacer(),
          if (widget.user != null)
            IconButton(
              tooltip: editing ? 'Cancel editing' : 'Edit profile',
              onPressed: () => setState(() => editing = !editing),
              icon: Icon(
                editing ? Icons.close : Icons.edit_outlined,
                color: charcoal,
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Center(
        child: CircleAvatar(
          radius: 62,
          backgroundColor: lightGreen,
          backgroundImage: widget.user?.photoURL == null
              ? null
              : NetworkImage(widget.user!.photoURL!),
          child: widget.user?.photoURL != null
              ? null
              : Text(
                  displayName.isEmpty ? 'P' : displayName[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: green,
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        displayName,
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: charcoal,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        widget.user?.email ?? 'Sign in to manage your account',
        textAlign: TextAlign.center,
        style: GoogleFonts.poppins(
          color: gray,
          fontSize: 17,
          fontWeight: FontWeight.w500,
        ),
      ),
      if (editing) ...[
        const SizedBox(height: 22),
        _profileField('Full name', name),
        const SizedBox(height: 12),
        _profileField(
          'Contact number',
          phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 12),
        _profileField('Address', address),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: FilledButton.icon(
            onPressed: saving ? null : _save,
            icon: const Icon(Icons.save_outlined),
            label: Text(saving ? 'Saving…' : 'Save profile'),
          ),
        ),
      ],
      const SizedBox(height: 26),
      Card(
        color: ivory,
        elevation: 3,
        shadowColor: charcoal.withValues(alpha: .15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Column(
          children: [
            _mobileProfileAction(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: widget.user == null ? widget.onLogin : _changePassword,
            ),
            const Divider(height: 1, indent: 60, endIndent: 20),
            _mobileProfileAction(
              icon: Icons.notifications_none,
              title: 'Notification Settings',
              onTap: () => showDialog<void>(
                context: context,
                builder: (dialogContext) => StatefulBuilder(
                  builder: (context, setDialogState) => AlertDialog(
                    title: const Text('Notification settings'),
                    content: SwitchListTile(
                      value: emailUpdates,
                      onChanged: (value) {
                        setState(() => emailUpdates = value);
                        setDialogState(() {});
                      },
                      title: const Text('Email updates'),
                      subtitle: const Text(
                        'Receive updates about your reports.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1, indent: 60, endIndent: 20),
            _mobileProfileAction(
              icon: Icons.support_agent_outlined,
              title: 'Help and Support',
              onTap: () => _message(
                context,
                'For help, contact your local road maintenance office.',
              ),
            ),
            if (widget.user != null) ...[
              const Divider(height: 1, indent: 60, endIndent: 20),
              _mobileProfileAction(
                icon: Icons.logout,
                title: 'Log out',
                color: Colors.redAccent,
                trailing: false,
                onTap: () async => FirebaseAuth.instance.signOut(),
              ),
            ],
          ],
        ),
      ),
    ],
  );

  Widget _mobileProfileAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = charcoal,
    bool trailing = true,
  }) => ListTile(
    minTileHeight: 76,
    contentPadding: const EdgeInsets.symmetric(horizontal: 22),
    leading: Icon(icon, size: 28, color: color),
    title: Text(
      title,
      style: TextStyle(fontSize: 17, color: color, fontWeight: FontWeight.w500),
    ),
    trailing: trailing
        ? const Icon(Icons.chevron_right, size: 28, color: gray)
        : null,
    onTap: onTap,
  );

  Widget _profileField(
    String label,
    TextEditingController controller, {
    bool readOnly = false,
    TextInputType? keyboardType,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: gray,
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 36,
        child: TextField(
          controller: controller,
          readOnly: readOnly || !editing,
          keyboardType: keyboardType,
          style: const TextStyle(fontSize: 14),
          decoration: _profileInputDecoration(),
        ),
      ),
    ],
  );

  Widget _emailProfileField() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Email',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: gray,
        ),
      ),
      const SizedBox(height: 4),
      SizedBox(
        height: 36,
        child: TextFormField(
          initialValue: widget.user?.email ?? '',
          readOnly: true,
          style: const TextStyle(fontSize: 14),
          decoration: _profileInputDecoration(),
        ),
      ),
    ],
  );

  InputDecoration _profileInputDecoration() => InputDecoration(
    isDense: true,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: sage, width: 0.8),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: sage, width: 0.8),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: const BorderSide(color: green, width: 1),
    ),
  );

  Widget _profileActions(BuildContext context) => Card(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: green.withValues(alpha: .18)),
    ),
    child: Column(
      children: [
        ListTile(
          dense: true,
          minTileHeight: 48,
          visualDensity: const VisualDensity(vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          minLeadingWidth: 24,
          horizontalTitleGap: 12,
          leading: const Icon(Icons.lock_outline, color: green, size: 20),
          title: const Text(
            'Change Password',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: widget.user == null ? widget.onLogin : _changePassword,
        ),
        const Divider(height: 1),
        ListTile(
          dense: true,
          minTileHeight: 48,
          visualDensity: const VisualDensity(vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          minLeadingWidth: 24,
          horizontalTitleGap: 12,
          leading: const Icon(Icons.notifications_none, color: green, size: 20),
          title: const Text(
            'Notification Settings',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => showDialog<void>(
            context: context,
            builder: (dialogContext) => StatefulBuilder(
              builder: (context, setDialogState) => AlertDialog(
                title: const Text('Notification settings'),
                content: SwitchListTile(
                  value: emailUpdates,
                  onChanged: (value) {
                    setState(() => emailUpdates = value);
                    setDialogState(() {});
                  },
                  title: const Text('Email updates'),
                  subtitle: const Text('Receive updates about your reports.'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (kIsWeb) ...[
          const Divider(height: 1),
          ListTile(
            dense: true,
            minTileHeight: 48,
            visualDensity: const VisualDensity(vertical: -2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            minLeadingWidth: 24,
            horizontalTitleGap: 12,
            leading: const Icon(Icons.android, color: green, size: 20),
            title: const Text(
              'Download app',
              maxLines: 1,
              softWrap: false,
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.download_outlined, size: 20),
            onTap: paveo_download.openAndroidDownload,
          ),
        ],
        const Divider(height: 1),
        ListTile(
          dense: true,
          minTileHeight: 48,
          visualDensity: const VisualDensity(vertical: -2),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          minLeadingWidth: 24,
          horizontalTitleGap: 12,
          leading: const Icon(
            Icons.support_agent_outlined,
            color: green,
            size: 20,
          ),
          title: const Text(
            'Help and Support',
            maxLines: 1,
            softWrap: false,
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => _message(
            context,
            'For help, contact your local road maintenance office.',
          ),
        ),
        if (widget.user != null) ...[
          const Divider(height: 1),
          ListTile(
            dense: true,
            minTileHeight: 48,
            visualDensity: const VisualDensity(vertical: -2),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14),
            minLeadingWidth: 24,
            horizontalTitleGap: 12,
            leading: const Icon(
              Icons.logout,
              color: Colors.redAccent,
              size: 20,
            ),
            title: const Text(
              'Log out',
              style: TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            onTap: () async => FirebaseAuth.instance.signOut(),
          ),
        ] else
          ListTile(
            leading: const Icon(Icons.login, color: green),
            title: const Text('Log in'),
            onTap: widget.onLogin,
          ),
      ],
    ),
  );

  Widget _profileMetric(String value, String label, Color color) => Column(
    children: [
      CircleAvatar(radius: 18, backgroundColor: color),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          height: 1,
          color: charcoal,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 10,
          height: 1,
          color: gray,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );
}

class _EmptyMessage extends StatelessWidget {
  const _EmptyMessage({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: lightGreen.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(color: gray),
    ),
  );
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.lock_outline, color: sage, size: 44),
          const SizedBox(height: 10),
          const Text(
            'Log in to see your reports',
            style: TextStyle(color: charcoal, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          FilledButton(
            onPressed: onTap,
            child: const Text('Log in or create account'),
          ),
        ],
      ),
    ),
  );
}

void _message(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

void _showReportDetails(BuildContext context, QueryDocumentSnapshot doc) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _ReportDetailPage(doc: doc)),
  );
}

class _ReportDetailPage extends StatelessWidget {
  const _ReportDetailPage({required this.doc});
  final QueryDocumentSnapshot doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final rawPhotos = data['photos'];
    final photoData = rawPhotos is List
        ? rawPhotos.whereType<String>().toList()
        : data['photo'] is String
        ? [data['photo'] as String]
        : <String>[];
    final status = data['status'] as String? ?? 'pending';
    final created = data['createdAt'] is Timestamp
        ? (data['createdAt'] as Timestamp).toDate()
        : null;
    final wide = MediaQuery.sizeOf(context).width > 900;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                data['issueType'] ?? 'Road issue',
                style: GoogleFonts.poppins(
                  fontSize: 25,
                  fontWeight: FontWeight.w600,
                  color: charcoal,
                ),
              ),
            ),
            _StatusPill(status: status),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Report #${doc.id.substring(0, doc.id.length < 8 ? doc.id.length : 8)}',
          style: const TextStyle(color: gray, fontSize: 12),
        ),
        const SizedBox(height: 18),
        if (photoData.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.memory(
              base64Decode(photoData.first),
              height: wide ? 370 : 230,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        if (photoData.length > 1) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final encoded in photoData.skip(1))
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    base64Decode(encoded),
                    width: 82,
                    height: 70,
                    fit: BoxFit.cover,
                  ),
                ),
            ],
          ),
        ],
        const SizedBox(height: 18),
        Text(
          data['description']?.toString().isNotEmpty == true
              ? data['description']
              : 'No description provided.',
          style: const TextStyle(color: charcoal, height: 1.5),
        ),
        const SizedBox(height: 20),
        Text(
          'Report details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: charcoal,
          ),
        ),
        _ReviewLine(
          label: 'Issue type',
          value: data['issueType'] ?? 'Road issue',
        ),
        _ReviewLine(label: 'Severity', value: data['severity'] ?? 'medium'),
        _ReviewLine(
          label: 'Location',
          value: '${data['lat'] ?? 'Unknown'}, ${data['lng'] ?? 'Unknown'}',
        ),
        _ReviewLine(
          label: 'Date reported',
          value: created == null
              ? 'Date unavailable'
              : '${created.day}/${created.month}/${created.year} · ${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}',
        ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 6, child: content),
                      const SizedBox(width: 36),
                      Expanded(
                        flex: 4,
                        child: _StatusTimeline(
                          status: status,
                          created: created,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      content,
                      const SizedBox(height: 24),
                      _StatusTimeline(status: status, created: created),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _StatusTimeline extends StatelessWidget {
  const _StatusTimeline({required this.status, required this.created});
  final String status;
  final DateTime? created;
  @override
  Widget build(BuildContext context) {
    final active = status == 'resolved'
        ? 2
        : status == 'in_progress'
        ? 1
        : 0;
    const labels = ['Reported', 'In progress', 'Resolved'];
    const notes = [
      'Your report was submitted.',
      'The team is reviewing and addressing the issue.',
      'The reported issue has been marked resolved.',
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status updates',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: charcoal,
              ),
            ),
            const SizedBox(height: 18),
            for (var i = 0; i < labels.length; i++)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: i <= active
                            ? (i == active ? green : sage)
                            : lightGray,
                        child: Icon(
                          i < active ? Icons.check : Icons.circle,
                          size: i < active ? 14 : 7,
                          color: ivory,
                        ),
                      ),
                      if (i < labels.length - 1)
                        Container(
                          width: 2,
                          height: 48,
                          color: i < active ? sage : lightGray,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2, bottom: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            labels[i],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: i <= active ? charcoal : gray,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            i == 0 && created != null
                                ? '${notes[i]} ${created!.day}/${created!.month}/${created!.year}'
                                : notes[i],
                            style: const TextStyle(
                              fontSize: 12,
                              color: gray,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            if (status == 'flagged')
              const Text(
                'This report is being checked for a possible duplicate.',
                style: TextStyle(color: gray, fontSize: 12),
              ),
          ],
        ),
      ),
    );
  }
}

class ReportWizardPage extends StatefulWidget {
  const ReportWizardPage({
    super.key,
    this.onNavigate,
    this.onComplete,
    this.embedded = false,
  });
  final ValueChanged<int>? onNavigate;
  final ValueChanged<bool>? onComplete;
  final bool embedded;
  @override
  State<ReportWizardPage> createState() => _ReportWizardPageState();
}

class _ReportWizardPageState extends State<ReportWizardPage> {
  final description = TextEditingController();
  final picker = ImagePicker();
  final mapController = MapController();
  int step = 0;
  String type = 'Pothole';
  String severity = 'medium';
  LatLng location = const LatLng(14.8527, 120.816);
  final List<XFile> photos = [];
  XFile? get photo => photos.isEmpty ? null : photos.first;
  bool saving = false;
  bool locating = false;
  static const steps = ['Details', 'Location', 'Photo', 'Review'];

  void _finish({required bool submitted}) {
    final onComplete = widget.onComplete;
    if (onComplete != null) {
      onComplete(submitted);
    } else {
      Navigator.pop(context, submitted);
    }
  }

  void _leave() {
    final onNavigate = widget.onNavigate;
    if (onNavigate != null) {
      onNavigate(0);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    description.dispose();
    super.dispose();
  }

  Future<void> _useLocation() async {
    setState(() => locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied)
        permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _message(
          context,
          'Location access is off. Move the pin to set the report location.',
        );
      } else {
        final p = await Geolocator.getCurrentPosition();
        if (mounted) {
          setState(() => location = LatLng(p.latitude, p.longitude));
          mapController.move(location, 15);
        }
      }
    } catch (_) {
      if (mounted)
        _message(
          context,
          'Could not get your location. Move the pin to set it manually.',
        );
    }
    if (mounted) setState(() => locating = false);
  }

  Future<void> _pickPhoto(ImageSource source) async {
    if (source == ImageSource.gallery) {
      final remaining = 5 - photos.length;
      if (remaining <= 0) return;
      final selectedPhotos = await picker.pickMultiImage(
        maxWidth: 800,
        imageQuality: 45,
      );
      if (selectedPhotos.isNotEmpty && mounted) {
        setState(() => photos.addAll(selectedPhotos.take(remaining)));
      }
      return;
    }
    if (photos.length >= 5) return;
    final selectedPhoto = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 45,
    );
    if (selectedPhoto != null && mounted)
      setState(() => photos.add(selectedPhoto));
  }

  bool _next() {
    if (step == 0 && description.text.trim().length > 200) {
      _message(context, 'Keep the description under 200 characters.');
      return false;
    }
    if (step == 2 && photo == null) {
      _message(context, 'Add a photo so the road issue can be reviewed.');
      return false;
    }
    if (step < 3) setState(() => step++);
    return true;
  }

  Future<void> _submit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || photos.isEmpty) return;
    setState(() => saving = true);
    try {
      final encodedPhotos = <String>[];
      final primaryPhoto = await photos.first.readAsBytes();
      for (final image in photos) {
        encodedPhotos.add(base64Encode(await image.readAsBytes()));
      }
      const radius = 0.0002;
      final nearbyReports = await reports
          .where('lat', isGreaterThan: location.latitude - radius)
          .where('lat', isLessThan: location.latitude + radius)
          .get();
      final nearby = nearbyReports.docs
          .where(
            (report) =>
                report['status'] != 'flagged' &&
                report['status'] != 'resolved' &&
                Geolocator.distanceBetween(
                      location.latitude,
                      location.longitude,
                      report['lat'],
                      report['lng'],
                    ) <=
                    20,
          )
          .firstOrNull;
      String? duplicateId;
      if (nearby != null && nearby.data() is Map<String, dynamic>) {
        final nearbyPhoto = (nearby.data() as Map<String, dynamic>)['photo'];
        if (nearbyPhoto is String && nearbyPhoto.isNotEmpty) {
          final match =
              (await comparePhotos(primaryPhoto, base64Decode(nearbyPhoto)) *
                      100)
                  .round();
          if (!mounted) return;
          final sameReport = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Nearby road issue found'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'A report was found within 20 meters ($match% visual match). Is this the same issue?',
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      base64Decode(nearbyPhoto),
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Different issue'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Same issue'),
                ),
              ],
            ),
          );
          if (sameReport == null) return;
          if (sameReport) {
            await reports.doc(nearby.id).update({
              'confirmedBy': FieldValue.arrayUnion([user.uid]),
            });
            if (mounted) _finish(submitted: true);
            return;
          }
          duplicateId = nearby.id;
        }
      }
      await reports.add({
        'userId': user.uid,
        'lat': location.latitude,
        'lng': location.longitude,
        'photo': encodedPhotos.first,
        'photos': encodedPhotos,
        'description': description.text.trim(),
        'issueType': type,
        'severity': severity,
        'status': duplicateId == null ? 'pending' : 'flagged',
        'duplicateOf': duplicateId,
        'confirmedBy': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _finish(submitted: true);
    } catch (_) {
      if (mounted)
        _message(
          context,
          'Your report could not be sent. Check your connection and try again.',
        );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    if (widget.embedded) return _wizardContent(context, wide: true);
    return Scaffold(
      backgroundColor: ivory,
      appBar: wide
          ? null
          : AppBar(
              title: const Text('Report an issue'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () =>
                    step == 0 ? Navigator.pop(context) : setState(() => step--),
              ),
            ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: wide
                  ? Row(
                      children: [
                        _SideNav(
                          selected: -1,
                          showBrand: true,
                          onSelect:
                              widget.onNavigate ??
                              (_) => Navigator.pop(context),
                          onReport: () {},
                        ),
                        Expanded(child: _wizardContent(context, wide: true)),
                      ],
                    )
                  : _wizardContent(context, wide: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wizardContent(BuildContext context, {required bool wide}) => Center(
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: wide ? 1100 : 820),
      child: Column(
        children: [
          if (wide)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report an Issue',
                      style: GoogleFonts.poppins(
                        fontSize: 26,
                        fontWeight: FontWeight.w600,
                        color: charcoal,
                      ),
                    ),
                    const Text(
                      'Help us keep our roads safe. Fill in the details below.',
                      style: TextStyle(color: gray),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
            child: Row(
              children: [
                for (var i = 0; i < steps.length; i++)
                  Expanded(
                    child: _WizardStep(
                      index: i,
                      current: step,
                      label: steps[i],
                      wide: wide,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 22),
              child: _stepBody(context, wide: wide),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Row(
              children: [
                if (step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => step--),
                      child: const Text('Back'),
                    ),
                  )
                else if (wide)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _leave,
                      child: const Text('Cancel'),
                    ),
                  ),
                if (step > 0 || wide) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: saving
                        ? null
                        : step == 3
                        ? _submit
                        : _next,
                    child: saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(step == 3 ? 'Submit report' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _stepBody(BuildContext context, {required bool wide}) {
    switch (step) {
      case 0:
        if (!wide) return _detailsStep();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _detailsStep()),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                height: 210,
                margin: const EdgeInsets.only(top: 32),
                decoration: BoxDecoration(
                  color: sage.withValues(alpha: .26),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sage.withValues(alpha: .55)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 56,
                      color: sage,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'You can add a photo in the next step.',
                      style: TextStyle(color: gray),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      case 1:
        return _locationStep();
      case 2:
        return _photoStep(context);
      default:
        return _reviewStep();
    }
  }

  Widget _detailsStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Tell us about the issue',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'A few details help the right team respond.',
        style: TextStyle(color: gray),
      ),
      const SizedBox(height: 22),
      const Text(
        'Issue type',
        style: TextStyle(fontWeight: FontWeight.w600, color: charcoal),
      ),
      const SizedBox(height: 8),
      DropdownButtonFormField<String>(
        value: type,
        decoration: const InputDecoration(),
        items: const [
          'Pothole',
          'Cracked pavement',
          'Road obstruction',
          'Flooding',
          'Other',
        ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => type = v ?? type),
      ),
      const SizedBox(height: 18),
      const Text(
        'Severity',
        style: TextStyle(fontWeight: FontWeight.w600, color: charcoal),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        children: [
          for (final s in const ['low', 'medium', 'high'])
            ChoiceChip(
              label: Text(s[0].toUpperCase() + s.substring(1)),
              selected: severity == s,
              onSelected: (_) => setState(() => severity = s),
            ),
        ],
      ),
      const SizedBox(height: 18),
      const Text(
        'Description (optional)',
        style: TextStyle(fontWeight: FontWeight.w600, color: charcoal),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: description,
        maxLength: 200,
        maxLines: 5,
        decoration: const InputDecoration(
          hintText: 'Describe what you see and any nearby landmarks...',
          alignLabelWithHint: true,
        ),
      ),
    ],
  );

  Widget _locationStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Pin the location',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'Drag the map to place the marker on the issue.',
        style: TextStyle(color: gray),
      ),
      const SizedBox(height: 16),
      ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 390,
          child: FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: location,
              initialZoom: 14,
              onPositionChanged: (position, _) {
                if (position.center != null) location = position.center!;
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.paveo.paveo_app',
              ),
            ],
          ),
        ),
      ),
      Transform.translate(
        offset: const Offset(0, -214),
        child: const Center(
          child: Icon(Icons.location_pin, color: Color(0xFFC56D62), size: 40),
        ),
      ),
      OutlinedButton.icon(
        onPressed: locating ? null : _useLocation,
        icon: locating
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.my_location),
        label: const Text('Use my current location'),
      ),
      const SizedBox(height: 4),
      Text(
        'Selected: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
        style: const TextStyle(color: gray, fontSize: 12),
      ),
    ],
  );

  Widget _photoStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Add a photo',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'Photos help verify the issue and plan a repair.',
        style: TextStyle(color: gray),
      ),
      const SizedBox(height: 18),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: lightGreen.withValues(alpha: .55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: sage.withValues(alpha: .6)),
        ),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < photos.length; i++)
              SizedBox(
                width: 112,
                height: 112,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: FutureBuilder<List<int>>(
                          future: photos[i].readAsBytes(),
                          builder: (_, snapshot) => snapshot.hasData
                              ? Image.memory(
                                  Uint8List.fromList(snapshot.data!),
                                  fit: BoxFit.cover,
                                )
                              : const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: IconButton.filledTonal(
                        onPressed: () => setState(() => photos.removeAt(i)),
                        icon: const Icon(Icons.close, size: 16),
                        style: IconButton.styleFrom(
                          backgroundColor: ivory,
                          minimumSize: const Size(28, 28),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (photos.length < 5)
              InkWell(
                onTap: () => _showPhotoOptions(context),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: ivory,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sage),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 30,
                        color: green,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Add photo',
                        style: TextStyle(
                          fontSize: 11,
                          color: charcoal,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (photos.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Add at least one clear photo. You can include up to five.',
                  style: TextStyle(color: gray, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${photos.length} of 5 photos added',
        style: const TextStyle(color: gray, fontSize: 12),
      ),
    ],
  );

  Widget _reviewStep() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Review your report',
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),
      const SizedBox(height: 5),
      const Text(
        'Check the details before sending it to the community team.',
        style: TextStyle(color: gray),
      ),
      const SizedBox(height: 18),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final image in photos)
            FutureBuilder<List<int>>(
              future: image.readAsBytes(),
              builder: (_, s) => s.hasData
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        Uint8List.fromList(s.data!),
                        height: 90,
                        width: 110,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const SizedBox(
                      height: 90,
                      width: 110,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      _ReviewLine(label: 'Issue type', value: type),
      _ReviewLine(label: 'Severity', value: severity),
      _ReviewLine(
        label: 'Location',
        value:
            '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
      ),
      _ReviewLine(
        label: 'Description',
        value: description.text.trim().isEmpty
            ? 'No description'
            : description.text.trim(),
      ),
    ],
  );

  void _showPhotoOptions(BuildContext context) => showModalBottomSheet(
    context: context,
    builder: (c) => SafeArea(
      child: Wrap(
        children: [
          if (photos.length < 5)
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(c);
                _pickPhoto(ImageSource.camera);
              },
            ),
          if (photos.length < 5)
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(c);
                _pickPhoto(ImageSource.gallery);
              },
            ),
        ],
      ),
    ),
  );
}

class _WizardStep extends StatelessWidget {
  const _WizardStep({
    required this.index,
    required this.current,
    required this.label,
    required this.wide,
  });
  final int index, current;
  final String label;
  final bool wide;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      if (index > 0)
        Expanded(
          child: Container(
            height: 2,
            color: index <= current ? green : lightGray,
          ),
        ),
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: index <= current ? green : lightGreen,
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: index <= current ? ivory : gray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      if (wide)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: index == current ? charcoal : gray,
              fontWeight: index == current
                  ? FontWeight.w600
                  : FontWeight.normal,
            ),
          ),
        ),
      if (index < 3)
        Expanded(
          child: Container(
            height: 2,
            color: index < current ? green : lightGray,
          ),
        ),
    ],
  );
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: const TextStyle(color: gray)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: charcoal,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    ),
  );
}
