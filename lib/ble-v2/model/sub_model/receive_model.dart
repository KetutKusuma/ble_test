import 'package:ble_test/ble-v2/utils/convert.dart';

class ReceiveModel {
  bool enable;
  int schedule;
  int count;
  int interval;
  int timeAdjust;

  ReceiveModel({
    required this.enable,
    required this.schedule,
    required this.count,
    required this.interval,
    required this.timeAdjust,
  });

  String get scheduleString => ConvertTime.minuteToDateTimeString(schedule);

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
enable : $enable \nschedule : $schedule \ncount : $count \ninterval : $interval \ntimeAdjust : $timeAdjust
  }
''';
  }
}
