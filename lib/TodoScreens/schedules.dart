import 'package:flutter/material.dart';

class Schedules extends StatefulWidget {
  @override
  Schedule createState() => Schedule();
}

class Schedule extends State<Schedules> {
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 90),
        child: Column(children: [
          const SizedBox(height: 30),
          Row(children: [
            Container(
              // bar graph
              height: 330,
              width: 900,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 255, 242, 239)),
            ),
            const SizedBox(width: 40),
            Container(
              // today's schedule decided pre-day
              height: 330,
              width: 480,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 255, 242, 239)),
            ),
          ]),
          Expanded(
              child: Row(children: [
            const SizedBox(height: 35),
            Container(
              // On going projects and their next step with all details
              height: 250,
              width: 1100,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 255, 242, 239)),
            ),
            const SizedBox(height: 35),
            const SizedBox(width: 40),
            Container(
              // Completed Projects or tasks to download report
              height: 250,
              width: 280,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 255, 242, 239)),
            ),
          ]))
        ]));
  }
}
