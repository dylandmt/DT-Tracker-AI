import 'package:dt_tracker_ai/core/utils/extensions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test('formats UTC timestamps in the local timezone', () {
    final timestamp = DateTime.utc(2026, 7, 31, 17, 15, 34);

    expect(
      timestamp.formattedDateTime,
      DateFormat('MMM dd, yyyy HH:mm').format(timestamp.toLocal()),
    );
  });
}
