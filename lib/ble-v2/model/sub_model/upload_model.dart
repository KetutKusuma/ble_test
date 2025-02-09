import 'package:ble_test/ble-v2/utils/convert.dart';

class UploadModel {
  bool enable;
  int schedule;

  UploadModel({required this.enable, required this.schedule});

  String getScheduleString() {
    return ConvertV2().minuteToDateTimeString(schedule);
  }

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
enable : $enable \nschedule : $schedule
}
''';
  }
}
