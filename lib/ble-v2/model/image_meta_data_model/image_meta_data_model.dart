import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/ble-v2/utils/crypto.dart';
import 'package:intl/intl.dart';

const int MARKER = 255;

class ImageMetaData {
  List<int> id;
  int dateTimeTaken;
  double temperature;
  double voltageBattery1;
  double voltageBattery2;
  String meterModel;
  String meterSN;
  String meterSeal;
  String custom;
  int timeUTC;

  ImageMetaData({
    required this.id,
    required this.dateTimeTaken,
    required this.temperature,
    required this.voltageBattery1,
    required this.voltageBattery2,
    required this.meterModel,
    required this.meterSN,
    required this.meterSeal,
    required this.custom,
    required this.timeUTC,
  });

  String getIDString() {
    return id.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
  }

  String getDateTimeTakenString() {
    DateTime dateTime =
        DateTime.fromMillisecondsSinceEpoch(dateTimeTaken * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  String getTemperatureString() {
    return '${temperature.toStringAsFixed(1)}°C';
  }

  String getVoltageBattery1String() {
    return '${voltageBattery1.toStringAsFixed(2)} Volt';
  }

  String getVoltageBattery2String() {
    return '${voltageBattery2.toStringAsFixed(2)} Volt';
  }

  String getMeterModelString() {
    return meterModel.trim().isEmpty ? '-' : meterModel;
  }

  String getMeterSNString() {
    return meterSN.trim().isEmpty ? '-' : meterSN;
  }

  String getMeterSealString() {
    return meterSeal.trim().isEmpty ? '-' : meterSeal;
  }

  String getCustomString() {
    return custom.trim().isEmpty ? '-' : custom;
  }
}

class ImageMetaDataParse {
  static Map<String, dynamic> parse(
    List<int> data,
  ) {
    List<int> keyA = [
      149,
      166,
      176,
      42,
      217,
      111,
      235,
      140,
      228,
      62,
      243,
      217,
      69,
      126,
      159,
      243,
      214,
      53,
      76,
      5,
      146,
      78,
      78,
      139,
      127,
      179,
      168,
      188,
      100,
      94,
      41,
      21
    ];
    List<int> ivA = [
      248,
      142,
      14,
      144,
      102,
      122,
      162,
      91,
      27,
      177,
      4,
      82,
      238,
      178,
      4,
      14
    ];
    log("#@#@ data : $data");
    try {
      List<int> temp2 = CryptoUtilsV2.aesDecrypt(
        Uint8List.fromList(data),
        Uint8List.fromList(keyA),
        Uint8List.fromList(
          ivA,
        ),
      );
      Uint8List temp = Uint8List.fromList(temp2);
      log("##long temp : ${temp.length}");
      int tempLen = temp.length;
      if (tempLen <= 4) {
        throw Exception("Invalid data");
      }

      int version = 1;
      int startIndex = data.length;
      if (temp[tempLen - 1] == MARKER) {
        version = temp[tempLen - 2];
        int metaDataLen =
            temp.buffer.asByteData().getUint16(tempLen - 4, Endian.little);

        if (tempLen < metaDataLen + 4) {
          throw Exception("Invalid data length");
        }

        if (temp[tempLen - metaDataLen] != MARKER) {
          throw Exception("Begin data marker not found");
        }
        startIndex = tempLen - metaDataLen + 1;
      }

      log("##version : $version");

      if (version == 1) {
        return {
          'img': temp,
          'metaData': null,
        };
      } else if (version == 2) {
        log("## sampai sini kahh ?");
        Uint8List metaData = temp.sublist(startIndex);
        log("## sampai sini kahh ??");
        Uint8List img = temp.sublist(0, startIndex);
        log("## sampai sini kahh ???");
        int index = 0;

        List<int> id = metaData.sublist(0, 5);
        log("## sampai sini kahh ????");
        index += 5;
        int dateTimeTaken =
            metaData.buffer.asByteData().getUint32(index, Endian.little);
        log("## sampai sini kahh ?????");
        index += 4;
        double temperature =
            metaData.buffer.asByteData().getFloat32(index, Endian.little);
        log("## sampai sini kahh ??????");
        index += 4;
        double voltageBattery1 =
            metaData.buffer.asByteData().getFloat32(index, Endian.little);
        log("## sampai sini kahh ???????");
        index += 4;
        double voltageBattery2 =
            metaData.buffer.asByteData().getFloat32(index, Endian.little);
        log("## sampai sini kahh 4");
        log("## sampai sini kahh 5");
        index += 4;
        String meterModel =
            utf8.decode(metaData.sublist(index, index + 16)).trim();
        log("## sampai sini kahh 6");
        index += 16;
        String meterSN =
            utf8.decode(metaData.sublist(index, index + 16)).trim();
        log("## sampai sini kahh 7");
        index += 16;
        String meterSeal =
            utf8.decode(metaData.sublist(index, index + 16)).trim();
        log("hasil lala1 : ${metaData.sublist(index, index + 16)}");
        index += 16;
        Uint8List lala = metaData.sublist(index, index + 32);

        log("hasil lala : $lala");

        String custom = utf8.decode(lala, allowMalformed: true).trim();
        log("## sampai sini kahh 9");
        index += 32;
        int timeUTC = metaData[index];
        log("## sampai sini kahh 10");

        ImageMetaData meta = ImageMetaData(
          id: id,
          dateTimeTaken: dateTimeTaken,
          temperature: temperature,
          voltageBattery1: voltageBattery1,
          voltageBattery2: voltageBattery2,
          meterModel: meterModel,
          meterSN: meterSN,
          meterSeal: meterSeal,
          custom: custom,
          timeUTC: timeUTC,
        );
        return {
          'img': img,
          'metaData': meta,
        };
      }
      return {
        'img': temp,
        'metaData': null,
      };
    } catch (e) {
      log("Error dapat : $e");
      return {
        'error': e,
        'img': null,
        'metaData': null,
      };
    }
  }
}
