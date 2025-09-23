import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class CaptureSettingsConverter {
  static List<dynamic> convertCaptureSettings(List<int> bytes) {
    bool statusBool = bytes[0] == 1;

    int captureScheduleInt = BytesConvert.bytesToInt16(
      bytes.sublist(1, 3),
      isBigEndian: false,
    );
    int captureIntervalInt = BytesConvert.bytesToInt16(
      bytes.sublist(3, 5),
      isBigEndian: false,
    );
    int captureCountInt = BytesConvert.bytesToInt8([bytes[5]]);
    int captureRecentLimitInt = BytesConvert.bytesToInt16(
      bytes.sublist(6, 8),
      isBigEndian: false,
    );
    List<int> spCaptureDateInt = bytesToBits(bytes.sublist(8, 12));
    log("sp capture date before : ${bytes.sublist(8, 12)}");
    int spCaptureScheduleInt = BytesConvert.bytesToInt16(
      bytes.sublist(12, 14),
      isBigEndian: false,
    );
    int spCaptureIntervalInt = BytesConvert.bytesToInt16(
      bytes.sublist(14, 16),
      isBigEndian: false,
    );
    int spCaptureCountInt = BytesConvert.bytesToInt8([bytes[16]]);

    log("capture schedule : $captureScheduleInt");
    log("capture interval : $captureIntervalInt");
    log("capture count : $captureCountInt");
    log("capture recent limit : $captureRecentLimitInt");
    log("sp capture date : $spCaptureDateInt");
    log("sp capture schedule : $spCaptureScheduleInt");
    log("sp capture interval : $spCaptureIntervalInt");
    log("sp capture count : $spCaptureCountInt");

    return [
      statusBool,
      captureScheduleInt,
      captureIntervalInt,
      captureCountInt,
      captureRecentLimitInt,
      spCaptureDateInt,
      spCaptureScheduleInt,
      spCaptureIntervalInt,
      spCaptureCountInt,
    ];
  }

  static List<int> bytesToBits(List<int> bytes) {
    List<int> bits = bytes.expand((byte) {
      return List<int>.generate(8, (i) => (byte >> (7 - i)) & 1).reversed;
    }).toList();
    return bits;
  }
}
