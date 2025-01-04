import 'dart:developer';

import '../bytes_convert.dart';

class TransmitSettingsConvert {
  static List<dynamic> convertTransmitSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 30) {
      throw Exception("Invalid bytes convert");
    }

    bool statusBool = bytes[0] == 1;
    List<bool> destinationEnable = convertTransmitDestinationEnable(bytes[1])
        .map((value) => value == 1)
        .toList();

    List<String> destinationId = convertDestinationID(bytes.sublist(2, 42));
    // int transmitScheduleInt =
    //     BytesConvert.bytesToInt16(bytes.sublist(27, 37), isBigEndian: false);
    List<int> transmitScheduleInt =
        convertTransmitSchedule(bytes.sublist(42, 58));

    log("status : $statusBool");
    log("destination enable : $destinationEnable");
    log("destination id : $destinationId");
    log("transmit schedule : $transmitScheduleInt");

    return [statusBool, destinationEnable, destinationId, transmitScheduleInt];
  }

  static List<String> convertDestinationID(List<int> bytes) {
    List<String> formattedChunks = [];
    for (int i = 0; i < bytes.length; i += 5) {
      List<int> chunk = bytes.sublist(i, i + 5); // Get a chunk of 5
      String formatted = chunk.map((value) {
        return value
            .toRadixString(16)
            .padLeft(2, '0'); // Convert to hex and pad
      }).join(':'); // Join with ':'
      formattedChunks.add(formatted);
    }

    // Join all formatted chunks with a comma
    return formattedChunks;
  }

  static List<int> convertTransmitSchedule(List<int> bytes) {
    List<int> listResultInt = [];
    for (int i = 0; i < bytes.length; i += 2) {
      List<int> chunk = bytes.sublist(i, i + 2);
      int rees = BytesConvert.bytesToInt16(chunk, isBigEndian: false);
      listResultInt.add(rees);
    }
    return listResultInt;
  }

  static List<int> convertTransmitDestinationEnable(int value) {
    // Convert to binary string
    String binaryString = value.toRadixString(2);

    // Pad to 8 bits (if necessary)
    binaryString = binaryString.padLeft(8, '0');

    // Convert to a list of integers
    List<int> binaryArray = binaryString.split('').map(int.parse).toList();

    List<int> resultReverse = binaryArray.reversed.toList();

    /// get the 5 first
    List<int> result = resultReverse.sublist(0, 8);

    return result;
  }
}
