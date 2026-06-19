class DateFormatUtils {
  DateFormatUtils._();

  static String formatDateTime(DateTime d) {
    return '${d.year}-${_pad(d.month)}-${_pad(d.day)} '
        '${_pad(d.hour)}:${_pad(d.minute)}';
  }

  static String formatTime(DateTime d) {
    return '${_pad(d.hour)}:${_pad(d.minute)}:${_pad(d.second)}.${d.millisecond.toString().padLeft(3, '0')}';
  }

  static String formatDate(DateTime d) {
    return '${d.year}${_pad(d.month)}${_pad(d.day)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
