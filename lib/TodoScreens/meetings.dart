import 'package:flutter/material.dart';

class Meetings extends StatefulWidget {
  @override
  Meet createState() => Meet();
}

class Meet extends State<Meetings> {
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.only(left: 70),
        child: Column(children: [
          const SizedBox(height: 30),
          Container(
            // Meeting hero section
            height: 330,
            width: 1380,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: const Color.fromARGB(255, 255, 242, 239)),
          ),
          const SizedBox(height: 15),
          Expanded(
              child: Row(children: [
            const SizedBox(width: 40),
            Container(
              // Completed Meetings and the report section
              height: 250,
              width: 665,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 255, 242, 239)),
            ),
            const SizedBox(width: 50),
            Container(
              // Upcoming Meetings
              height: 250,
              width: 665,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: const Color.fromARGB(255, 255, 242, 239)),
            ),
          ]))
        ]));
  }
}
