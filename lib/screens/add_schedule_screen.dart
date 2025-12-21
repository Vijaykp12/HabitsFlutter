import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddScheduleDialog extends StatefulWidget {
  const AddScheduleDialog({super.key});

  @override
  State<AddScheduleDialog> createState() => _AddScheduleDialogState();
}

class _AddScheduleDialogState extends State<AddScheduleDialog> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _habitStackController = TextEditingController();

  final List<String> _types = [
    'Learning',
    'Project',
    'Event',
    'Meetup',
    'Deep Work'
  ];
  String _selectedType = 'Learning';

  final List<String> _priorities = ['High', 'Medium', 'Low'];
  String _selectedPriority = 'Medium';

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _endTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  bool _isHabitStacked = false;
  bool _isLoading = false;

  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (date == null) return;

    final time = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (time == null) return;

    setState(() {
      if (isStart) {
        _startDate = date;
        _startTime = time;
        final startDT =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        final endDT = startDT.add(const Duration(hours: 1));
        _endDate = endDT;
        _endTime = TimeOfDay.fromDateTime(endDT);
      } else {
        _endDate = date;
        _endTime = time;
      }
    });
  }

  Future<void> _saveSchedule() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Title is required")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final startDT = DateTime(_startDate.year, _startDate.month,
          _startDate.day, _startDate.hour, _startDate.minute);
      final endDT = DateTime(_endDate.year, _endDate.month, _endDate.day,
          _endDate.hour, _endDate.minute);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('schedules')
          .add({
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'priority': _selectedPriority,
        'startTime': Timestamp.fromDate(startDT),
        'endTime': Timestamp.fromDate(endDT),
        'status': 'upcoming',
        'progress': 0,
        'notes': _notesController.text.trim(),
        'isHabitStacked': _isHabitStacked,
        'habitStack':
            _isHabitStacked ? _habitStackController.text.trim() : null,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context); // Closes the Dialog
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('MMM d, h:mm a').format(DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startDate.hour,
        _startDate.minute));
    final endStr = DateFormat('MMM d, h:mm a').format(DateTime(_endDate.year,
        _endDate.month, _endDate.day, _endDate.hour, _endDate.minute));

    // RETURN DIALOG INSTEAD OF SCAFFOLD
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color.fromARGB(255, 255, 242, 239),
      insetPadding: const EdgeInsets.all(20), // Adds margin from screen edges
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(
            maxWidth: 500), // Prevents it from being too wide
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Shrinks to fit content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Add Schedule",
                      style: TextStyle(
                          fontFamily: 'Sekuya',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 17, 34, 88))),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  )
                ],
              ),
              const SizedBox(height: 20),

              // 1. TITLE
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Title",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 15),

              // 2. TYPE & PRIORITY
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedType,
                      items: _types
                          .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) => setState(() => _selectedType = val!),
                      decoration: InputDecoration(
                        labelText: "Type",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      items: _priorities
                          .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _selectedPriority = val!),
                      decoration: InputDecoration(
                        labelText: "Priority",
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // 3. DATE PICKERS
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => _pickDateTime(true),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Starts",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(startStr,
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 17, 34, 88))),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    InkWell(
                      onTap: () => _pickDateTime(false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Ends",
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(endStr,
                                style: const TextStyle(
                                    color: Color.fromARGB(255, 17, 34, 88))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 4. HABIT STACKING
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _isHabitStacked
                      ? const Color.fromARGB(255, 230, 240, 255)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: _isHabitStacked
                      ? Border.all(color: const Color.fromARGB(255, 17, 34, 88))
                      : null,
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text("Habit Stacking",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      value: _isHabitStacked,
                      dense: true,
                      activeColor: const Color.fromARGB(255, 17, 34, 88),
                      onChanged: (val) => setState(() => _isHabitStacked = val),
                    ),
                    if (_isHabitStacked)
                      Padding(
                        padding: const EdgeInsets.only(
                            bottom: 10, left: 15, right: 15),
                        child: TextField(
                          controller: _habitStackController,
                          decoration: const InputDecoration(
                            hintText: "e.g. After morning coffee...",
                            border: UnderlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 5. NOTES
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Notes",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),

              // 6. ACTION BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 17, 34, 88),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isLoading ? null : _saveSchedule,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Add to Schedule",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
