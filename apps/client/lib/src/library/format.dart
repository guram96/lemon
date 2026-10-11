/// Display formatting for library screens.
library;

const _units = ['KB', 'MB', 'GB', 'TB', 'PB'];

/// `512 B`, `1.4 MB`, `12 GB`: binary units like Steam, one decimal below 10
/// (and none for bytes).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  var value = bytes / 1024;
  var unit = 0;
  while (value >= 1024 && unit < _units.length - 1) {
    value /= 1024;
    unit++;
  }
  // Round first, so 1023.96 KB reads "1 MB" rather than "1024 KB".
  if (value >= 1023.95 && unit < _units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value < 10 ? 1 : 0;
  var text = value.toStringAsFixed(digits);
  if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
  return '$text ${_units[unit]}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// `Oct 11, 2026`, in local time.
String formatDate(DateTime date) {
  final d = date.toLocal();
  return '${_months[d.month - 1]} ${d.day}, ${d.year}';
}

/// `1 game`, `12 games`.
String formatGameCount(int count) =>
    count == 1 ? '1 game' : '${formatCount(count)} games';

/// File name of a `/`-separated relative path.
String fileName(String path) {
  final slash = path.lastIndexOf('/');
  return slash < 0 ? path : path.substring(slash + 1);
}

/// `1,204`.
String formatCount(int value) {
  final digits = value.abs().toString();
  final out = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
    out.write(digits[i]);
  }
  return out.toString();
}
