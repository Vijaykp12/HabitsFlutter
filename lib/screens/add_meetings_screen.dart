import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddMeetingScreen extends StatefulWidget {
  const AddMeetingScreen({super.key});

  @override
  State<AddMeetingScreen> createState() => _AddMeetingScreenState();
}

class _AddMeetingScreenState extends State<AddMeetingScreen> {
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();

  final List<String> meetingTypes = [
    'Work',
    'Academic',
    'Business',
    'Tech',
    'Personal',
    'Health',
    'Social'
  ];
  String _selectedType = 'Work'; // Default value

  DateTime _startDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _endTime =
      TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

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
        // Auto-adjust end time
        final startDateTime =
            DateTime(date.year, date.month, date.day, time.hour, time.minute);
        final endDateTime = startDateTime.add(const Duration(hours: 1));
        _endDate = endDateTime;
        _endTime = TimeOfDay.fromDateTime(endDateTime);
      } else {
        _endDate = date;
        _endTime = time;
      }
    });
  }

  Future<void> _saveMeeting() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please enter a title")));
      return;
    }

    setState(() => _isLoading = true);

    final startDateTime = DateTime(_startDate.year, _startDate.month,
        _startDate.day, _startDate.hour, _startDate.minute);

    final endDateTime = DateTime(_endDate.year, _endDate.month, _endDate.day,
        _endDate.hour, _endDate.minute);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('meetings')
          .add({
        'title': _titleController.text.trim(),
        'link': _linkController.text.trim(),
        'type': _selectedType, // <--- SAVING THE NEW FIELD
        'startTime': Timestamp.fromDate(startDateTime),
        'endTime': Timestamp.fromDate(endDateTime),
        'createdAt': FieldValue.serverTimestamp(),
        'report': '',
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final startStr = DateFormat('MMM d, y - h:mm a').format(DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startDate.hour,
        _startDate.minute));
    final endStr = DateFormat('MMM d, y - h:mm a').format(DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endDate.hour,
        _endDate.minute));

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 242, 239),
      appBar: AppBar(
        title: const Text("Schedule Meeting",
            style: TextStyle(
                fontFamily: 'Sekuya', color: Color.fromARGB(255, 17, 34, 88))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 17, 34, 88)),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: "Meeting Title",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // --- NEW: TYPE DROPDOWN ---
              DropdownButtonFormField<String>(
                value: _selectedType,
                items: meetingTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedType = val!),
                decoration: InputDecoration(
                  labelText: "Meeting Type",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("Starts"),
                      trailing: Text(startStr,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _pickDateTime(true),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text("Ends"),
                      trailing: Text(endStr,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      onTap: () => _pickDateTime(false),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _linkController,
                decoration: InputDecoration(
                  labelText: "Meeting Link (Zoom/Meet)",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 17, 34, 88),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _saveMeeting,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Schedule It",
                        style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
