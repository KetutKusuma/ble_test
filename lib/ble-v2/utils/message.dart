import 'dart:developer';
import 'dart:typed_data';
import 'dart:convert';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/crypto.dart';
import 'package:ble_test/utils/crc32.dart';
import 'package:encrypt/encrypt.dart';

class Header {
  int? dateTime;
  int? uniqueID;
  int? requestResponse;
  int? command;
  int? parameterCount;
  bool status;

  Header({
    this.dateTime,
    this.uniqueID,
    this.requestResponse,
    this.command,
    this.parameterCount,
    required this.status,
  });

  @override
  String toString() {
    // TODO: implement toString
    return "dateTime: $dateTime, uniqueID: $uniqueID, requestResponse: $requestResponse, command: $command, parameterCount: $parameterCount, status: $status";
  }
}

class MessageV2 {
  static int request = 0;
  static int response = 1;

  bool allowAddParameter(List<int> buffer) {
    if (buffer.length >= 8) {
      return buffer[8] < 254;
    }
    return false;
  }

  int addParameter(int parameterLen, List<int> buffer) {
    buffer[8] = buffer[8] + 1;
    int startIndex = buffer.length;
    buffer.addAll(List.filled(1 + parameterLen, 0));
    buffer[startIndex] = parameterLen;
    return startIndex + 1;
  }

  void createBegin(
      int uniqueID, int requestResponse, int command, List<int> buffer) {
    buffer.clear();
    buffer.addAll(List.filled(9, 0));

    buffer.setRange(
        0, 4, intToUint8List(DateTime.now().millisecondsSinceEpoch ~/ 1000));
    buffer.setRange(4, 6, intToUint8List(uniqueID));
    buffer[6] = requestResponse;
    buffer[7] = command;
    buffer[8] = 0;
  }

  bool addBool(bool b, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(1, buffer);
    buffer[startIndex] = b ? 1 : 0;
    return true;
  }

  bool addInt8(int i, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(1, buffer);
    buffer[startIndex] = i;
    return true;
  }

  bool addUint8(int i, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(1, buffer);
    buffer[startIndex] = i;
    return true;
  }

  bool addUint16(int i, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(2, buffer);
    buffer.setRange(startIndex, startIndex + 2, intToUint8List(i));
    return true;
  }

  bool addUint32(int i, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(4, buffer);
    buffer.setRange(startIndex, startIndex + 4, intToUint8List(i));
    return true;
  }

  bool addFloat32(double f, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    int startIndex = addParameter(4, buffer);
    var byteArray = ByteData(4)..setFloat32(0, f, Endian.little);
    buffer.setRange(startIndex, startIndex + 4, byteArray.buffer.asUint8List());
    return true;
  }

  bool addArrayOfUint8(List<int> data, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    if (data.length > 255) return false;
    int startIndex = addParameter(data.length, buffer);
    buffer.setRange(startIndex, startIndex + data.length, data);
    return true;
  }

  bool addString(String data, List<int> buffer) {
    if (!allowAddParameter(buffer)) return false;
    if (data.length > 255) return false;
    int startIndex = addParameter(data.length, buffer);
    buffer.setRange(startIndex, startIndex + data.length, utf8.encode(data));
    return true;
  }

  List<int> createEnd(
      int status, List<int> buffer, List<int> key, List<int> iv) {
    int startIndex = buffer.length;
    int l = 1 + 4;
    buffer.addAll(List.filled(l, 0));
    buffer[startIndex] = status;

    // You may need to implement a CRC32 method in Dart or use a package.
    int crc32 = CRC32.compute(buffer.sublist(0, startIndex + 1));

    buffer.setRange(startIndex + 1, startIndex + 5, intToUint8List(crc32));

    // final encrypted = await encryptData(buffer, key, iv);
    final encrypted = aesEncrypt(buffer, key, iv);

    return encrypted;
  }

  List<int> aesEncrypt(List<int> data, List<int> key, List<int> iv) {
    final encrypter =
        Encrypter(AES(Key(Uint8List.fromList(key)), mode: AESMode.cbc));
    List<int> result =
        encrypter.encryptBytes(data, iv: IV(Uint8List.fromList(iv))).bytes;
    print("encrypt result : $result");
    return result;
  }

  Header getHeader(List<int> buffer) {
    if (buffer.length < 9) {
      return Header(
          dateTime: 0,
          uniqueID: 0,
          requestResponse: 0,
          command: 0,
          parameterCount: 0,
          status: false);
    }

    return Header(
      dateTime: bytesToInt32(buffer.sublist(0, 4)),
      uniqueID: bytesToInt16(buffer.sublist(4, 6)),
      requestResponse: buffer[6],
      command: buffer[7],
      parameterCount: buffer[8],
      status: buffer[buffer.length - 5] == 1,
    );
  }

  int bytesToInt16(List<int> bytes) {
    return (bytes[0] << 8) + bytes[1];
  }

  int bytesToInt32(List<int> bytes) {
    return (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];
  }

  List<int> intToUint8List(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  Future<bool> parse(
      List<int> data, List<int> key, List<int> iv, List<int> buffer) async {
    try {
      log("datanya yg mau di parse : $data");
      buffer.clear();
      buffer.addAll(CryptoUtilsV2.aesDecrypt(data, key, iv));
      if (buffer.length < 4) {
        log("insufficient buffer size");
        throw Exception("insufficient buffer size");
      }
      int crc32 = CryptoUtilsV2.crc32(buffer.sublist(0, buffer.length - 4));
      if (crc32 != ConvertV2().bufferToUint32(buffer, buffer.length - 4)) {
        log("crc32 mismatch");
        throw Exception("crc32 mismatch");
      }
      return true;
    } catch (e) {
      log("Error catch on parse : $e");
      return false;
    }
  }

  List<int>? getParameter(List<int> buffer, int index) {
    if (buffer.length < 9) return null;
    int parameterCount = buffer[8];
    if (index >= parameterCount) return null;

    int counter = 0;
    int pos = 8;
    while (counter <= index) {
      pos += 1;
      int length = buffer[pos];
      if (counter == index) {
        return buffer.sublist(pos + 1, pos + 1 + length);
      }
      pos += length;
      if (pos >= buffer.length) return null;
      counter++;
    }
    return null;
  }

  int? getParameterUint8(List<int> buffer, int index) {
    List<int>? b = getParameter(buffer, index);
    return b != null && b.isNotEmpty ? b[0] : null;
  }

  int? getParameterUint16(List<int> buffer, int index) {
    List<int>? b = getParameter(buffer, index);
    return b != null ? ConvertV2().bufferToUint16(b, 0) : null;
  }

  int? getParameterUint32(List<int> buffer, int index) {
    List<int>? b = getParameter(buffer, index);
    return b != null ? ConvertV2().bufferToUint32(b, 0) : null;
  }

  double? getParameterFloat32(List<int> buffer, int index) {
    List<int>? b = getParameter(buffer, index);
    return b != null ? ConvertV2().bufferToFloat32(b, 0) : null;
  }

  String? getParameterString(List<int> buffer, int index) {
    List<int>? b = getParameter(buffer, index);
    return b != null ? utf8.decode(b) : null;
  }
}
