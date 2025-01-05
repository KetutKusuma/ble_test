import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class DeviceStatusConverter {
  static List<dynamic> converDeviceStatus(List<int> bytes) {
    bool statusBool = bytes[0] == 1;
    String firmware = BytesConvert.bytesToString(bytes.sublist(1, 17));
    String version = BytesConvert.bytesToString(bytes.sublist(17, 25));
    int timeInt = BytesConvert.bytesToInt32(
      bytes.sublist(25, 29),
      isBigEndian: true,
    );
    String timeString =
        DateTime.fromMillisecondsSinceEpoch((timeInt + 946684800) * 1000)
            .subtract(const Duration(hours: 8))
            .toString();

    double temperature = BytesConvert.bytesToFloatorDoubleV2(
        bytes.sublist(29, 33),
        isBigEndian: false);
    double battery1 = BytesConvert.bytesToFloatorDouble(bytes.sublist(33, 37),
        isBigEndian: false);
    double battery2 = BytesConvert.bytesToFloatorDouble(bytes.sublist(37, 41),
        isBigEndian: false);
    int critBattery1Counter = BytesConvert.bytesToInt8([bytes[41]]);
    int critBattery2Counter = BytesConvert.bytesToInt8([bytes[42]]);

    log("temperature : $temperature");
    log("bytes : ${bytes.sublist(29, 33)}");
    log("time : $timeString");
    log("battery1 : $battery1");
    log("battery2 : $battery2");
    log("crit battery1 counter : $critBattery1Counter");
    log("crit battery2 counter : $critBattery2Counter");

    return [
      statusBool,
      firmware,
      version,
      timeString,
      temperature,
      battery1,
      battery2,
      critBattery1Counter,
      critBattery2Counter,
    ];
  }
}
