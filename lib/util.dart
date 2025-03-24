import 'package:flutter/material.dart';

String cleanHtml(String htmlString) {
  String cleanedString = htmlString.replaceAll(RegExp(r'<br\s*\/?>'), '\n');
  cleanedString = cleanedString.replaceAll(RegExp(r'<[^>]*>'), '');
  return cleanedString;
}

String formatTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
}

extension RoundedDateTime on DateTime {
  DateTime roundDown({required int min}) {
    final d = Duration(minutes: min).inMilliseconds;
    return DateTime.fromMillisecondsSinceEpoch(
      millisecondsSinceEpoch - millisecondsSinceEpoch % d,
    );
  }

  DateTime roundUp({required int min}) {
    final d = Duration(minutes: min).inMilliseconds;
    return DateTime.fromMillisecondsSinceEpoch(
      millisecondsSinceEpoch + (d - millisecondsSinceEpoch % d),
    );
  }
}

typedef TimeTable = Map<String, List<TimeOfDay>>;

final List<String> timetableDays = [
  "Monday",
  "Tuesday",
  "Wednesday",
  "Thursday",
  "Friday",
  "Saturday",
  "Sunday",
];

extension RoundedTimeOfDay on TimeOfDay {
  TimeOfDay roundDown({required int min}) {
    int totalMinutes = hour * 60 + minute;
    totalMinutes -= totalMinutes % min;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  TimeOfDay roundUp({required int min}) {
    int totalMinutes = hour * 60 + minute;
    totalMinutes += (min - (totalMinutes % min)) % min;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  TimeOfDay round({required int min}) {
    int totalMinutes = hour * 60 + minute;
    totalMinutes += min ~/ 2 - 1;
    totalMinutes -= totalMinutes % min;
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  TimeOfDay add(Duration d) {
    int totalMinutes = (hour * 60 + minute + d.inMinutes) % (24 * 60);
    return TimeOfDay(hour: totalMinutes ~/ 60, minute: totalMinutes % 60);
  }

  Duration difference(TimeOfDay t) {
    return Duration(minutes: minute - t.minute, hours: hour - t.hour);
  }
}
