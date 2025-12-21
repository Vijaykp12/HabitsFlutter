import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTodoScreen extends StatefulWidget {
  const AddTodoScreen({super.key});

  @override
  AddTodo createState() => AddTodo();
}

class AddTodo extends State<AddTodoScreen> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  int priority = 1;
  String category = "Health";
  bool reminder = false;
  bool _isLoading = false; // Added loading state

  final Map<int, String> daysMap = {
    1: "M",
    2: "T",
    3: "W",
    4: "T",
    5: "F",
    6: "S",
    7: "S" // Fixed: Removed trailing comma inside string
  };

  final Set<int> selectedDays = {};

  Future<void> saveTodo() async {
    final title = _titleCtrl.text.trim();

    // Validation
    if (title.isEmpty || selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Title and at least one day required")),
      );
      return;
    }

    // Auth Check
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to save tasks.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("todos")
          .add({
        "title": title,
        "createdAt": Timestamp.now(),
        "active": true,
        "category": category,
        "priority": priority,
        "daysOfTask": selectedDays.toList()..sort(),
        "reminder": reminder,
        "notes": _notesCtrl.text.trim(),
        "color": "#4CAF50" // Consider storing this as an int or RGB string
      });

      if (mounted) {
        clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving task: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void clearForm() {
    _titleCtrl.clear(); // Clears the Title text
    _notesCtrl.clear(); // Clears the Notes text

    setState(() {
      // Reset state variables to their defaults
      priority = 1;
      category = "Health";
      reminder = false;
      selectedDays.clear(); // Empties the set of selected days
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we are on a wide screen (Web/Desktop) or Mobile
    //final isWideScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
        backgroundColor: const Color.fromARGB(255, 255, 242, 239),
        appBar: AppBar(
          title: const Text("Add New Task"),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Container(
            // Use constraints to make it work on both Mobile and Web
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: const Color.fromARGB(206, 247, 165, 165),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.all(16), // Simple margin for all sides
            child: ListView(
              shrinkWrap: true, // Important when inside a Center/Container
              children: [
                const SizedBox(height: 10),
                TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: "Task Title",
                    fillColor: Colors.white,
                    filled: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    labelText: "Notes (optional)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: category,
                        items: ["Health", "Study", "Work", "Personal"]
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) => setState(() => category = v!),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: "Category",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: priority,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text("High")),
                          DropdownMenuItem(value: 2, child: Text("Medium")),
                          DropdownMenuItem(value: 3, child: Text("Low")),
                        ],
                        onChanged: (v) => setState(() => priority = v!),
                        decoration: const InputDecoration(
                          fillColor: Colors.white,
                          filled: true,
                          labelText: "Priority",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Days of Task",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                    spacing: 8,
                    children: daysMap.entries.map((e) {
                      final selected = selectedDays.contains(e.key);
                      return FilterChip(
                        // ChoiceChip or FilterChip works here
                        label: Text(e.value),
                        selected: selected,
                        onSelected: (bool value) {
                          setState(() {
                            value
                                ? selectedDays.add(e.key)
                                : selectedDays.remove(e.key);
                          });
                        },
                      );
                    }).toList()),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text("Set Reminder"),
                  value: reminder,
                  onChanged: (v) => setState(() => reminder = v),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: const Color.fromARGB(255, 17, 34, 88),
                      foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : saveTodo,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Save To-Do"),
                ),
              ],
            ),
          ),
        ));
  }
}
