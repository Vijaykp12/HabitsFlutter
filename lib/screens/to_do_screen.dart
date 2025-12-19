import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:habitsapp/TodoScreens/daily_tasks.dart';
import 'package:habitsapp/TodoScreens/meetings.dart';
import 'package:habitsapp/TodoScreens/schedules.dart';

class ToDoScreen extends StatefulWidget {
  @override
  ToDoPage createState() => ToDoPage();
}

class ToDoPage extends State<ToDoScreen> {
  String section = "DailyTask";

  void setSection(String value) {
    setState(() => section = value);
  }

  Widget sideIcon({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.white24 : Colors.transparent,
          borderRadius: BorderRadius.circular(0),
        ),
        child: Icon(
          icon,
          size: 25,
          color: isActive
              ? const Color.fromARGB(206, 247, 165, 165)
              : Colors.white70,
        ),
      ),
    );
  }

  Widget topNav(String title, bool isActive) {
    return TextButton(
      onPressed: () => setSection(title),
      child: Text(
        title,
        style: TextStyle(
          color: isActive
              ? const Color.fromARGB(206, 247, 165, 165)
              : Colors.white70,
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          fontSize: 20,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 17, 34, 88),
        elevation: 0,
        title: const Text(
          "Habits",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 25,
            color: Color.fromARGB(206, 247, 165, 165),
          ),
        ),
        actions: [
          topNav("DailyTask", section == "DailyTask"),
          topNav("Schedules", section == "Schedules"),
          topNav("Meetings", section == "Meetings"),
          const SizedBox(width: 100),
        ],
      ),
      body: Stack(
        children: [
          // LEFT SIDEBAR

          Container(
            width: 60,
            color: const Color.fromARGB(255, 17, 34, 88),
            child: Column(
              children: [
                const SizedBox(height: 20),
                sideIcon(
                  icon: LucideIcons.checkSquare,
                  isActive: section == "DailyTask",
                  onTap: () => setSection("DailyTask"),
                ),
                sideIcon(
                  icon: LucideIcons.calendar,
                  isActive: section == "Schedules",
                  onTap: () => setSection("Schedules"),
                ),
                sideIcon(
                  icon: LucideIcons.users,
                  isActive: section == "Meetings",
                  onTap: () => setSection("Meetings"),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.only(left: 50, top: 230),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 249, 223, 223),
              borderRadius: BorderRadius.circular(0),
            ),
          ),

          Container(
            margin: const EdgeInsets.only(left: 50),
            height: 250,
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 247, 165, 165),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                bottomLeft: Radius.circular(20),
                topRight: Radius.circular(0),
                bottomRight: Radius.circular(0),
              ),
            ),
          ),

          section == "DailyTask"
              ? DailyTasks()
              : section == "Meetings"
                  ? Meetings()
                  : Schedules(),
        ],
      ),
    );
  }
}
