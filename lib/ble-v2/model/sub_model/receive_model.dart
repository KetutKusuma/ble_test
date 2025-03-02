import 'package:ble_test/ble-v2/utils/convert.dart';

class ReceiveModel {
  bool enable;
  int schedule;
  int timeAdjust;

  ReceiveModel({
    required this.enable,
    required this.schedule,
    required this.timeAdjust,
  });

  String get scheduleString => ConvertTime.minuteToDateTimeString(schedule);

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
enable : $enable \nschedule : $schedule \ntimeAdjust : $timeAdjust
  }
''';
  }
}
