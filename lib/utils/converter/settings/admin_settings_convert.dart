import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class AdminSettingsConverter {
  List<dynamic> convertAdminSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 17) {
      throw Exception("Invalid bytes convert");
    }

    // 0:1 -> byte to bool
    bool boolStatus = bytes[0] != 0;

    // 1:5 -> bytes to string (MAC-like address)
    // log("sublist 1,6 : ${bytes.sublist(1, 5)}");
    String macAddress = bytes
        .sublist(1, 6)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':');

    bool boolEnable = bytes[6] != 0;

    // 6:9 -> bytes to float
    // log("list 7 : ${bytes[7]}");
    log("sublist 7,10 : ${bytes.sublist(7, 11)}");
    double floatVoltageCoef1 =
        BytesConvert.bytesToFloatorDouble(bytes.sublist(7, 11));

    // 10:13 -> bytes to float
    log("sublist 11,14 : ${bytes.sublist(11, 15)}");
    double floatVoltageCoef2 =
        BytesConvert.bytesToFloatorDouble(bytes.sublist(11, 15));

    // 14:15 -> byte to bit (convert to individual bits)
    // log("sublist 15,16 : ${bytes.sublist(15, 16)}");
    List<int> bits = BytesConvert.bytesToBits(bytes.sublist(15, 17));

    // 15:16 -> byte to bool

    // log("bytes 16 : ${bytes[16]} bytes 15 : ${bytes[15]}");
    // log("bytes 17 : ${bytes[17] == 0}");
    int intRole = BytesConvert.bytesToInt8([bytes[17]]);

    // Print results
    log('Bool status: $boolStatus');
    log('id: $macAddress');
    log("Bool enable : $boolEnable");
    log('Float 1: $floatVoltageCoef1');
    log('Float 2: $floatVoltageCoef2');
    log('Bits: $bits');
    log('Int Role: $intRole');

    return [
      boolStatus,
      macAddress,
      boolEnable,
      floatVoltageCoef1,
      floatVoltageCoef2,
      bits,
      intRole
    ];
  }
}
