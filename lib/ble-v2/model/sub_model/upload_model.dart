import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';
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

  void toDeviceConfiguration(UploadScheduleModelYaml c, List<UploadModel> m) {
    c.schedules[0].enabled = m[0].enable;
    c.schedules[0].setScheduleFromUint16(m[0].schedule);

    c.schedules[1].enabled = m[1].enable;
    c.schedules[1].setScheduleFromUint16(m[1].schedule);

    c.schedules[2].enabled = m[2].enable;
    c.schedules[2].setScheduleFromUint16(m[2].schedule);

    c.schedules[3].enabled = m[3].enable;
    c.schedules[3].setScheduleFromUint16(m[3].schedule);

    c.schedules[4].enabled = m[4].enable;
    c.schedules[4].setScheduleFromUint16(m[4].schedule);

    c.schedules[5].enabled = m[5].enable;
    c.schedules[5].setScheduleFromUint16(m[5].schedule);

    c.schedules[6].enabled = m[6].enable;
    c.schedules[6].setScheduleFromUint16(m[6].schedule);

    c.schedules[7].enabled = m[7].enable;
    c.schedules[7].setScheduleFromUint16(m[7].schedule);
  }

  static List<UploadModel> fromDeviceConfiguration(UploadScheduleModelYaml c) {
    List<UploadModel> m = [];
    for (int i = 0; i < c.schedules.length; i++) {
      m.add(UploadModel(
        enable: c.schedules[i].enabled,
        schedule: c.schedules[i].getScheduleToUint16(),
      ));
    }
    return m;
  }
}
