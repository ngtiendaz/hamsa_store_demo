import 'package:intl/intl.dart';

const Duration vietnamUtcOffset = Duration(hours: 7);

String formatVietnamDateTime(
  DateTime dateTime, {
  String pattern = 'dd/MM/yyyy HH:mm',
}) {
  final vietnamDateTime = dateTime.toUtc().add(vietnamUtcOffset);
  return DateFormat(pattern).format(vietnamDateTime);
}
