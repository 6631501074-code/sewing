import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'task_card.dart';

class TaskItem {
  final String title;
  final String tailorName;
  final TaskStatus status;
  final String imagePath;

  TaskItem({
    required this.title,
    required this.tailorName,
    required this.status,
    required this.imagePath,
  });
}

class TaskSection extends StatelessWidget {
  final DateTime date;
  final List<TaskItem> tasks;

  const TaskSection({
    super.key,
    required this.date,
    required this.tasks,
  });

  @override
  Widget build(BuildContext context) {
    final header = DateFormat('EEE, dd MMM').format(date);
    final show = tasks.take(5).toList();
    final moreCount = tasks.length - show.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ หัววัน
        Row(
          children: [
            Text(
              header,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            if (moreCount > 0)
              Text(
                "+$moreCount more",
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),

        const SizedBox(height: 10),

        // ✅ งาน (max 5)
        ...show.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskCard(
                title: t.title,
                tailorName: t.tailorName,
                status: t.status,
                imagePath: t.imagePath,
                onTap: () {
                  // TODO: ไปหน้า Task Detail
                },
              ),
            )),
      ],
    );
  }
}
