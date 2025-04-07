import 'dart:developer';

import '../bytes_convert.dart';

class ReceiveSettingsConvert {
  static List<dynamic> convertReceiveSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 5) {
      throw Exception("Invalid bytes convert");
    }

    bool statusBool = bytes[0] == 1;
    bool receiveEnableBool = bytes[1] == 1;
    int receiveScheduleInt =
        BytesConvert.bytesToInt16(bytes.sublist(2, 4), isBigEndian: false);
    int receiveIntervalInt =
        BytesConvert.bytesToInt16(bytes.sublist(4, 6), isBigEndian: false);
    int receiveCountInt = BytesConvert.bytesToInt8([bytes[6]]);
    int receiveTimeAdjust =
        BytesConvert.bytesToInt16(bytes.sublist(7, 9), isBigEndian: false);

    log("status : $statusBool");
    log("receive enable : $receiveEnableBool");
    log("receive schedule : $receiveScheduleInt");
    log("receive interval : $receiveIntervalInt");
    log("receive count : $receiveCountInt");
    log("receive time adjust : $receiveTimeAdjust");

    return [
      statusBool,
      receiveEnableBool,
      receiveScheduleInt,
      receiveIntervalInt,
      receiveCountInt,
      receiveTimeAdjust
    ];
  }
}
