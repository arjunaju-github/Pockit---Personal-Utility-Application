String getTimeLeft(String dueDate, String dueTime) {
  try {
    final now = DateTime.now();
    final due = DateTime.parse("$dueDate $dueTime");

    final diff = due.difference(now);

    if (diff.isNegative) return "Overdue";

    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;

    if (d > 0) return "$d d $h h left";
    if (h > 0) return "$h h $m m left";
    return "$m m left";
  } catch (e) {
    return "Invalid date";
  }
}