import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:intl/intl.dart' as intl;

class ConvertV2 {
  int getTimeNowSeconds() {
    DateTime dateTimeS = DateTime.now();

    // Convert to Unix timestamp (in seconds)
    Duration durationTimeS = dateTimeS.timeZoneOffset;
    int helpDuration = durationTimeS.inSeconds;
    int unixTimestampSS = (dateTimeS.millisecondsSinceEpoch) ~/ 1000;
    return (unixTimestampSS + helpDuration) - 946684800;
  }

  String minuteToDateTimeString(int minute) {
    int hh = minute ~/ 60;
    int mm = minute % 60;
    return "${hh.toString().padLeft(2, '0')}:${mm.toString().padLeft(2, '0')}";
  }

  int dateTimeStringToMinute(String s) {
    if (s.isEmpty) throw const FormatException("Invalid time format");
    var parts = s.split(":");
    if (parts.length != 2) throw const FormatException("Invalid time format");

    int hh = int.tryParse(parts[0]) ?? -1;
    int mm = int.tryParse(parts[1]) ?? -1;

    if (hh == -1 || mm == -1)
      throw const FormatException("Invalid time format");

    return hh * 60 + mm;
  }

  List<int> stringHexAddressToArrayUint8(String input, int byteLength) {
    int expectedLen = byteLength * 2 + (byteLength - 1);
    if (input.length != expectedLen) {
      throw FormatException("Input length must be $expectedLen");
    }

    List<int> result = [];
    for (int i = 0; i < byteLength; i++) {
      var hex = input.substring(i * 3, i * 3 + 2);
      result.add(int.parse(hex, radix: 16));
    }
    return result;
  }

  String arrayUint8ToStringHexAddress(List<int> input) {
    return input.map((e) => e.toRadixString(16).padLeft(2, '0')).join(":");
  }

  String arrayUint8ToString(List<int> input) {
    return input.map((e) => e.toRadixString(16).padLeft(2, '0')).join("");
  }

  List<int> stringHexToArrayUint8(String input, int byteLength) {
    int expectedLen = byteLength * 2;
    if (input.length != expectedLen) {
      throw FormatException("Input length must be $expectedLen");
    }

    List<int> result = [];
    for (int i = 0; i < byteLength; i++) {
      var hex = input.substring(i * 2, i * 2 + 2);
      result.add(int.parse(hex, radix: 16));
    }
    return result;
  }

  String uint8ToUtcString(int utc) {
    String mm = utc % 2 != 0 ? "30" : "00";
    if (utc < 24) {
      return "-${(24 - utc) ~/ 2}:$mm";
    } else {
      return "+${(utc - 24) ~/ 2}:$mm";
    }
  }

  String formatNumberForUTC(String input) {
    // Cek apakah string diawali dengan "-" atau "+"
    if (input.startsWith("-") || input.startsWith("+")) {
      // Jika panjang string kurang dari 6, tambahkan "0" di index ke-1
      if (input.length < 6) {
        return input[0] + "0" + input.substring(1);
      }
    }
    return input;
  }

  int utcStringToUint8(String utc) {
    try {
      utc = formatNumberForUTC(utc);

      RegExp regExp = RegExp(r"^[-+]?(0[0-9]|1[0-2]):(00|30)$");
      if (!regExp.hasMatch(utc)) {
        throw const FormatException("Invalid format");
      }

      if (utc.length == 5) {
        utc = "+" + utc;
      }
      int h = int.parse(utc.substring(1, 3));
      int m = utc.substring(4, 6) == "30" ? 1 : 0;
      if (utc[0] == '-') {
        return (12 - h) * 2 - m;
      } else {
        return 24 + h * 2 + m;
      }
    } catch (e) {
      throw "Error catch on utcStringToUint8: $e";
    }
  }

  int stringHexToUint8(String input, int startIndex) {
    return int.parse(input.substring(startIndex, startIndex + 2), radix: 16);
  }

  int stringHexToUint16(String input, int startIndex) {
    return int.parse(input.substring(startIndex, startIndex + 4), radix: 16);
  }

  int stringHexToUint32(String input, int startIndex) {
    return int.parse(input.substring(startIndex, startIndex + 8), radix: 16);
  }

  String bufferToString(List<int> buffer) {
    return String.fromCharCodes(buffer);
  }

  String bufferToStringUsingIndex(
      List<int> buffer, int startIndex, int length) {
    int endIndex = buffer.length;
    if (length > 0) {
      endIndex = startIndex + length;
    }
    return String.fromCharCodes(buffer.sublist(startIndex, endIndex));
  }

  String bufferToStringUTF8(List<int> listData, int index, int length) {
    List<int> lala = listData
        .sublist(
          index,
          index + length,
        )
        .toList();

    lala.removeWhere((element) => element == 0);
    if (lala.isEmpty) {
      return "";
    }
    String custom = utf8.decode(lala).trim();

    return custom;
  }

  bool bufferToBool(List<int> buffer, int startIndex) {
    return (buffer[startIndex]) == 1;
  }

  int bufferToInt8(List<int> buffer, int startIndex) {
    return uint8ToInt8(buffer[startIndex]);
  }

  int bufferToUint8(List<int> buffer, int startIndex) {
    return buffer[startIndex];
  }

  int bufferToUint16(List<int> buffer, int startIndex) {
    int value2 =
        ((buffer[startIndex + 1] & 0xFF) << 8) | (buffer[startIndex] & 0xFF);
    int value =
        (buffer[startIndex + 1] & 0xFF << 8) | (buffer[startIndex] & 0xFF);
    return value2;
  }

  int bufferToUint16V2(List<int> buffer) {
    ByteData byteData = ByteData.sublistView(Uint8List.fromList(buffer));

    int value = byteData.getUint16(0, Endian.little);
    return value;
  }

  int bufferToUint32(List<int> buffer, int startIndex) {
    return (buffer[startIndex]) |
        (buffer[startIndex + 1] << 8) |
        (buffer[startIndex + 2] << 16) |
        (buffer[startIndex + 3] << 24);
  }

  int bufferToUint32BigEndian(List<int> buffer, int startIndex) {
    return (buffer[startIndex + 3]) |
        (buffer[startIndex + 2] << 8) |
        (buffer[startIndex + 1] << 16) |
        (buffer[startIndex] << 24);
  }

  double bufferToFloat32(List<int> buffer, int startIndex) {
    final byteData = ByteData.sublistView(
        Uint8List.fromList(buffer), startIndex, startIndex + 4);
    return byteData.getFloat32(0, Endian.little);
  }

  int uint8ToInt8(int i) {
    if (i >= 128) {
      return -((255 - i + 1));
    }
    return i;
  }

  void insertInt8ToBuffer(int data, Uint8List buffer, int startIndex) {
    buffer[startIndex] = data & 0xFF;
  }

  void insertUint16ToBuffer(int data, Uint8List buffer, int startIndex) {
    buffer[startIndex] = data & 0x00FF;
    buffer[startIndex + 1] = (data >> 8) & 0xFF;
  }

  void insertUint32ToBuffer(int data, List<int> buffer, int startIndex) {
    buffer[startIndex] = data & 0x000000FF;
    buffer[startIndex + 1] = (data >> 8) & 0x0000FF;
    buffer[startIndex + 2] = (data >> 16) & 0x00FF;
    buffer[startIndex + 3] = (data >> 24) & 0xFF;
  }

  void insertFloat32ToBuffer(double data, Uint8List buffer, int startIndex) {
    var byteData = ByteData(4);
    byteData.setFloat32(0, data, Endian.little);
    for (int i = 0; i < 4; i++) {
      buffer[startIndex + i] = byteData.getUint8(i);
    }
  }

  bool getBit(int data, int index) {
    if (index > (8 * (data.bitLength ~/ 8) - 1)) {
      return false;
    }
    return ((data & (1 << index)) >> index) == 1;
  }

  bool setBit(int data, int index, bool value) {
    if (index > (8 * (data.bitLength ~/ 8) - 1)) {
      return false;
    }
    if (value) {
      data |= (1 << index);
    } else {
      data &= ~(1 << index);
    }
    return true;
  }

  List<int> hexStringtoList(String hexString) {
    List<int> byteList = [];
    for (int i = 0; i < hexString.length; i += 2) {
      String hexPair = hexString.substring(i, i + 2);
      byteList.add(int.parse(hexPair, radix: 16));
    }
    return byteList;
  }
}

class ConvertTime {
  static String minuteToDateTimeString(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return "${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}";
  }

  static int dateTimeStringToMinute(String time) {
    final parts = time.split(":");
    if (parts.length != 2) throw const FormatException("Invalid time format");
    final hours = int.parse(parts[0]);
    final minutes = int.parse(parts[1]);
    return hours * 60 + minutes;
  }

  static bool getBit(int value, int position) {
    log("special dates get bit : ${(value & (1 << position))}");
    return (value & (1 << position)) != 0;
  }

  static int setBit(int value, int position, bool state) {
    if (state) {
      return value | (1 << position);
    } else {
      return value & ~(1 << position);
    }
  }

  static String dateFormatDateTime(DateTime dateTime) {
    String formattedDate =
        intl.DateFormat("yyyy-MM-dd HH:mm:ss").format(dateTime);
    return formattedDate;
  }
}
