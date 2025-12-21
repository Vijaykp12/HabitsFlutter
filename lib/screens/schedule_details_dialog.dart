import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ScheduleDetailsDialog extends StatefulWidget {
  final DocumentSnapshot doc;

  const ScheduleDetailsDialog({super.key, required this.doc});

  @override
  State<ScheduleDetailsDialog> createState() => _ScheduleDetailsDialogState();
}

class _ScheduleDetailsDialogState extends State<ScheduleDetailsDialog> {
  // Controllers
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late TextEditingController _habitStackController;

  // State Variables
  late String _selectedType;
  late String _selectedPriority;
  late DateTime _startDate;
  late TimeOfDay _startTime;
  late DateTime _endDate;
  late TimeOfDay _endTime;
  late bool _isHabitStacked;
  late double _progress;
  late String _status;

  bool _isLoading = false;
  final List<String> _statuses = [
    'upcoming',
    'ongoing',
    'completed',
    'archived'
  ];

  @override
  void initState() {
    super.initState();
    // 1. PRE-FILL DATA FROM DATABASE
    final data = widget.doc.data() as Map<String, dynamic>;

    _titleController = TextEditingController(text: data['title']);
    _notesController = TextEditingController(text: data['notes']);
    _habitStackController =
        TextEditingController(text: data['habitStack'] ?? "");

    _selectedType = data['type'] ?? 'Learning';
    _selectedPriority = data['priority'] ?? 'Medium';
    _status = data['status'] ?? 'upcoming';
    _progress = (data['progress'] ?? 0).toDouble();

    // Handle Timestamps
    final startTs = data['startTime'] as Timestamp;
    final endTs = data['endTime'] as Timestamp;

    _startDate = startTs.toDate();
    _startTime = TimeOfDay.fromDateTime(_startDate);

    _endDate = endTs.toDate();
    _endTime = TimeOfDay.fromDateTime(_endDate);

    _isHabitStacked = data['isHabitStacked'] ?? false;
  }

  // --- LOGIC: UPDATE ---
  Future<void> _updateSchedule() async {
    setState(() => _isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Reconstruct DateTime objects
      final startDT = DateTime(_startDate.year, _startDate.month,
          _startDate.day, _startTime.hour, _startTime.minute);
      final endDT = DateTime(_endDate.year, _endDate.month, _endDate.day,
          _endTime.hour, _endTime.minute);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('schedules')
          .doc(widget.doc.id)
          .update({
        'title': _titleController.text.trim(),
        'type': _selectedType,
        'priority': _selectedPriority,
        'status': _status,
        'progress': _progress.toInt(),
        'startTime': Timestamp.fromDate(startDT),
        'endTime': Timestamp.fromDate(endDT),
        'notes': _notesController.text.trim(),
        'isHabitStacked': _isHabitStacked,
        'habitStack':
            _isHabitStacked ? _habitStackController.text.trim() : null,
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Schedule Updated!")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LOGIC: DELETE ---
  Future<void> _deleteSchedule() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text("Delete Schedule?"),
              content: const Text("This action cannot be undone."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text("Delete",
                        style: TextStyle(color: Colors.red))),
              ],
            ));

    if (confirm == true) {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .collection('schedules')
          .doc(widget.doc.id)
          .delete();

      if (mounted) Navigator.pop(context);
    }
  }

  // Helper for Date Picker
  Future<void> _pickDateTime(bool isStart) async {
    final date = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2020),
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
      } else {
        _endDate = date;
        _endTime = time;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Format Strings for UI
    final startStr = DateFormat('MMM d, h:mm a').format(DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute));
    final endStr = DateFormat('MMM d, h:mm a').format(DateTime(_endDate.year,
        _endDate.month, _endDate.day, _endTime.hour, _endTime.minute));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: const Color.fromARGB(255, 255, 242, 239),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Edit Details",
                      style: TextStyle(
                          fontFamily: 'Sekuya',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 17, 34, 88))),
                  IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.grey))
                ],
              ),
              const SizedBox(height: 20),

              // TITLE
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

              // STATUS & PROGRESS (Unique to Edit Mode)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _status,
                      items: _statuses
                          .map((s) => DropdownMenuItem(
                              value: s, child: Text(s.toUpperCase())))
                          .toList(),
                      onChanged: (val) => setState(() => _status = val!),
                      decoration: InputDecoration(
                        labelText: "Status",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Progress: ${_progress.toInt()}%",
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                          Slider(
                            value: _progress,
                            min: 0,
                            max: 100,
                            divisions: 10,
                            activeColor: const Color.fromARGB(255, 17, 34, 88),
                            onChanged: (val) => setState(() => _progress = val),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 15),

              // DATE PICKERS
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
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(startStr,
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 17, 34, 88))),
                            ]),
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
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(endStr,
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 17, 34, 88))),
                            ]),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // NOTES
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: "Notes",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 25),

              // ACTION BUTTONS
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _deleteSchedule,
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text("Delete",
                          style: TextStyle(color: Colors.red)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _updateSchedule,
                      icon: _isLoading
                          ? const SizedBox()
                          : const Icon(Icons.save),
                      label: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Update Schedule",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 17, 34, 88),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
