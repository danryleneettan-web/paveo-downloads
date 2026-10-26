import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand.dart';
import 'login_page.dart';
import 'admin_page.dart';
import 'similarity.dart';
import 'download_link_stub.dart'
    if (dart.library.js_interop) 'download_link_web.dart'
    as paveo_download;

const labels = {
  'pending': 'Pending',
  'in_progress': 'In progress',
  'resolved': 'Resolved',
  'flagged': 'Flagged for review',
};

final reports = FirebaseFirestore.instance.collection('reports');

class MapPage extends StatefulWidget {
  const MapPage({super.key, this.embedded = false, this.onReport});

  final bool embedded;
  final VoidCallback? onReport;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  User? user;
  bool admin = false;
  String mapSearch = '';
  String statusFilter = 'all';
  String typeFilter = 'all';
  final mapController = MapController();
  late final Stream<QuerySnapshot> reportStream;

  @override
  void initState() {
    super.initState();
    reportStream = reports.snapshots();
    FirebaseAuth.instance.authStateChanges().listen((u) async {
      var a = false;
      if (u != null) {
        final d = await FirebaseFirestore.instance
            .collection('users')
            .doc(u.uid)
            .get();
        a = d.data()?['role'] == 'admin';
      }
      if (mounted) {
        setState(() {
          user = u;
          admin = a;
        });
      }
    });
  }

  void confirm(String id) => reports.doc(id).update({
    'confirmedBy': FieldValue.arrayUnion([user!.uid]),
  });

  Future<void> save(
    Map<String, String> info,
    String photo,
    Position p,
    String? dup,
  ) => reports.add({
    'userId': user!.uid,
    'lat': p.latitude,
    'lng': p.longitude,
    'photo': photo,
    'description': info['description'],
    'severity': info['severity'],
    'status': dup == null ? 'pending' : 'flagged',
    'duplicateOf': dup,
    'confirmedBy': [],
    'createdAt': FieldValue.serverTimestamp(),
  });

  Future<Map<String, String>?> ask() {
    final t = TextEditingController();
    var sev = 'medium';
    return showDialog<Map<String, String>>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Report a pothole'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: t,
                decoration: const InputDecoration(
                  labelText: 'What does it look like?',
                ),
              ),
              DropdownButton<String>(
                value: sev,
                isExpanded: true,
                items: [
                  for (final s in ['low', 'medium', 'high'])
                    DropdownMenuItem(value: s, child: Text(s)),
                ],
                onChanged: (v) => set(() => sev = v!),
              ),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () =>
                  Navigator.pop(c, {'description': t.text, 'severity': sev}),
              child: const Text('Send report'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> report() async {
    await Geolocator.requestPermission();
    final f = await ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      imageQuality: 40,
    );
    if (f == null) return;
    final photoBytes = await f.readAsBytes();
    final photo = base64Encode(photoBytes);
    final p = await Geolocator.getCurrentPosition();
    final info = await ask();
    if (info == null) return;
    const r = 0.0002;
    final q = await reports
        .where('lat', isGreaterThan: p.latitude - r)
        .where('lat', isLessThan: p.latitude + r)
        .get();
    final near = q.docs
        .where(
          (d) =>
              d['status'] != 'flagged' &&
              d['status'] != 'resolved' &&
              Geolocator.distanceBetween(
                    p.latitude,
                    p.longitude,
                    d['lat'],
                    d['lng'],
                  ) <=
                  20,
        )
        .firstOrNull;
    if (near == null) return save(info, photo, p, null);

    final nearBytes = base64Decode(near['photo']);
    final similarity = await comparePhotos(photoBytes, nearBytes);
    final matchPercent = (similarity * 100).toInt();

    if (!mounted) return;
    final same = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nearby Pothole Detected'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'A pothole was reported within 20m ($matchPercent% visual match).',
            ),
            const SizedBox(height: 8),
            Image.memory(nearBytes),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Different pothole'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Same pothole'),
          ),
        ],
      ),
    );
    if (same == null) return;
    same ? confirm(near.id) : save(info, photo, p, near.id);
  }

  void detail(QueryDocumentSnapshot d) {
    final count = List.from(d['confirmedBy']).length;
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.memory(
                base64Decode(d['photo']),
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              labels[d['status']]!,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: charcoal,
              ),
            ),
            Text(d['description'] ?? ''),
            Text('Severity: ${d['severity']}, $count confirmation(s)'),
            Row(
              children: [
                if (user != null)
                  TextButton(
                    onPressed: () {
                      confirm(d.id);
                      Navigator.pop(context);
                    },
                    child: const Text('Confirm'),
                  ),
                if (admin)
                  DropdownButton<String>(
                    value: d['status'],
                    items: [
                      for (final k in labels.keys)
                        DropdownMenuItem(value: k, child: Text(labels[k]!)),
                    ],
                    onChanged: (v) {
                      reports.doc(d.id).update({'status': v});
                      Navigator.pop(context);
                    },
                  ),
                if (admin)
                  TextButton(
                    onPressed: () {
                      reports.doc(d.id).delete();
                      Navigator.pop(context);
                    },
                    child: const Text('Delete'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: widget.embedded
        ? null
        : AppBar(
            backgroundColor: ivory,
            title: const PaveoBrandLockup(
              iconSize: 38,
              wordmarkSize: 20,
              showTagline: false,
            ),
            actions: [
              if (kIsWeb)
                TextButton.icon(
                  onPressed: paveo_download.openAndroidDownload,
                  icon: const Icon(Icons.android),
                  label: const Text('Download app'),
                ),
              if (admin)
                FilledButton.icon(
                  icon: const Icon(Icons.admin_panel_settings, size: 16),
                  label: const Text('Admin Dashboard'),
                  style: FilledButton.styleFrom(backgroundColor: charcoal),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPage()),
                  ),
                ),
              if (user != null)
                TextButton(
                  onPressed: FirebaseAuth.instance.signOut,
                  child: const Text('Log out'),
                )
              else ...[
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  ),
                  child: const Text('Log in'),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
    body: StreamBuilder<QuerySnapshot>(
      stream: reportStream,
      builder: (c, s) {
        final compact = MediaQuery.sizeOf(c).width < 600;
        final docs = (s.data?.docs ?? []).where(
          (d) => admin || d['status'] != 'flagged',
        );
        final filteredDocs = docs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          final statusMatch =
              statusFilter == 'all' || data['status'] == statusFilter;
          final issueType = (data['issueType'] ?? 'Pothole').toString();
          final typeMatch =
              typeFilter == 'all' ||
              issueType.toLowerCase() == typeFilter.toLowerCase();
          final query = mapSearch.toLowerCase().trim();
          final searchable =
              '${data['description'] ?? ''} $issueType ${data['lat'] ?? ''} ${data['lng'] ?? ''} ${data['location'] ?? ''}'
                  .toLowerCase();
          return statusMatch &&
              typeMatch &&
              (query.isEmpty || searchable.contains(query));
        }).toList();
        final statusLegend = Container(
          width: compact ? double.infinity : 264,
          padding: EdgeInsets.all(compact ? 12 : 15),
          decoration: BoxDecoration(
            color: ivory,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: green, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: charcoal.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Wrap(
            spacing: 14,
            runSpacing: 10,
            children: [
              Text(
                'REPORT STATUS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                  color: charcoal,
                ),
              ),
              _legendItem('Pending', statusPending),
              _legendItem('In progress', statusInProgress),
              _legendItem('Resolved', statusResolved),
              if (admin) _legendItem('Flagged', statusFlagged),
            ],
          ),
        );
        final attribution = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: ivory.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '© OpenStreetMap contributors',
            style: TextStyle(fontSize: 10, color: charcoal),
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [
            FlutterMap(
              mapController: mapController,
              options: const MapOptions(
                initialCenter: LatLng(14.8527, 120.816),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.paveo.paveo_app',
                ),
                MarkerLayer(
                  markers: [
                    for (final d in filteredDocs)
                      Marker(
                        point: LatLng(d['lat'], d['lng']),
                        width: 44,
                        height: 44,
                        child: GestureDetector(
                          onTap: () => detail(d),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(Icons.location_on_outlined, color: charcoal, size: 42),
                              Icon(
                                Icons.location_on,
                                color: statusColors[d['status']] ?? statusPending,
                                size: 36,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: 14,
              top: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ivory.withValues(alpha: 0.97),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: lightGray),
                  boxShadow: [
                    BoxShadow(
                      color: charcoal.withValues(alpha: .12),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      onChanged: (value) => setState(() => mapSearch = value),
                      decoration: const InputDecoration(
                        hintText: 'Search issues or coordinates',
                        prefixIcon: Icon(Icons.search),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: statusFilter,
                            isDense: true,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: 'all',
                                child: const Text('All status'),
                              ),
                              DropdownMenuItem(
                                value: 'pending',
                                child: const Text('Reported'),
                              ),
                              DropdownMenuItem(
                                value: 'in_progress',
                                child: const Text('In progress'),
                              ),
                              DropdownMenuItem(
                                value: 'resolved',
                                child: const Text('Resolved'),
                              ),
                              if (admin)
                                DropdownMenuItem(
                                  value: 'flagged',
                                  child: const Text('Flagged'),
                                ),
                            ],
                            onChanged: (value) =>
                                setState(() => statusFilter = value ?? 'all'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: typeFilter,
                            isDense: true,
                            decoration: const InputDecoration(
                              labelText: 'Issue type',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('All types'),
                              ),
                              DropdownMenuItem(
                                value: 'pothole',
                                child: Text('Potholes'),
                              ),
                              DropdownMenuItem(
                                value: 'cracked pavement',
                                child: Text('Cracked pavement'),
                              ),
                              DropdownMenuItem(
                                value: 'road obstruction',
                                child: Text('Obstructions'),
                              ),
                              DropdownMenuItem(
                                value: 'flooding',
                                child: Text('Flooding'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) =>
                                setState(() => typeFilter = value ?? 'all'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (compact)
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    attribution,
                    const SizedBox(height: 8),
                    if (user != null)
                      FloatingActionButton.extended(
                        heroTag: 'map-report-mobile',
                        onPressed: widget.onReport ?? report,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Report a pothole'),
                      ),
                    if (user != null) const SizedBox(height: 12),
                    statusLegend,
                  ],
                ),
              )
            else ...[
              Positioned(
                left: 16,
                bottom: 16,
                child: statusLegend,
              ),
              Positioned(
                right: 12,
                bottom: user == null ? 10 : 82,
                child: attribution,
              ),
            ],
          ],
        );
      },
    ),
    floatingActionButton:
        user == null || MediaQuery.sizeOf(context).width < 600
        ? null
        : FloatingActionButton.extended(
            onPressed: widget.onReport ?? report,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Report a pothole'),
          ),
  );

  Widget _legendItem(String title, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: charcoal.withValues(alpha: 0.35),
            width: 0.7,
          ),
        ),
      ),
      const SizedBox(width: 5),
      Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),
    ],
  );
}
