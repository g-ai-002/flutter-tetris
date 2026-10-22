class DateFormatUtils {
  DateFormatUtils._();

  static String formatDateTime(DateTime d) {
    return '${d.year}-${_pad(d.month)}-${_pad(d.day)} '
        '${_pad(d.hour)}:${_pad(d.minute)}';
  }

  static String _pad(int n) => n.toString().padLeft(2, '0');
}
