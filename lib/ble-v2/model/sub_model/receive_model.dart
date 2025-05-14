import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';
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

  void toDeviceConfiguration(ReceiveScheduleModelYaml c, List<ReceiveModel> m) {
    c.schedules[0].enabled = m[0].enable;
    c.schedules[0].setScheduleFromUint16(m[0].schedule);
    c.schedules[0].timeAdjust = m[0].timeAdjust;

    c.schedules[1].enabled = m[1].enable;
    c.schedules[1].setScheduleFromUint16(m[1].schedule);
    c.schedules[1].timeAdjust = m[1].timeAdjust;

    c.schedules[2].enabled = m[2].enable;
    c.schedules[2].setScheduleFromUint16(m[2].schedule);
    c.schedules[2].timeAdjust = m[2].timeAdjust;

    c.schedules[3].enabled = m[3].enable;
    c.schedules[3].setScheduleFromUint16(m[3].schedule);
    c.schedules[3].timeAdjust = m[3].timeAdjust;

    c.schedules[4].enabled = m[4].enable;
    c.schedules[4].setScheduleFromUint16(m[4].schedule);
    c.schedules[4].timeAdjust = m[4].timeAdjust;

    c.schedules[5].enabled = m[5].enable;
    c.schedules[5].setScheduleFromUint16(m[5].schedule);
    c.schedules[5].timeAdjust = m[5].timeAdjust;

    c.schedules[6].enabled = m[6].enable;
    c.schedules[6].setScheduleFromUint16(m[6].schedule);
    c.schedules[6].timeAdjust = m[6].timeAdjust;

    c.schedules[7].enabled = m[7].enable;
    c.schedules[7].setScheduleFromUint16(m[7].schedule);
    c.schedules[7].timeAdjust = m[7].timeAdjust;

    c.schedules[8].enabled = m[8].enable;
    c.schedules[8].setScheduleFromUint16(m[8].schedule);
    c.schedules[8].timeAdjust = m[8].timeAdjust;

    c.schedules[9].enabled = m[9].enable;
    c.schedules[9].setScheduleFromUint16(m[9].schedule);
    c.schedules[9].timeAdjust = m[9].timeAdjust;

    c.schedules[10].enabled = m[10].enable;
    c.schedules[10].setScheduleFromUint16(m[10].schedule);
    c.schedules[10].timeAdjust = m[10].timeAdjust;

    c.schedules[11].enabled = m[11].enable;
    c.schedules[11].setScheduleFromUint16(m[11].schedule);
    c.schedules[11].timeAdjust = m[11].timeAdjust;

    c.schedules[12].enabled = m[12].enable;
    c.schedules[12].setScheduleFromUint16(m[12].schedule);
    c.schedules[12].timeAdjust = m[12].timeAdjust;

    c.schedules[13].enabled = m[13].enable;
    c.schedules[13].setScheduleFromUint16(m[13].schedule);
    c.schedules[13].timeAdjust = m[13].timeAdjust;

    c.schedules[14].enabled = m[14].enable;
    c.schedules[14].setScheduleFromUint16(m[14].schedule);
    c.schedules[14].timeAdjust = m[14].timeAdjust;

    c.schedules[15].enabled = m[15].enable;
    c.schedules[15].setScheduleFromUint16(m[15].schedule);
    c.schedules[15].timeAdjust = m[15].timeAdjust;
  }

  static List<ReceiveModel> fromDeviceConfiguration(
      ReceiveScheduleModelYaml c) {
    List<ReceiveModel> m = [];
    for (int i = 0; i < c.schedules.length; i++) {
      m.add(ReceiveModel(
        enable: c.schedules[i].enabled ?? false,
        schedule: c.schedules[i].getScheduleToUint16(),
        timeAdjust: c.schedules[i].timeAdjust ?? 0,
      ));
    }
    return m;
  }
}
