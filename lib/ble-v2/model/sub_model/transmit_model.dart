import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';

class TransmitModel {
  bool enable;
  int schedule;
  List<int> destinationID;

  TransmitModel({
    required this.enable,
    required this.schedule,
    required this.destinationID,
  });

  String get scheduleString => ConvertTime.minuteToDateTimeString(schedule);

  String get destinationIDString =>
      ConvertV2().arrayUint8ToStringHexAddress(destinationID);

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
enable : $enable \nschedule : $schedule \ndestinationID : $destinationID
    }
''';
  }

  void toDeviceConfiguration(
      TransmitScheduleModelYaml c, List<TransmitModel> m) {
    c.schedules[0].enabled = m[0].enable;
    c.schedules[0].setScheduleFromUint16(m[0].schedule);
    c.schedules[0].setDestinationIDFromArrayUint8(m[0].destinationID);

    c.schedules[1].enabled = m[1].enable;
    c.schedules[1].setScheduleFromUint16(m[1].schedule);
    c.schedules[1].setDestinationIDFromArrayUint8(m[1].destinationID);

    c.schedules[2].enabled = m[2].enable;
    c.schedules[2].setScheduleFromUint16(m[2].schedule);
    c.schedules[2].setDestinationIDFromArrayUint8(m[2].destinationID);

    c.schedules[3].enabled = m[3].enable;
    c.schedules[3].setScheduleFromUint16(m[3].schedule);
    c.schedules[3].setDestinationIDFromArrayUint8(m[3].destinationID);

    c.schedules[4].enabled = m[4].enable;
    c.schedules[4].setScheduleFromUint16(m[4].schedule);
    c.schedules[4].setDestinationIDFromArrayUint8(m[4].destinationID);

    c.schedules[5].enabled = m[5].enable;
    c.schedules[5].setScheduleFromUint16(m[5].schedule);
    c.schedules[5].setDestinationIDFromArrayUint8(m[5].destinationID);

    c.schedules[6].enabled = m[6].enable;
    c.schedules[6].setScheduleFromUint16(m[6].schedule);
    c.schedules[6].setDestinationIDFromArrayUint8(m[6].destinationID);

    c.schedules[7].enabled = m[7].enable;
    c.schedules[7].setScheduleFromUint16(m[7].schedule);
    c.schedules[7].setDestinationIDFromArrayUint8(m[7].destinationID);
  }

  static List<TransmitModel> fromDeviceConfiguration(
      TransmitScheduleModelYaml c) {
    List<TransmitModel> m = [];
    for (int i = 0; i < c.schedules.length; i++) {
      m.add(TransmitModel(
        enable: c.schedules[i].enabled,
        schedule: c.schedules[i].getScheduleToUint16(),
        destinationID: c.schedules[i].getDestinationIDToArrayUint8(),
      ));
    }
    return m;
  }
}
