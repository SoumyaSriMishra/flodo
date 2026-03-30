class DateUtilsX {
  static bool isOverdue(DateTime dueDate, String status) {
    if (status == 'Done') return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.isBefore(today);
  }
}

