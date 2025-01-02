import 'dart:developer';

import '../bytes_convert.dart';

class TransmitSettingsConvert {
  static List<dynamic> convertTransmitSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 30) {
      throw Exception("Invalid bytes convert");
    }

    bool statusBool = bytes[0] == 1;
    bool destinationEnable = bytes[1] == 1;
    String destinationId = convertDestinationID(bytes.sublist(2, 27));
    // int transmitScheduleInt =
    //     BytesConvert.bytesToInt16(bytes.sublist(27, 37), isBigEndian: false);
    String transmitScheduleInt = convertTransmitSchedule(bytes.sublist(27, 37));

    if (bytes.sublist(2, 27).every((element) => element == 0)) {
      destinationId = '-';
    }

    log("status : $statusBool");
    log("destination enable : $destinationEnable");
    log("destination id : $destinationId");
    log("transmit schedule : $transmitScheduleInt");

    return [statusBool, destinationEnable, destinationId, transmitScheduleInt];
  }

  static String convertDestinationID(List<int> bytes) {
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
    String result = formattedChunks.join('\n');
    return result;
  }

  static String convertTransmitSchedule(List<int> bytes) {
    List<int> listResultInt = [];
    for (int i = 0; i < bytes.length; i += 2) {
      List<int> chunk = bytes.sublist(i, i + 2);
      listResultInt.add(BytesConvert.bytesToInt16(chunk, isBigEndian: false));
    }
    return listResultInt.toString();
  }
}
