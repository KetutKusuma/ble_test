import 'package:flutter/material.dart';

class TimePickerHelper {
  static Future<TimeOfDay?> pickTime(
      BuildContext context, TimeOfDay? selectedTime) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    return pickedTime; // Mengembalikan nilai TimeOfDay yang dipilih
  }

  static TimeOfDay minutesToTimeOfDay(int totalMinutes) {
    final int hours = totalMinutes ~/ 60; // Integer division for hours
    final int minutes = totalMinutes % 60; // Remaining minutes
    return TimeOfDay(hour: hours, minute: minutes);
  }

  static int timeOfDayToMinutes(TimeOfDay time) {
    return (time.hour * 60) + time.minute;
  }

  static String formatTimeOfDay(TimeOfDay time) {
    // Ensuring two-digit formatting for hours and minutes
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return "$hour:$minute";
  }

  static TimeOfDay stringToTimeOfDay(String timeString) {
    final parts = timeString.split(":");
    final int hour = int.parse(parts[0]);
    final int minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }
}
