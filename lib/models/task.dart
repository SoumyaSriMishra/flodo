import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
class Task extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime dueDate;

  @HiveField(4)
  late String status; // "To-Do" | "In Progress" | "Done"

  @HiveField(5)
  String? blockedById; // Optional: ID of the task that blocks this one

  @HiveField(6)
  bool isRecurring;

  @HiveField(7)
  String? recurrenceInterval; // "Daily" or "Weekly" — null if not recurring

  @HiveField(8)
  int sortOrder;

  Task({
    String? id,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = 'To-Do',
    this.blockedById,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.sortOrder = 0,
  }) : id = id ?? const Uuid().v4();
}
