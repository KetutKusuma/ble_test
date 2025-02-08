import 'dart:developer';

import 'package:ble_test/ble-v2/utils/convert.dart';

class CaptureModel {
  int schedule;
  int count;
  int interval;
  int specialDate;
  int specialSchedule;
  int specialCount;
  int specialInterval;
  int recentCaptureLimit;

  CaptureModel({
    required this.schedule,
    required this.count,
    required this.interval,
    required this.specialDate,
    required this.specialSchedule,
    required this.specialCount,
    required this.specialInterval,
    required this.recentCaptureLimit,
  });

  @override
  String toString() {
    // TODO: implement toString

    return '''
{
  schedule : $schedule \n
  count : $count \n
  interval : $interval \n
  specialDate : $specialDate \n
  specialSchedule : $specialSchedule \n
  specialCount : $specialCount \n
  specialInterval : $specialInterval \n
  recentCaptureLimit : $recentCaptureLimit \n
}''';
  }

  String get scheduleString => ConvertTime.minuteToDateTimeString(schedule);

  set scheduleString(String value) {
    schedule = ConvertTime.dateTimeStringToMinute(value);
  }

  String get specialDateString {
    log("masok ?? $specialDate");
    List<String> specialDates = [];
    for (int i = 0; i < 31; i++) {
      // log("special dates uuhy : ${ConvertTime.getBit(specialDate, i)}");
      if (ConvertTime.getBit(specialDate, i)) {
        // log("special dates : $specialDates");
        specialDates.add((i + 1).toString());
      }
    }
    log("special dates : $specialDates");
    return specialDates.join(",");
  }

  set specialDateString(String value) {
    int temp = 0;
    List<String> arr = value.split(",");
    for (String v in arr) {
      int date = int.parse(v);
      if (date >= 1 && date <= 31) {
        temp = ConvertTime.setBit(temp, date - 1, true);
      } else {
        throw Exception("Invalid date");
      }
    }
    specialDate = temp;
  }

  String get specialScheduleString =>
      ConvertTime.minuteToDateTimeString(specialSchedule);

  set specialScheduleString(String value) {
    specialSchedule = ConvertTime.dateTimeStringToMinute(value);
  }
}
