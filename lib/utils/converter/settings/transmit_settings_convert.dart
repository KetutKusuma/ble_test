import 'dart:developer';

import '../bytes_convert.dart';

class TransmitSettingsConvert {
  static List<dynamic> convertTransmitSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 30) {
      throw Exception("Invalid bytes convert");
    }

    bool statusBool = bytes[0] == 1;
    bool destinationEnable = bytes[1] == 1;
    String destinationId = BytesConvert.bytesToString(bytes.sublist(2, 27));
    int transmitScheduleInt =
        BytesConvert.bytesToInt16(bytes.sublist(27, 37), isBigEndian: false);

    if (bytes.sublist(2, 27).every((element) => element == 0)) {
      destinationId = '-';
    }

    log("status : $statusBool");
    log("destination enable : $destinationEnable");
    log("destination id : $destinationId");
    log("transmit schedule : $transmitScheduleInt");

    return [statusBool, destinationEnable, destinationId, transmitScheduleInt];
  }
}
