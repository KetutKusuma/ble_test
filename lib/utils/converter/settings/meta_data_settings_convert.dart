import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class MetaDataSettingsConvert {
  static List<dynamic> convertMetaDataSettings(List<int> bytes) {
    try {
      if (bytes.isEmpty || bytes.length < 45) {
        throw Exception("Invalid bytes convert");
      }
      log("data convert meta data settings : ${bytes}");

      bool statusBool = bytes[0] == 1;
      String modelMeter = BytesConvert.bytesToString(bytes.sublist(1, 17));
      String meterSN = BytesConvert.bytesToString(bytes.sublist(17, 33));
      String meterSeal = BytesConvert.bytesToString(bytes.sublist(33, 49));
      int timeUtc = BytesConvert.bytesToInt8([bytes[81]]);
      String description = BytesConvert.bytesToString(bytes.sublist(49, 80));

      if (bytes.sublist(1, 17).every((element) => element == 0)) {
        modelMeter = '-';
      }

      if (bytes.sublist(17, 33).every((element) => element == 0)) {
        meterSN = '-';
      }

      if (bytes.sublist(33, 49).every((element) => element == 0)) {
        meterSeal = '-';
      }

      if (bytes.sublist(50, 81).every((element) => element == 0)) {
        description = '-';
      }

      log("model meter : $modelMeter");
      log("meter SN : $meterSN");
      log("meter seal : $meterSeal");
      log("time utc : $timeUtc");

      return [statusBool, modelMeter, meterSN, meterSeal, timeUtc, description];
    } catch (e) {
      log("Error convert meta data settings : $e");
      return [];
    }
  }
}
