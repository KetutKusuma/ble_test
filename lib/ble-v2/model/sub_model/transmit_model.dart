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
}
