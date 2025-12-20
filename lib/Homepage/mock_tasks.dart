import 'task_section.dart';
import 'task_card.dart';

final List<TaskItem> mockTasks = [
  TaskItem(
    title: "Cutting - Dress #A102",
    tailorName: "Tailor: Nook",
    status: TaskStatus.urgent,
    imagePath: "asset/img/user.png",
  ),
  TaskItem(
    title: "Sewing - Shirt #B221",
    tailorName: "Tailor: Ploy",
    status: TaskStatus.doing,
    imagePath: "asset/img/user.png",
  ),
  TaskItem(
    title: "Fitting - Suit #S010",
    tailorName: "Tailor: Bank",
    status: TaskStatus.doing,
    imagePath: "asset/img/user.png",
  ),
  TaskItem(
    title: "Deliver - Skirt #K900",
    tailorName: "Tailor: May",
    status: TaskStatus.done,
    imagePath: "asset/img/user.png",
  ),
  TaskItem(
    title: "Check size - Customer #C77",
    tailorName: "Tailor: Fai",
    status: TaskStatus.urgent,
    imagePath: "asset/img/user.png",
  ),
  // ✅ เกิน 5 เพื่อทดสอบ "+x more"
  TaskItem(
    title: "Extra task - Pants #P100",
    tailorName: "Tailor: Art",
    status: TaskStatus.doing,
    imagePath: "asset/img/user.png",
  ),
];
