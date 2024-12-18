import 'dart:convert';
import 'dart:typed_data';

class BytesConvert {
  static String bytesToHex(List<int> bytes) {
    return bytes.map((e) => e.toRadixString(16).padLeft(2, '0')).join('');
  }

  static String bytesToString(List<int> bytes) {
    return String.fromCharCodes(bytes);
  }

  static String bytesToStringUseUtf8(List<int> bytes) {
    return utf8.decode(bytes);
  }

  static int bytesToInt8(List<int> bytes) {
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Read as int32 (little-endian)
    int result = byteData.getInt8(0);
    return result;
  }

  static int bytesToInt16(List<int> bytes) {
    // Create a ByteData from the list
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Read as int16 (little-endian)
    int result = byteData.getInt16(0, Endian.little);
    return result;
  }

  static int bytesToInt32(List<int> bytes) {
    // Create a ByteData from the list
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));

    // Read as int32 (little-endian)
    int result = byteData.getInt32(0, Endian.little);
    return result;
  }
}

class ConvertToBytes {
  static Uint8List stringToBytes(String string) {
    return Uint8List.fromList(utf8.encode(string));
  }
}
