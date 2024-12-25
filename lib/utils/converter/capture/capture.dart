import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/utils/crc32.dart';

import '../bytes_convert.dart';

class CaptureConverter {
  static List<dynamic> convertSquenceCapture(
      List<int> bytes, int lengthByteChunk) {
    if (bytes.isEmpty || bytes.length < 400) {
      throw Exception("Invalid bytes convert");
    }

    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    log("MASUK CONVERTER SEQUENCE CAPTURE");
    int chuckSquenceNumber =
        BytesConvert.bytesToInt16(bytes.sublist(0, 2), isBigEndian: true);
    int lengthInt = byteData.getUint16(2, Endian.big);
    // -- FOR CHUNK DATA --

    List<int> chunkData = bytes.sublist(4, lengthInt + 4);

    List<int> sublistCrc32 = bytes.sublist(lengthInt + 4, lengthInt + 8);
    int crc32 = byteData.getUint32((lengthInt + 4), Endian.big);
    // melakukan pengecekan crc32
    int calculatedCrc32 = CRC32.compute(chunkData);

    /// checking
    log("hashing chunck data crc32 : $calculatedCrc32");
    log("MATCH : ${calculatedCrc32 == crc32} | $crc32 == $calculatedCrc32");

    log("-- check if the length of chunck data == lengthInt we got ---");
    log("${chunkData.length == lengthInt} | ${chunkData.length} == $lengthInt");

    return [chuckSquenceNumber, lengthInt, chunkData, crc32];
  }

  static List<dynamic> convertManifestCapture(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 35) {
      throw Exception("Invalid bytes convert");
    }

    // Convert to ByteData for easier parsing
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Extract fields
    bool status = byteData.getUint8(0) == 1; // First byte is status
    String message = utf8
        .decode(bytes.sublist(1, 33))
        .replaceAll('\x00', ''); // Bytes 1 to 32, decoded to string and cleaned
    int totalChunk =
        byteData.getUint16(33, Endian.big); // Bytes 33-34 as uint16
    int crc32 = byteData.getUint32(35, Endian.little); // Bytes 35-38 as uint32

    // Print results
    log('status: $status');
    log('message: $message');
    log('total_chunk: $totalChunk');
    log('crc32: $crc32');

    return [status, message, totalChunk, crc32];
  }
}
