import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:habitsapp/screens/add_meetings_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';

class Meetings extends StatefulWidget {
  const Meetings({super.key});

  @override
  State<Meetings> createState() => _MeetingsState();
}

class _MeetingsState extends State<Meetings> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Function to launch URL
  Future<void> _launchUrl(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> launchMeetingLink(BuildContext context, String url) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No link provided for this meeting.")));
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Couldn't launch the meeting link.")));
      }
    }
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color.fromARGB(255, 17, 34, 88), size: 28),
        const SizedBox(width: 15),
        Text(text,
            style: const TextStyle(
                fontSize: 18,
                color: Colors.black87,
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Future<void> meetingDetails(
      BuildContext context, DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime start = (data['startTime'] as Timestamp).toDate();
    final String dateStr = DateFormat('EEEE, MMMM d, y').format(start);
    final String timeStr = DateFormat('jm').format(start);
    final String type = data['type'] ?? "General";
    final String link = data['link'] ?? "";
    final String report = data['report'] ?? "";

    await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Meeting Details",
                  style: TextStyle(
                      fontFamily: 'Sekuya',
                      color: Color.fromARGB(255, 17, 34, 88))),
              content: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Sekuya',
                          color: Color.fromARGB(255, 17, 34, 88),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 17, 34, 88),
                            borderRadius: BorderRadius.circular(8)),
                        child: Text(type.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 30),
                      _buildInfoRow(Icons.calendar_today, dateStr),
                      const SizedBox(height: 15),
                      _buildInfoRow(Icons.access_time, timeStr),
                      const SizedBox(height: 30),
                      const Divider(thickness: 2),
                      const SizedBox(height: 20),
                      const Text(
                        "Report Status",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 17, 34, 88)),
                      ),
                    ]),
              ),
              actions: [
                // --- 1. ACTION BUTTONS ROW (Join + Resources) ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    children: [
                      // JOIN BUTTON (Only if link exists)
                      if (link.isNotEmpty)
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => launchMeetingLink(context, link),
                            icon: const Icon(Icons.video_call),
                            label: const Text("Join",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),

                      if (link.isNotEmpty) const SizedBox(width: 10),

                      // RESOURCES BUTTON (New!)
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 17, 34, 88),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            // Close the details dialog first to keep UI clean
                            Navigator.pop(ctx);
                            // Open the existing resources sheet
                            _showResourcesSheet(context, doc);
                          },
                          icon: const Icon(Icons.folder_open),
                          label: const Text("Resources",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 15),

                // --- 2. REPORT CONTAINER ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: report.isEmpty
                      ? Column(
                          children: [
                            const Icon(Icons.analytics_outlined,
                                size: 40, color: Colors.grey),
                            const SizedBox(height: 10),
                            const Text(
                              "No AI Report yet.",
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            "AI Generation coming soon!")));
                              },
                              child: const Text("Generate"),
                            )
                          ],
                        )
                      : Text(report,
                          style: const TextStyle(fontSize: 16, height: 1.5)),
                ),
              ],
            ));
  }

  Future<void> _addNewResource(BuildContext context, String docId) async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title:
            const Text("Add Resource", style: TextStyle(fontFamily: 'Sekuya')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(
                labelText: "Title (e.g. Slides, Design File)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: "Link URL",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 17, 34, 88),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleCtrl.text.isNotEmpty && urlCtrl.text.isNotEmpty) {
                // Save to Firestore
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('meetings')
                    .doc(docId)
                    .update({
                  'resources': FieldValue.arrayUnion([
                    {
                      'title': titleCtrl.text.trim(),
                      'url': urlCtrl.text.trim(),
                      'type': 'link'
                    }
                  ])
                });
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // Function to show Resources Bottom Sheet
  void _showResourcesSheet(BuildContext context, DocumentSnapshot doc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows sheet to grow with keyboard
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: 500, // Fixed height for the sheet
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Meeting Resources",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sekuya')),
                IconButton(
                  onPressed: () => _addNewResource(context, doc.id),
                  icon: const Icon(Icons.add_circle,
                      color: Color.fromARGB(255, 17, 34, 88), size: 32),
                )
              ],
            ),
            const SizedBox(height: 20),

            // --- LIVE DATA LIST ---
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('meetings')
                    .doc(doc.id)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData)
                    return const Center(child: CircularProgressIndicator());

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final link = data['link'] ?? "";

                  // Get the array of resources (or empty list if none)
                  final List<dynamic> resources = data['resources'] ?? [];

                  return ListView(
                    children: [
                      // 1. The Main Meeting Link
                      if (link.isNotEmpty)
                        ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.video_camera_front,
                                color: Colors.blue),
                          ),
                          title: const Text("Join Meeting",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(link,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () => _launchUrl(link),
                        ),

                      const Divider(),
                      const SizedBox(height: 10),

                      // 2. The Added Resources List
                      if (resources.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                              child: Text("No extra resources added yet.")),
                        ),

                      ...resources.map((res) {
                        final resMap = res as Map<String, dynamic>;
                        return Card(
                          elevation: 0,
                          color: Colors.grey.shade50,
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading:
                                const Icon(Icons.link, color: Colors.orange),
                            title: Text(resMap['title'] ?? "Resource",
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(resMap['url'] ?? "",
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  size: 20, color: Colors.grey),
                              onPressed: () {
                                // Delete logic
                                FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(currentUser!.uid)
                                    .collection('meetings')
                                    .doc(doc.id)
                                    .update({
                                  'resources': FieldValue.arrayRemove([res])
                                });
                              },
                            ),
                            onTap: () => _launchUrl(resMap['url']),
                          ),
                        );
                      }).toList()
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Please log in"));

    return Container(
      margin: const EdgeInsets.only(left: 70),
      child: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('meetings')
                .orderBy('startTime', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();
              final allDocs = snapshot.data!.docs;

              List<DocumentSnapshot> pastMeetings = [];
              List<DocumentSnapshot> futureMeetings = [];

              for (var doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final Timestamp? endTs = data['endTime'];
                if (endTs != null && endTs.toDate().isBefore(now)) {
                  pastMeetings.add(doc);
                } else {
                  futureMeetings.add(doc);
                }
              }

              DocumentSnapshot? heroMeeting;
              List<DocumentSnapshot> upcomingMeetings = [];

              if (futureMeetings.isNotEmpty) {
                heroMeeting = futureMeetings.first;
                if (futureMeetings.length > 1) {
                  upcomingMeetings = futureMeetings.sublist(1);
                }
              }

              pastMeetings = pastMeetings.reversed.toList();

              // --- SCROLLABLE WRAPPER START ---
              return SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 30),
                    _buildHeroSection(heroMeeting),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 600,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(width: 40),
                          _buildCompletedSection(pastMeetings),
                          const SizedBox(width: 50),
                          _buildUpcomingSection(upcomingMeetings),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 40,
            right: 40,
            child: SizedBox(
              height: 60,
              width: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0)),
                  backgroundColor: const Color.fromARGB(255, 17, 34, 88),
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AddMeetingScreen()));
                },
                child: const Text("+",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeroSection(DocumentSnapshot? meeting) {
    // --- UPDATED HEIGHT: 450 ---
    double heroHeight = 550;

    if (meeting == null) {
      return Container(
        margin: const EdgeInsets.only(top: 30),
        height: heroHeight,
        width: 1380,
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: const Color.fromARGB(255, 255, 242, 239)),
        child: const Center(
          child: Text("No upcoming meetings. You're free! 🎉",
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sekuya')),
        ),
      );
    }

    final data = meeting.data() as Map<String, dynamic>;
    final DateTime start = (data['startTime'] as Timestamp).toDate();
    final String formattedTime = DateFormat('jm').format(start);
    final String formattedDate = DateFormat('MMMM d, y').format(start);
    final String type = data['type'] ?? "General";

    return Container(
      height: heroHeight,
      width: 1380,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color.fromARGB(255, 17, 34, 88),
            Color.fromARGB(255, 66, 88, 155)
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8)),
                  child: Text("UP NEXT • ${type.toUpperCase()}",
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
                Text(data['title'] ?? "Untitled Meeting",
                    style: const TextStyle(
                        fontSize: 60, // Increased Font Size for bigger hero
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Sekuya')),
                const SizedBox(height: 10),
                Text("$formattedDate  •  $formattedTime",
                    style:
                        const TextStyle(fontSize: 28, color: Colors.white70)),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color.fromARGB(255, 17, 34, 88),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 20), // Bigger Button
                  ),
                  onPressed: () => _showResourcesSheet(context, meeting),
                  icon: const Icon(Icons.folder_open),
                  label: const Text("View Resources",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                )
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(Icons.timer_outlined,
                  size: 200, // Bigger Icon
                  color: Colors.white.withOpacity(0.2)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCompletedSection(List<DocumentSnapshot> meetings) {
    return Container(
      height: double.infinity,
      width: 665,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(255, 255, 242, 239)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Completed & Reports",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sekuya',
                  color: Color.fromARGB(255, 17, 34, 88))),
          const SizedBox(height: 15),
          Expanded(
            child: meetings.isEmpty
                ? const Center(child: Text("No history yet."))
                : ListView.builder(
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {
                      final data =
                          meetings[index].data() as Map<String, dynamic>;
                      final hasReport = data['report'] != null &&
                          (data['report'] as String).isNotEmpty;
                      final type = data['type'] ?? "General";

                      return Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.6),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          title: Text(data['title'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              "$type • ${hasReport ? "Report Ready" : "Processing"}"),
                          trailing: const Icon(Icons.arrow_forward_ios,
                              size: 16, color: Colors.grey),
                          onTap: () => meetingDetails(context, meetings[index]),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildUpcomingSection(List<DocumentSnapshot> meetings) {
    return Container(
      height: double.infinity,
      width: 665,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(255, 255, 242, 239)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Upcoming",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sekuya',
                  color: Color.fromARGB(255, 17, 34, 88))),
          const SizedBox(height: 15),
          Expanded(
            child: meetings.isEmpty
                ? const Center(child: Text("No more meetings scheduled."))
                : ListView.builder(
                    itemCount: meetings.length,
                    itemBuilder: (context, index) {
                      final data =
                          meetings[index].data() as Map<String, dynamic>;
                      final DateTime start =
                          (data['startTime'] as Timestamp).toDate();
                      final dateStr = DateFormat('MMM d, h:mm a').format(start);
                      final type = data['type'] ?? "General";

                      return Card(
                        elevation: 0,
                        color: Colors.white.withOpacity(0.6),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 17, 34, 88)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.calendar_today,
                                color: Color.fromARGB(255, 17, 34, 88)),
                          ),
                          title: Text(data['title'],
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("$type • $dateStr"),
                          onTap: () => meetingDetails(context, meetings[index]),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
