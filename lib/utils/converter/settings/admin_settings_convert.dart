import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class AdminSettingsConverter {
  List<dynamic> convertAdminSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 19) {
      throw Exception("Invalid bytes convert");
    }

    // for (int i = 0; i < bytes.length; i++) {
    //   log("mama [$i] = ${bytes[i]}");
    // }

    // 0:1 -> byte to bool
    bool boolStatus = bytes[0] != 0;

    // 1:5 -> bytes to string (MAC-like address)
    log("sublist 1,6 : ${bytes.sublist(1, 6)}");
    String macAddress = bytes
        .sublist(1, 6)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':');

    // 6:9 -> bytes to float
    // log("list 7 : ${bytes[7]}");
    log("sublist 6,10 : ${bytes.sublist(6, 10)}");
    double floatVoltageCoef1 =
        BytesConvert.bytesToFloatorDouble(bytes.sublist(6, 10));

    // 10:13 -> bytes to float
    log("sublist 10,13 : ${bytes.sublist(10, 14)}");
    double floatVoltageCoef2 =
        BytesConvert.bytesToFloatorDouble(bytes.sublist(10, 14));

    int brightnessInt = BytesConvert.bytesToInt8([bytes[14]]);
    int contrastInt = BytesConvert.bytesToInt8([bytes[15]]);
    int saturationInt = BytesConvert.bytesToInt8([bytes[16]]);
    int specialEffectInt = BytesConvert.bytesToInt8([bytes[17]]);
    bool hmirrorBool = bytes[18] == 1;
    bool vflipBool = bytes[19] == 1;

    int cameraJpgQuality = BytesConvert.bytesToInt8([bytes[20]]);
    int intRole = BytesConvert.bytesToInt8([bytes[21]]);

    // Print results
    log("boolStatus: $boolStatus");
    log("macAddress: $macAddress");
    log("floatVoltageCoef1: $floatVoltageCoef1");
    log("floatVoltageCoef2: $floatVoltageCoef2");
    log("brightnessInt: $brightnessInt");
    log("contrastInt: $contrastInt");
    log("saturationInt: $saturationInt");
    log("specialEffectInt: $specialEffectInt");
    log("hmirrorBool: $hmirrorBool");
    log("vflipBool: $vflipBool");
    log("cameraJpgQuality: $cameraJpgQuality");
    log("intRole: $intRole");

    return [
      boolStatus,
      macAddress,
      floatVoltageCoef1,
      floatVoltageCoef2,
      brightnessInt,
      contrastInt,
      saturationInt,
      specialEffectInt,
      hmirrorBool,
      vflipBool,
      cameraJpgQuality,
      intRole
    ];
  }

  List<dynamic> convertAdminCameraSettings(List<int> bits) {
    if (bits.isEmpty || bits.length < 17) {
      throw Exception("Invalid bytes convert");
    }

    List<dynamic> mappedValues = [];
    for (int i = 0; i < 9; i += 3) {
      mappedValues.add(bitsToMappedInt(bits.sublist(i, i + 2)));
    }
    int directInt = bitsToInt(bits.sublist(9, 12));
    bool bool1 = bitToBool(bits[12]);
    bool bool2 = bitToBool(bits[13]);
    mappedValues.addAll([directInt, bool1, bool2]);

    return mappedValues;
  }

  int bitsToMappedInt(List<int> bits) {
    if (bits.length != 2) {
      throw ArgumentError("Input must be exactly 2 bits.");
    }
    int value = bits[0] * 2 + bits[1]; // Convert binary to integer
    return value - 2; // Map 0->-2, 1->-1, 2->0, 3->1
  }

// Function to convert bits directly to integer
  int bitsToInt(List<int> bits) {
    int value = 0;
    for (int i = 0; i < bits.length; i++) {
      value = (value << 1) | bits[i]; // Shift and add bit
    }
    return value;
  }

// Function to convert a single bit to boolean
  bool bitToBool(int bit) {
    return bit == 1;
  }
}
