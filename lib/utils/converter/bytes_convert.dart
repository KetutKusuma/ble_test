import 'dart:convert';
import 'dart:developer';
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

  static bool bytesToBool(List<int> bytes) {
    bool value = bytes.isNotEmpty && bytes[0] == 1;
    return value;
  }

  static double bytesToFloatorDouble(List<int> bytes) {
    try {
      Uint8List uint8list = Uint8List.fromList(bytes);

      // Wrap the byte list with ByteData
      ByteData byteData = uint8list.buffer.asByteData();

      // Read the float from the ByteData (little-endian)
      double value = byteData.getFloat32(0, Endian.little);
      return value;
    } catch (e) {
      log("error When convert bytes to float : $e");
      return 0.0;
    }
  }

  static List<int> bytesToBits(List<int> byteArray) {
    // Convert each byte into bits and flatten into a single list of integers
    return byteArray.expand((byte) {
      return byte
          .toRadixString(2) // Convert byte to binary string
          .padLeft(8, '0') // Ensure it's 8 bits long
          .split('') // Split string into a list of characters
          .map(int.parse); // Convert characters ('0' or '1') to integers
    }).toList();
  }
}

class ConvertToBytes {
  static Uint8List stringToBytes(String string) {
    return Uint8List.fromList(utf8.encode(string));
  }
}
