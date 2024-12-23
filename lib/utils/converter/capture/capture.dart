import 'dart:developer';

import '../bytes_convert.dart';

class CaptureConverter {
  static List<dynamic> convertSquenceCaptureBuffer(
      List<int> bytes, int lengthByteChunk) {
    if (bytes.isEmpty || bytes.length < 20) {
      throw Exception("Invalid bytes convert");
    }
    int chuckSquenceNumber = BytesConvert.bytesToInt16(bytes.sublist(0, 2));
    int lengthInt = BytesConvert.bytesToInt16(bytes.sublist(2, 4));
    int chunkData =
        BytesConvert.bytesToInt16(bytes.sublist(4, 4 + lengthByteChunk));
    int crc32 = BytesConvert.bytesToInt16(
        bytes.sublist(4 + lengthByteChunk, 8 + lengthByteChunk));

    log("chuck squence number : $chuckSquenceNumber");
    log("length : $lengthInt");
    log("chunk data : $chunkData");
    log("crc32 : $crc32");

    return [chuckSquenceNumber, lengthInt, chunkData, crc32];
  }
}
