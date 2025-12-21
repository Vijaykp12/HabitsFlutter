import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class MeetingDetailsScreen extends StatelessWidget {
  final DocumentSnapshot doc;

  const MeetingDetailsScreen({super.key, required this.doc});

  // Helper to open meeting link
  Future<void> _launchMeetingLink(BuildContext context, String? url) async {
    if (url == null || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No link provided for this meeting.")));
      return;
    }

    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Could not launch meeting link.")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final DateTime start = (data['startTime'] as Timestamp).toDate();
    final String dateStr = DateFormat('EEEE, MMMM d, y').format(start);
    final String timeStr = DateFormat('jm').format(start);
    final String type = data['type'] ?? "General";
    final String link = data['link'] ?? "";
    final String report = data['report'] ?? "";

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 242, 239),
      appBar: AppBar(
        title: const Text("Meeting Details",
            style: TextStyle(
                fontFamily: 'Sekuya', color: Color.fromARGB(255, 17, 34, 88))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 17, 34, 88)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Text(
              data['title'],
              style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Sekuya',
                  color: Color.fromARGB(255, 17, 34, 88)),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 17, 34, 88),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(type.toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 30),

            // TIME SECTION
            _buildInfoRow(Icons.calendar_today, dateStr),
            const SizedBox(height: 15),
            _buildInfoRow(Icons.access_time, timeStr),
            const SizedBox(height: 30),

            // LINK SECTION
            if (link.isNotEmpty)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // Distinct color for action
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _launchMeetingLink(context, link),
                icon: const Icon(Icons.video_call),
                label: const Text("Join Meeting",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),

            const SizedBox(height: 40),
            const Divider(thickness: 2),
            const SizedBox(height: 20),

            // REPORT / RESOURCES SECTION
            const Text(
              "Resources & Report",
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 17, 34, 88)),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: report.isEmpty
                  ? Column(
                      children: [
                        const Icon(Icons.analytics_outlined,
                            size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        const Text(
                          "No AI Report generated yet.",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                        // Placeholder for future AI button
                        OutlinedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("AI Generation coming soon!")));
                          },
                          child: const Text("Generate Report"),
                        )
                      ],
                    )
                  : Text(report,
                      style: const TextStyle(fontSize: 16, height: 1.5)),
            ),
          ],
        ),
      ),
    );
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
}
