import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:habitsapp/screens/add_todo_screens.dart';

class DailyTasks extends StatefulWidget {
  const DailyTasks({super.key});

  @override
  State<DailyTasks> createState() => _DailyTasksState();
}

class _DailyTasksState extends State<DailyTasks> {
  User? get currentUser => FirebaseAuth.instance.currentUser;
  int get currentWeekday => DateTime.now().weekday;
  String get todayDateId => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<void> toggleTaskCompletion(String todoId, bool currentStatus) async {
    if (currentUser == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .collection('daily_progress')
        .doc(todayDateId);

    await docRef.set({todoId: !currentStatus}, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Please log in."));

    return Container(
      margin: const EdgeInsets.only(left: 90),
      child: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser!.uid)
                .collection('todos')
                .snapshots(),
            builder: (context, todoSnapshot) {
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser!.uid)
                    .collection('daily_progress')
                    .doc(todayDateId)
                    .snapshots(),
                builder: (context, progressSnapshot) {
                  // --- CALCULATION LOGIC ---
                  if (!todoSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  Map<String, dynamic> progressData = {};
                  if (progressSnapshot.hasData &&
                      progressSnapshot.data!.exists) {
                    progressData =
                        progressSnapshot.data!.data() as Map<String, dynamic>;
                  }

                  final allDocs = todoSnapshot.data!.docs;
                  List<DocumentSnapshot> incompleteTasks = [];
                  List<DocumentSnapshot> completedTasks = [];

                  for (var doc in allDocs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final List<dynamic> days = data['daysOfTask'] ?? [];

                    if (data['active'] == true &&
                        days.contains(currentWeekday)) {
                      final isDone = progressData[doc.id] == true;
                      if (isDone) {
                        completedTasks.add(doc);
                      } else {
                        incompleteTasks.add(doc);
                      }
                    }
                  }

                  int totalTasks =
                      completedTasks.length + incompleteTasks.length;
                  double progressValue =
                      totalTasks == 0 ? 0 : completedTasks.length / totalTasks;

                  return Row(
                    children: [
                      // -------------------------
                      // LEFT SIDE: GRAPH (UPDATED)
                      // -------------------------
                      Container(
                        height: 600,
                        width: 550,
                        margin: const EdgeInsets.only(right: 20),
                        // Added padding inside the container
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: const Color.fromARGB(255, 255, 242, 239)),
                        child: Column(
                          // 1. PUSH UP: Use start alignment + top SizedBox
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const SizedBox(
                                height: 80), // Controls vertical position

                            const Text("Daily Consistency",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    fontFamily: 'Sekuya',
                                    color: Color.fromARGB(255, 17, 34, 88))),

                            const SizedBox(height: 40),

                            // PROGRESS RING
                            Stack(alignment: Alignment.center, children: [
                              SizedBox(
                                  height: 200,
                                  width: 200,
                                  child: CircularProgressIndicator(
                                    value: progressValue,
                                    backgroundColor: const Color.fromARGB(
                                        206, 247, 165, 165),
                                    color:
                                        const Color.fromARGB(255, 17, 34, 88),
                                    strokeCap: StrokeCap.round,
                                    strokeWidth: 15,
                                  )),
                              Column(children: [
                                Text(
                                  "${completedTasks.length}",
                                  style: const TextStyle(
                                    fontSize: 50,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 17, 34, 88),
                                  ),
                                ),
                                Text(
                                  "of $totalTasks Tasks Completed",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 17, 34, 88),
                                  ),
                                ),
                              ])
                            ]),

                            const SizedBox(height: 40),

                            // 2. NEW DATA DISPLAY (Completed vs Remaining)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 20, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  // Completed Count
                                  Column(
                                    children: [
                                      Text("${completedTasks.length}",
                                          style: const TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green)),
                                      const Text("Completed",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  // Divider Line
                                  Container(
                                      height: 40, width: 2, color: Colors.grey),
                                  // Remaining Count
                                  Column(
                                    children: [
                                      Text("${incompleteTasks.length}",
                                          style: const TextStyle(
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              color: Color.fromARGB(
                                                  255, 17, 34, 88))),
                                      const Text("Remaining",
                                          style: TextStyle(
                                              fontSize: 16,
                                              color: Colors.black54,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            if (progressValue == 1.0 && totalTasks > 0)
                              const Text("All Done! Great Job! 🎉",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green))
                            else if (progressValue > 0.5)
                              const Text("Keep it up!",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey))
                            else
                              const Text("Let's get started!",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      ),

                      // -------------------------
                      // RIGHT SIDE: LISTS (SAME AS BEFORE)
                      // -------------------------
                      Expanded(
                        child: Column(
                          children: [
                            const SizedBox(height: 35),
                            // COMPLETED LIST
                            Container(
                              height: 270,
                              width: 800,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color:
                                      const Color.fromARGB(255, 255, 242, 239)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Completed",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Color.fromARGB(255, 17, 34, 88),
                                          fontSize: 18,
                                          fontFamily: 'Sekuya')),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: completedTasks.length,
                                      itemBuilder: (context, index) {
                                        final doc = completedTasks[index];
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        return Card(
                                          color: Colors.white.withOpacity(0.5),
                                          elevation: 0,
                                          child: ListTile(
                                            leading: IconButton(
                                              icon: const Icon(Icons.check_box,
                                                  color: Colors.green),
                                              onPressed: () =>
                                                  toggleTaskCompletion(
                                                      doc.id, true),
                                            ),
                                            title: Text(data['title'],
                                                style: const TextStyle(
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                    color: Colors.grey,
                                                    fontWeight: FontWeight.bold,
                                                    fontFamily: 'Cause')),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 40),
                            // INCOMPLETE LIST
                            Container(
                              height: 290,
                              width: 800,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color:
                                      const Color.fromARGB(255, 255, 242, 239)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("To-Do",
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color:
                                              Color.fromARGB(255, 17, 34, 88),
                                          fontFamily: 'Sekuya')),
                                  const SizedBox(height: 10),
                                  Expanded(
                                    child: ListView.builder(
                                      itemCount: incompleteTasks.length,
                                      itemBuilder: (context, index) {
                                        final doc = incompleteTasks[index];
                                        final data =
                                            doc.data() as Map<String, dynamic>;
                                        return Card(
                                          color: Colors.white.withOpacity(0.6),
                                          elevation: 0,
                                          child: ListTile(
                                            leading: IconButton(
                                              icon: const Icon(Icons
                                                  .check_box_outline_blank),
                                              onPressed: () =>
                                                  toggleTaskCompletion(
                                                      doc.id, false),
                                            ),
                                            title: Text(data['title'],
                                                style: const TextStyle(
                                                  fontFamily: 'Cause',
                                                  fontWeight: FontWeight.bold,
                                                )),
                                            subtitle:
                                                Text(data['category'] ?? ""),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
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
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AddTodoScreen())),
                  child: const Text("+",
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 30))),
            ),
          )
        ],
      ),
    );
  }
}
