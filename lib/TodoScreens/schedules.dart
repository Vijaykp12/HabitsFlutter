import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:habitsapp/screens/add_schedule_screen.dart';
import 'package:habitsapp/screens/schedule_details_dialog.dart';

class Schedules extends StatefulWidget {
  const Schedules({super.key});

  @override
  State<Schedules> createState() => _SchedulesState();
}

class _SchedulesState extends State<Schedules> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Helper to check if two dates are the same day
  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  // --- LOGIC: GENERATE AI REPORT ---
  Future<void> _generateReport(
      BuildContext context, DocumentSnapshot doc) async {
    // 1. Show Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) =>
          const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    // 2. Simulate AI Processing Delay (2 seconds)
    await Future.delayed(const Duration(seconds: 2));

    // 3. Generate Mock AI Content based on the task
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'];
    final type = data['type'];
    final notes = data['notes'] ?? "";

    // Simple template to mimic AI
    final aiReport = "AI ANALYSIS:\n"
        "Great job completing '$title'! Based on your notes ($notes), "
        "you maintained good focus during this $type session. "
        "Consistency Score: 9.5/10. Keep this momentum for your next '$type' block.";

    // 4. Update Database
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('schedules')
        .doc(doc.id)
        .update({
      'report': aiReport,
      'status': 'archived', // changing status hides it from the list
      'archivedAt': FieldValue.serverTimestamp(),
    });

    // 5. Close Loading Dialog
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Report Generated & Archived! 📂")));
    }
  }

  // --- LOGIC: SHOW REPORT DIALOG ---
  void _showReportDialog(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Ready to Archive?",
                  style: TextStyle(fontFamily: 'Sekuya')),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("You have completed '${data['title']}'.",
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text(
                      "Generate an AI performance report and save this to your permanent records?"),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Later"),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 17, 34, 88),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Close confirmation
                    _generateReport(context, doc); // Start generation
                  },
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text("Generate Report"),
                )
              ],
            ));
  }

  List<Map<String, dynamic>> _getWeeklyProgress(
      List<QueryDocumentSnapshot> docs) {
    List<Map<String, dynamic>> weeklyData = [];
    final now = DateTime.now();

    // Loop back 6 days + today = 7 days
    for (int i = 6; i >= 0; i--) {
      final targetDate = now.subtract(Duration(days: i));
      final dayName = DateFormat('E').format(targetDate); // "Mon", "Tue"

      // Filter tasks for this specific date
      final daysTasks = docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final start = (data['startTime'] as Timestamp).toDate();
        return isSameDay(start, targetDate);
      }).toList();

      double avgProgress = 0;
      if (daysTasks.isNotEmpty) {
        final totalProgress = daysTasks.fold(0.0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          return sum + (data['progress'] ?? 0);
        });
        avgProgress = totalProgress / daysTasks.length;
      }

      weeklyData.add({
        'day': dayName,
        'value': avgProgress / 100, // Normalize to 0.0 - 1.0
        'isToday': i == 0,
      });
    }
    return weeklyData;
  }

  // Update Progress Logic
  Future<void> _updateProgress(String docId, double newVal) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('schedules')
        .doc(docId)
        .update({'progress': newVal.toInt()});
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Please log in"));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: SizedBox(
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
          onPressed: () => showDialog(
            context: context,
            builder: (context) => const AddScheduleDialog(),
          ),
          child: const Text("+",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30)),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.only(
            left: 90, right: 20), // Added right margin for safety
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser!.uid)
              .collection('schedules')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snapshot.data!.docs;
            final now = DateTime.now();

            // --- 1. FILTER: TODAY'S SCHEDULE ---
            List<DocumentSnapshot> todaysList = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final DateTime start = (data['startTime'] as Timestamp).toDate();
              return isSameDay(start, now) && data['status'] != 'completed';
            }).toList();

            // Sort by time
            todaysList.sort((a, b) {
              final tA = (a['startTime'] as Timestamp).toDate();
              final tB = (b['startTime'] as Timestamp).toDate();
              return tA.compareTo(tB);
            });

            // --- 2. FILTER: ONGOING SCHEDULES ---
            // Items marked 'ongoing' OR items that started in the past but aren't done
            List<DocumentSnapshot> ongoingList = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'upcoming';
              final int progress = data['progress'] ?? 0;
              // Logic: It is ongoing if explicitly 'ongoing' OR has progress started
              return (status == 'ongoing' ||
                      (progress > 0 && progress < 100)) &&
                  status != 'completed';
            }).toList();

            // ... inside StreamBuilder ...

            // --- 3. FILTER: COMPLETED (Waiting for Report) ---
            List<DocumentSnapshot> completedList = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final String status = data['status'] ?? 'upcoming';
              final int progress = data['progress'] ?? 0;

              // It shows up here if Progress is 100% OR Status is 'completed'
              // BUT it must NOT be 'archived' yet.
              return (progress == 100 || status == 'completed') &&
                  status != 'archived';
            }).toList();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),

                  // --- TOP ROW ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. BAR GRAPH (Left)
                      Container(
                        height: 330,
                        width: 900,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color.fromARGB(255, 255, 242, 239)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Weekly Consistency",
                                style: TextStyle(
                                    fontFamily: 'Sekuya',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 17, 34, 88))),
                            const SizedBox(height: 5),
                            const Text("Average progress on scheduled tasks",
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 30),

                            // THE CHART ROW
                            Expanded(
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                crossAxisAlignment: CrossAxisAlignment
                                    .end, // Align bars to bottom
                                children: _getWeeklyProgress(docs).map((data) {
                                  final double pct = data['value'];
                                  final bool isToday = data['isToday'];

                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Percentage Text (e.g., 85%)
                                      Text("${(pct * 100).toInt()}%",
                                          style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 17, 34, 88))),
                                      const SizedBox(height: 10),

                                      // The Bar
                                      Container(
                                        width: 50,
                                        height: 180 *
                                            pct, // Max height 180px, scaled by percentage
                                        decoration: BoxDecoration(
                                          color: isToday
                                              ? const Color.fromARGB(255, 17,
                                                  34, 88) // Dark Blue for Today
                                              : const Color.fromARGB(
                                                  100,
                                                  17,
                                                  34,
                                                  88), // Light Blue for past
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      const SizedBox(height: 15),

                                      // Day Label (Mon, Tue...)
                                      Text(data['day'],
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isToday
                                                  ? const Color.fromARGB(
                                                      255, 17, 34, 88)
                                                  : Colors.grey)),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 40),

                      // 2. TODAY'S SCHEDULE (Right)
                      Container(
                        height: 330,
                        width: 480, // Fixed width as requested
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color.fromARGB(255, 255, 242, 239)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Today's Agenda",
                                style: TextStyle(
                                    fontFamily: 'Sekuya',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 17, 34, 88))),
                            const SizedBox(height: 15),
                            Expanded(
                              child: todaysList.isEmpty
                                  ? const Center(
                                      child:
                                          Text("Nothing scheduled for today!"))
                                  : ListView.builder(
                                      itemCount: todaysList.length,
                                      itemBuilder: (context, index) {
                                        final data = todaysList[index].data()
                                            as Map<String, dynamic>;
                                        final DateTime start =
                                            (data['startTime'] as Timestamp)
                                                .toDate();
                                        final DateTime end =
                                            (data['endTime'] as Timestamp)
                                                .toDate();

                                        // Conflict Check: overlapping with previous?
                                        bool isConflicting = false;
                                        if (index > 0) {
                                          final prevData = todaysList[index - 1]
                                              .data() as Map<String, dynamic>;
                                          final DateTime prevEnd =
                                              (prevData['endTime'] as Timestamp)
                                                  .toDate();
                                          if (start.isBefore(prevEnd))
                                            isConflicting = true;
                                        }

                                        // Habit Stacking Check
                                        final String? stackTrigger =
                                            data['isHabitStacked'] == true
                                                ? data['habitStack']
                                                : null;
                                        // inside ListView.builder for ongoingList...
                                        return InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    ScheduleDetailsDialog(
                                                        doc: todaysList[index]),
                                              );
                                            },
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 10),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: isConflicting
                                                    ? Colors.red.shade50
                                                    : Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: isConflicting
                                                    ? Border.all(
                                                        color: Colors.red)
                                                    : null,
                                              ),
                                              child: Row(
                                                children: [
                                                  Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                          DateFormat('h:mm a')
                                                              .format(start),
                                                          style:
                                                              const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize:
                                                                      16)),
                                                      Text(
                                                          DateFormat('h:mm a')
                                                              .format(end),
                                                          style:
                                                              const TextStyle(
                                                                  color: Colors
                                                                      .grey,
                                                                  fontSize:
                                                                      12)),
                                                    ],
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(data['title'],
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold)),
                                                        if (stackTrigger !=
                                                            null)
                                                          Text(
                                                              "👉 After: $stackTrigger",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .purple
                                                                      .shade700,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                        if (isConflicting)
                                                          const Text(
                                                              "⚠ Conflict!",
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .red,
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold)),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ));
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                  // --- BOTTOM ROW ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. ONGOING SCHEDULES (Left Wide Box)
                      Container(
                        height: 250,
                        width: 1100, // Fixed width as requested
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color.fromARGB(255, 255, 242, 239)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Ongoing & Active Works",
                                style: TextStyle(
                                    fontFamily: 'Sekuya',
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 17, 34, 88))),
                            const SizedBox(height: 15),
                            Expanded(
                              child: ongoingList.isEmpty
                                  ? const Center(
                                      child: Text(
                                          "No ongoing works. Add one with 'Progress' > 0"))
                                  : ListView.builder(
                                      scrollDirection: Axis
                                          .horizontal, // Horizontal scroll for cards
                                      itemCount: ongoingList.length,
                                      itemBuilder: (context, index) {
                                        final docId = ongoingList[index].id;
                                        final data = ongoingList[index].data()
                                            as Map<String, dynamic>;
                                        final double progress =
                                            (data['progress'] ?? 0).toDouble();
                                        final String priority =
                                            data['priority'] ?? 'Low';

                                        // inside ListView.builder for ongoingList...
                                        return InkWell(
                                            onTap: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    ScheduleDetailsDialog(
                                                        doc:
                                                            ongoingList[index]),
                                              );
                                            },
                                            child: Container(
                                              width: 300,
                                              margin: const EdgeInsets.only(
                                                  right: 15),
                                              padding: const EdgeInsets.all(15),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(15),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 4),
                                                        decoration: BoxDecoration(
                                                            color:
                                                                priority ==
                                                                        'High'
                                                                    ? Colors.red
                                                                        .shade100
                                                                    : Colors
                                                                        .blue
                                                                        .shade100,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        8)),
                                                        child: Text(priority,
                                                            style: TextStyle(
                                                                fontSize: 10,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color: priority ==
                                                                        'High'
                                                                    ? Colors.red
                                                                    : Colors
                                                                        .blue)),
                                                      ),
                                                      Text(
                                                          "${progress.toInt()}%",
                                                          style: const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold)),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 10),
                                                  Text(data['title'],
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontFamily:
                                                              'Sekuya')),
                                                  const Text(
                                                      "Tap to update progress",
                                                      style: TextStyle(
                                                          fontSize: 12,
                                                          color: Colors.grey)),
                                                  const Spacer(),
                                                  SliderTheme(
                                                    data:
                                                        SliderTheme.of(context)
                                                            .copyWith(
                                                      thumbShape:
                                                          const RoundSliderThumbShape(
                                                              enabledThumbRadius:
                                                                  6),
                                                      overlayShape:
                                                          const RoundSliderOverlayShape(
                                                              overlayRadius:
                                                                  10),
                                                      trackHeight: 4,
                                                    ),
                                                    child: Slider(
                                                      value: progress,
                                                      min: 0,
                                                      max: 100,
                                                      activeColor:
                                                          const Color.fromARGB(
                                                              255, 17, 34, 88),
                                                      inactiveColor:
                                                          Colors.grey.shade300,
                                                      onChanged: (val) {
                                                        // Real-time update logic
                                                        _updateProgress(
                                                            docId, val);
                                                      },
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ));
                                      },
                                    ),
                            )
                          ],
                        ),
                      ),

                      const SizedBox(width: 40),

                      // 4. COMPLETED / REPORTS (Right Box)
                      Container(
                        height: 250,
                        width: 280,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color.fromARGB(255, 255, 242, 239)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Ready for Report",
                                style: TextStyle(
                                    fontFamily: 'Sekuya',
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 17, 34, 88))),
                            const SizedBox(height: 5),
                            const Text("Tap to generate & archive",
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 15),
                            Expanded(
                              child: completedList.isEmpty
                                  ? const Center(
                                      child: Icon(Icons.check_circle_outline,
                                          size: 60, color: Colors.black12))
                                  : ListView.builder(
                                      itemCount: completedList.length,
                                      itemBuilder: (context, index) {
                                        final doc = completedList[index];
                                        final data =
                                            doc.data() as Map<String, dynamic>;

                                        return Card(
                                          elevation: 0,
                                          color: Colors.green.shade50,
                                          margin:
                                              const EdgeInsets.only(bottom: 10),
                                          child: ListTile(
                                            onTap: () => _showReportDialog(doc),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10),
                                            leading: const Icon(
                                                Icons.auto_awesome,
                                                color: Colors.green),
                                            title: Text(data['title'],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14)),
                                            trailing: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 12,
                                                color: Colors.green),
                                          ),
                                        );
                                      },
                                    ),
                            )
                          ],
                        ),
                      ),
                    ],
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
