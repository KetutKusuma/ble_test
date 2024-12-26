import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class StatusConverter {
  static List<dynamic> convertBatteryStatus(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 3) {
      throw Exception("Invalid bytes convert");
    }
    // [9]

    bool statusBool = bytes[0] == 1;
    int volt1Int =
        BytesConvert.bytesToInt32(bytes.sublist(1, 5), isBigEndian: false);
    int volt2Int =
        BytesConvert.bytesToInt32(bytes.sublist(5, 9), isBigEndian: false);

    log("status : $statusBool");
    log("battery status : $volt1Int");
    log("battery level : $volt2Int");

    return [statusBool, volt1Int, volt2Int];
  }

  static List<dynamic> convertStorageStatus(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 3) {
      throw Exception("Invalid bytes convert");
    }
    // [9]

    bool statusBool = bytes[0] == 1;
    int getTotalBytes = BytesConvert.bytesToInt32(bytes.sublist(1, 5));
    int getUsedBytes = BytesConvert.bytesToInt32(bytes.sublist(5, 9));

    log("status : $statusBool");
    log("storage status : $getTotalBytes");
    log("storage level : $getUsedBytes");

    return [statusBool, getTotalBytes, getUsedBytes];
  }

  static List<dynamic> convertFileStatus(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 3) {
      throw Exception("Invalid bytes convert");
    }
    // [11]

    bool statusBool = bytes[0] == 1;
    int dirNear = BytesConvert.bytesToInt16(bytes.sublist(1, 5));
    int dirNearUnset = BytesConvert.bytesToInt16(bytes.sublist(5, 9));
    int dirImage = BytesConvert.bytesToInt16(bytes.sublist(5, 9));
    int dirImageUnset = BytesConvert.bytesToInt16(bytes.sublist(5, 9));
    int dirLog = BytesConvert.bytesToInt16(bytes.sublist(5, 9));

    log("status : $statusBool");
    log("dir near : $dirNear");
    log("dir near unset : $dirNearUnset");
    log("dir image : $dirImage");
    log("dir image unset : $dirImageUnset");
    log("dir log : $dirLog");

    return [statusBool, dirNear, dirNearUnset, dirImage, dirImageUnset, dirLog];
  }
}
