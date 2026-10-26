import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'brand.dart';

final reportsRef = FirebaseFirestore.instance.collection('reports');

const labels = {
  'pending': 'Pending',
  'in_progress': 'In progress',
  'resolved': 'Resolved',
  'flagged': 'Flagged for review',
};

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  String filter = 'all';
  String searchQuery = '';
  late final Future<bool> authorization = _checkAdminRole();

  Future<bool> _checkAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return profile.data()?['role'] == 'admin';
  }

  void updateReportStatus(String id, String status) => reportsRef
      .doc(id)
      .update({'status': status, if (status != 'flagged') 'duplicateOf': null});

  void updateSeverity(String id, String sev) =>
      reportsRef.doc(id).update({'severity': sev});

  void addAdminNote(String id, String note) =>
      reportsRef.doc(id).update({'adminNote': note});

  void deleteReport(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text(
          'Are you sure you want to permanently delete this report?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            style: FilledButton.styleFrom(
              backgroundColor: charcoal,
              foregroundColor: ivory,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      reportsRef.doc(id).delete();
    }
  }

  void openInspectionDialog(QueryDocumentSnapshot d) {
    final noteController = TextEditingController(
      text: (d.data() as Map<String, dynamic>)['adminNote'] ?? '',
    );
    var currentStatus = d['status'] as String? ?? 'pending';
    var currentSev = d['severity'] as String? ?? 'medium';
    final dupId = (d.data() as Map<String, dynamic>)['duplicateOf'] as String?;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.verified_outlined, color: green),
              const SizedBox(width: 8),
              Text(
                'Verify Pothole Report',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d['photo'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(d['photo']),
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 12),
                Text(
                  'Description: ${d['description'] ?? 'No description'}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  'Location: Lat ${d['lat']}, Lng ${d['lng']}',
                  style: const TextStyle(fontSize: 12, color: gray),
                ),
                const SizedBox(height: 4),
                Text(
                  'Citizen Confirmations: ${List.from(d['confirmedBy'] ?? []).length}',
                  style: const TextStyle(fontSize: 12, color: gray),
                ),
                if (dupId != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: peach.withValues(alpha: 0.4),
                      border: Border.all(color: peach),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: charcoal,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Flagged as a possible duplicate of report #$dupId',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 24),
                const Text(
                  'Verification & Status:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                DropdownButton<String>(
                  value: currentStatus,
                  isExpanded: true,
                  items: [
                    for (final k in labels.keys)
                      DropdownMenuItem(value: k, child: Text(labels[k]!)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => currentStatus = v);
                      updateReportStatus(d.id, v);
                    }
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Severity Level:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                DropdownButton<String>(
                  value: currentSev,
                  isExpanded: true,
                  items: [
                    for (final s in ['low', 'medium', 'high'])
                      DropdownMenuItem(value: s, child: Text(s.toUpperCase())),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => currentSev = v);
                      updateSeverity(d.id, v);
                    }
                  },
                ),
                const SizedBox(height: 10),
                const Text(
                  'Maintenance Crew Notes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    hintText:
                        'e.g. Work crew dispatched, repair materials scheduled',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Close'),
            ),
            if (currentStatus == 'flagged')
              FilledButton.icon(
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Approve as Distinct Pothole'),
                style: FilledButton.styleFrom(backgroundColor: green),
                onPressed: () {
                  updateReportStatus(d.id, 'pending');
                  Navigator.pop(c);
                },
              ),
            FilledButton(
              onPressed: () {
                addAdminNote(d.id, noteController.text.trim());
                Navigator.pop(c);
              },
              child: const Text('Save Notes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: authorization,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.data != true) {
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    size: 48,
                    color: green,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Admin access restricted',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in with an account that has administrator access to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: gray),
                  ),
                ],
              ),
            ),
          ),
        );
      }
      return _adminDashboard();
    },
  );

  Widget _adminDashboard() => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          const PaveoBrandLockup(
            iconSize: 38,
            wordmarkSize: 20,
            showTagline: false,
          ),
          const SizedBox(width: 14),
          Container(width: 1, height: 34, color: sage),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Admin portal',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: charcoal,
                    fontSize: 17,
                  ),
                ),
                const Text(
                  'Road Maintenance & Verification',
                  style: TextStyle(fontSize: 11, color: gray),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    body: StreamBuilder<QuerySnapshot>(
      stream: reportsRef.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data!.docs;

        final totalCount = docs.length;
        final flaggedCount = docs.where((d) => d['status'] == 'flagged').length;
        final pendingCount = docs.where((d) => d['status'] == 'pending').length;
        final inProgressCount = docs
            .where((d) => d['status'] == 'in_progress')
            .length;
        final resolvedCount = docs
            .where((d) => d['status'] == 'resolved')
            .length;

        final filtered = docs.where((d) {
          final statusMatch = filter == 'all' || d['status'] == filter;
          final desc = (d['description'] ?? '').toString().toLowerCase();
          final searchMatch =
              searchQuery.isEmpty || desc.contains(searchQuery.toLowerCase());
          return statusMatch && searchMatch;
        }).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: lightGreen,
                  border: Border.all(color: sage),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Road report overview',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalCount reports received · $pendingCount awaiting review',
                            style: const TextStyle(color: gray, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: ivory,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.route_rounded, color: green),
                    ),
                  ],
                ),
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _badge('All ($totalCount)', 'all'),
                  const SizedBox(width: 8),
                  _badge(
                    'Flagged Review ($flaggedCount)',
                    'flagged',
                    color: statusFlagged,
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    'Pending ($pendingCount)',
                    'pending',
                    color: statusPending,
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    'In Repair ($inProgressCount)',
                    'in_progress',
                    color: statusInProgress,
                  ),
                  const SizedBox(width: 8),
                  _badge(
                    'Resolved ($resolvedCount)',
                    'resolved',
                    color: statusResolved,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search, size: 20),
                  hintText: 'Search reports by description...',
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                ),
                onChanged: (v) => setState(() => searchQuery = v),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: lightGreen,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.fact_check_outlined,
                              color: green,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No reports to show',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Try another status filter or search term.',
                            style: TextStyle(color: gray),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final d = filtered[i];
                        final status = d['status'] as String? ?? 'pending';
                        final confCount = List.from(
                          d['confirmedBy'] ?? [],
                        ).length;
                        final dupId =
                            (d.data() as Map<String, dynamic>)['duplicateOf']
                                as String?;
                        final adminNote =
                            (d.data() as Map<String, dynamic>)['adminNote']
                                as String?;

                        return Card(
                          color: lightGreen,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: statusColors[status] ?? lightGray,
                              width: 1.5,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => openInspectionDialog(d),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: d['photo'] != null
                                            ? Image.memory(
                                                base64Decode(d['photo']),
                                                width: 80,
                                                height: 80,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 80,
                                                height: 80,
                                                color: lightGray,
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        statusColors[status]
                                                            ?.withValues(
                                                              alpha: 0.72,
                                                            ) ??
                                                        lightGreen,
                                                    border: Border.all(
                                                      color: charcoal
                                                          .withValues(
                                                            alpha: .48,
                                                          ),
                                                      width: .8,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    labels[status] ?? status,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 11,
                                                      color: charcoal,
                                                    ),
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  'Sev: ${d['severity']}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: charcoal,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '$confCount confirms',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: gray,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              d['description'] ??
                                                  'No description',
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (dupId != null) ...[
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(
                                                    Icons.warning_amber_rounded,
                                                    color: charcoal,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(
                                                      'Possible duplicate of: $dupId',
                                                      style: const TextStyle(
                                                        color: charcoal,
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                            if (adminNote != null &&
                                                adminNote.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Note: $adminNote',
                                                style: const TextStyle(
                                                  color: green,
                                                  fontSize: 11,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      OutlinedButton.icon(
                                        icon: const Icon(
                                          Icons.edit_note,
                                          size: 16,
                                        ),
                                        label: const Text('Verify / Inspect'),
                                        onPressed: () =>
                                            openInspectionDialog(d),
                                      ),
                                      Row(
                                        children: [
                                          if (status == 'flagged')
                                            FilledButton.icon(
                                              icon: const Icon(
                                                Icons.check,
                                                size: 16,
                                              ),
                                              label: const Text('Approve'),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: green,
                                              ),
                                              onPressed: () =>
                                                  updateReportStatus(
                                                    d.id,
                                                    'pending',
                                                  ),
                                            ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: charcoal,
                                              size: 20,
                                            ),
                                            tooltip: 'Delete Spam Report',
                                            onPressed: () => deleteReport(d.id),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    ),
  );

  Widget _badge(String title, String val, {Color? color}) {
    final sel = filter == val;
    final tone = color ?? lightGreen;
    return ChoiceChip(
      label: Text(
        title,
        style: const TextStyle(color: charcoal, fontWeight: FontWeight.w500),
      ),
      selected: sel,
      backgroundColor: ivory,
      selectedColor: tone.withValues(alpha: color == null ? .72 : .82),
      side: BorderSide(
        color: color == null
            ? (sel ? green : lightGray)
            : charcoal.withValues(alpha: sel ? .65 : .38),
        width: sel ? 1.4 : 1,
      ),
      shape: const StadiumBorder(),
      onSelected: (_) => setState(() => filter = val),
    );
  }
}
