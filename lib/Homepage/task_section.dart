import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'task_card.dart';

class TaskItem {
  final String id;
  final String title;
  final String tailorName;
  final TaskStatus status;
  final String imagePath;
  final String priorityLabel;

  TaskItem({
    this.id = '',
    required this.title,
    required this.tailorName,
    required this.status,
    required this.imagePath,
    this.priorityLabel = '',
  });
}

class TaskSection extends StatelessWidget {
  final DateTime date;
  final List<TaskItem> tasks;
  final ValueChanged<TaskItem>? onTaskTap;

  const TaskSection({
    super.key,
    required this.date,
    required this.tasks,
    this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    final header = DateFormat('EEE, dd MMM').format(date);
    final show = tasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ หัววัน
        Row(
          children: [
            Text(
              header,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
            const Spacer(),
            Text(
              '${tasks.length} งาน',
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
        ...show.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: TaskCard(
              title: t.title,
              tailorName: t.tailorName,
              status: t.status,
              imagePath: t.imagePath,
              priorityLabel: t.priorityLabel,
              onTap: () {
                onTaskTap?.call(t);
              },
            ),
          ),
        ),
      ],
    );
  }
}
