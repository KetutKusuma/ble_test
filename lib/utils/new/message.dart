import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/utils/crc32.dart';
import 'package:encrypt/encrypt.dart';

class MessageNew {
  static const int Request = 0;
  static const int Response = 1;

  static bool allowAddParameter(List<int> buffer) {
    if (buffer.length >= 8) {
      return buffer[8] < 254;
    }
    return false;
  }

  static int addParameter(int parameterLen, List<int> buffer) {
    buffer[8] = buffer[8] + 1;
    int startIndex = buffer.length;
    buffer.addAll(List.filled(1 + parameterLen, 0));
    buffer[startIndex] = parameterLen;
    return startIndex + 1;
  }

  static Map<String, List<int>> getKEYandIV() {
    return {
      "key": [
        173,
        217,
        109,
        178,
        176,
        214,
        198,
        8,
        110,
        22,
        101,
        92,
        3,
        139,
        155,
        170,
        82,
        81,
        174,
        190,
        233,
        70,
        184,
        119,
        240,
        61,
        237,
        66,
        203,
        172,
        247,
        70,
      ],
      "iv": [
        91,
        152,
        230,
        244,
        26,
        128,
        35,
        236,
        75,
        21,
        23,
        49,
        118,
        216,
        134,
        141
      ]
    };
  }

  static List<int> createBegin(
      int uniqueID, int requestResponse, int command, List<int> buffer) {
    // Use a dynamic list to allow modifications
    List<int> dynamicBuffer = [];

    // Initialize with 9 bytes
    dynamicBuffer.addAll(List.filled(9, 0));

    // Set the timestamp (4 bytes)
    // print("seconds :${DateTime.now().millisecondsSinceEpoch ~/ 1000}");
    // print(
    //     "hasil uint32bytes : ${_uint32ToBytes(DateTime.now().millisecondsSinceEpoch ~/ 1000)}");
    // print("hasil uint16bytes : ${_uint16ToBytes(uniqueID)}");
    dynamicBuffer.setRange(
        0, 4, _uint32ToBytes(DateTime.now().millisecondsSinceEpoch ~/ 1000));

    // Set the unique ID (2 bytes)
    dynamicBuffer.setRange(4, 6, _uint16ToBytes(uniqueID));

    // Set the requestResponse, command, and reserved byte
    dynamicBuffer[6] = requestResponse;
    dynamicBuffer[7] = command;
    dynamicBuffer[8] = 0;

    // Convert back to Uint8List
    return dynamicBuffer;
  }

  static bool addBool(bool value, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(1, buffer);
    buffer[startIndex] = value ? 1 : 0;
    return true;
  }

  static bool addInt8(int value, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(1, buffer);
    buffer[startIndex] = value & 0xFF;
    return true;
  }

  static bool addUint8(int value, List<int> buffer) {
    if (!allowAddParameter(buffer)) {
      return false;
    }
    int startIndex = addParameter(1, buffer);
    buffer[startIndex] = value;
    return true;
  }

  static bool addUint16(int value, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(2, buffer);
    buffer.setRange(startIndex, startIndex + 2, _uint16ToBytes(value));
    return true;
  }

  static bool addUint32(int value, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(4, buffer);
    buffer.setRange(startIndex, startIndex + 4, _uint32ToBytes(value));
    return true;
  }

  static bool addFloat32(double value, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(4, buffer);
    buffer.setRange(startIndex, startIndex + 4,
        Float32List.fromList([value]).buffer.asUint8List());
    return true;
  }

  static bool addArrayOfUint8(List<int> data, List<int> buffer) {
    if (!allowAddParameter(buffer) || data.length > 255) return false;
    int startIndex = addParameter(data.length, buffer);
    buffer.setRange(startIndex, startIndex + data.length, data);
    return true;
  }

  static bool addString(String data, List<int> buffer) {
    log("mama");
    if (!allowAddParameter(buffer) || data.length > 255) {
      return false;
    }
    log("masuk samapai start index");
    int startIndex = addParameter(data.length, buffer);
    log("add paramater masuk sih");
    buffer.setRange(startIndex, startIndex + data.length, utf8.encode(data));
    return true;
  }

  static String createEnd(
      int status, List<int> buffer, List<int> key, List<int> iv) {
    int startIndex = buffer.length;
    buffer.addAll(List.filled(5, 0));
    buffer[startIndex] = status;
    int crc32 = _calculateCRC32(buffer.sublist(0, startIndex + 1));
    print("CRC32 create end : $crc32");
    buffer.setRange(startIndex + 1, startIndex + 5, _uint32ToBytes(crc32));
    return base64Encode(_aesEncrypt(buffer, key, iv));
  }

  static Future<List<int>?> parse(
      String data, List<int> key, List<int> iv, List<int> buffer) async {
    List<int> encryptedInput = base64Decode(data);
    buffer = _aesDecrypt(encryptedInput, key, iv);
    print("decrypted : $buffer");
    if (buffer.length < 4 ||
        _calculateCRC32(buffer.sublist(0, buffer.length - 4)) !=
            _bytesToUint32(buffer, (buffer.length - 4))) {
      throw Exception("CRC32 mismatch or insufficient buffer size");
    } else {
      print("parse succes!!!");
      return buffer;
    }
  }

  static List<int> _uint32ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  static List<int> _uint16ToBytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
    ];
  }

  static int _bytesToUint32(List<int> bytes, int startIndex) {
    return (bytes[startIndex] & 0x000000ff) |
        ((bytes[startIndex + 1] & 0x000000ff) << 8) |
        ((bytes[startIndex + 2] & 0x000000ff) << 16) |
        ((bytes[startIndex + 3] & 0x000000ff) << 24);
  }

  static int _calculateCRC32(List<int> data) {
    // Implement CRC32 calculation here.
    return CRC32.compute(data);
  }

  static List<int> _aesEncrypt(List<int> data, List<int> key, List<int> iv) {
    final encrypter =
        Encrypter(AES(Key(Uint8List.fromList(key)), mode: AESMode.cbc));
    List<int> result =
        encrypter.encryptBytes(data, iv: IV(Uint8List.fromList(iv))).bytes;
    print("encrypt result : $result");
    return result;
  }

  static List<int> _aesDecrypt(List<int> data, List<int> key, List<int> iv) {
    final encrypter =
        Encrypter(AES(Key(Uint8List.fromList(key)), mode: AESMode.cbc));
    List<int> result = encrypter.decryptBytes(
        Encrypted(Uint8List.fromList(data)),
        iv: IV(Uint8List.fromList(iv)));

    return result;
  }
}
