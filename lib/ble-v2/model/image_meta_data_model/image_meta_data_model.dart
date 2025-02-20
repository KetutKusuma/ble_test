import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/crypto.dart';
import 'package:intl/intl.dart';

const int MARKER = 255;

class ImageMetaDataModel {
  String? firmware;
  String? version;
  List<int>? id;
  int? dateTimeTaken;
  int? timeUTC;
  double? temperature;
  double? voltageBattery1;
  double? voltageBattery2;
  int? adjustmentRotation;
  String? meterModel;
  String? meterSN;
  String? meterSeal;
  String? custom;

  ImageMetaDataModel({
    this.firmware,
    this.version,
    this.id,
    this.dateTimeTaken,
    this.temperature,
    this.voltageBattery1,
    this.voltageBattery2,
    this.adjustmentRotation,
    this.meterModel,
    this.meterSN,
    this.meterSeal,
    this.custom,
    this.timeUTC,
  });

  String getIDString() {
    if (id == null) return '';
    return id!.map((e) => e.toRadixString(16).padLeft(2, '0')).join(':');
  }

  String getDateTimeTakenString() {
    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(
        (dateTimeTaken! + 946659600) * 1000);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime);
  }

  String getTemperatureString() {
    if (temperature == null) return '-';
    return '${temperature!.toStringAsFixed(1)}°C';
  }

  String getVoltageBattery1String() {
    if (voltageBattery1 == null) return '-';
    return '${voltageBattery1!.toStringAsFixed(2)} Volt';
  }

  String getVoltageBattery2String() {
    if (voltageBattery2 == null) return '-';
    return '${voltageBattery2!.toStringAsFixed(2)} Volt';
  }

  String getMeterModelString() {
    if (meterModel == null) return '-';
    return meterModel!.trim().isEmpty ? '-' : meterModel!;
  }

  String getMeterSNString() {
    if (meterSN == null) return '-';
    return meterSN!.trim().isEmpty ? '-' : meterSN!;
  }

  String getMeterSealString() {
    if (meterSeal == null) return '-';
    return meterSeal!.trim().isEmpty ? '-' : meterSeal!;
  }

  String getCustomString() {
    if (custom == null) return '-';
    return custom!.trim().isEmpty ? '-' : custom!;
  }
}

class ImageMetaDataModelParse {
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
        // [0:1]   marker begin
        // [1:5]   id
        // [6:4]   date time taken
        // [10:4]  temperature
        // [14:4]  voltage battery1
        // [18:4]  voltage battery2
        // [22:16] INDEX_METER_MODEL
        // [38:16] INDEX_METER_SN
        // [54:16] INDEX_METER_SEAL
        // [70:32] INDEX_CUSTOM
        // [102:1] INDEX_TIME_UTC
        // [103:2] start index of meta data
        // [105:1] meta data version
        // [106:1] marker end
        Uint8List metaData = temp.sublist(startIndex);
        Uint8List img = temp.sublist(0, startIndex);
        int index = 0;

        List<int> id = metaData.sublist(0, 5);
        index += 5;
        int dateTimeTaken =
            metaData.buffer.asByteData().getUint32(index, Endian.little);
        index += 4;
        double temperature =
            metaData.buffer.asByteData().getFloat32(index, Endian.little);
        index += 4;
        double voltageBattery1 =
            metaData.buffer.asByteData().getFloat32(index, Endian.little);
        index += 4;
        double voltageBattery2 =
            metaData.buffer.asByteData().getFloat32(index, Endian.little);
        index += 4;
        String meterModel =
            utf8.decode(metaData.sublist(index, index + 16)).trim();
        index += 16;
        String meterSN =
            utf8.decode(metaData.sublist(index, index + 16)).trim();
        index += 16;
        String meterSeal =
            utf8.decode(metaData.sublist(index, index + 16)).trim();
        index += 16;
        Uint8List lala = metaData.sublist(index, index + 32);

        String custom = utf8.decode(lala, allowMalformed: true).trim();
        index += 32;
        int timeUTC = metaData[index];

        ImageMetaDataModel meta = ImageMetaDataModel(
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
      } else if (version == 3) {
        // tambahkan meta data:
        // [0:1]   marker begin
        // [1:16]  firmware
        // [17:8]  version
        // [25:5]  id
        // [30:4]  date time
        // [34:1]  time utc
        // [35:4]  temperature
        // [39:4]  voltage battery1
        // [42:4]  voltage battery2
        // [46:2]  adjust image rotation
        // [48:16] INDEX_METER_MODEL
        // [64:16] INDEX_METER_SN
        // [80:16] INDEX_METER_SEAL
        // [96:32] INDEX_CUSTOM
        // [128:2] start index of meta data
        // [130:1] meta data version
        // [131:1] marker end
        Uint8List metaData = temp.sublist(startIndex);
        Uint8List img = temp.sublist(0, startIndex);
        int index = 0;

        String firmware =
            ConvertV2().bufferToStringUsingIndex(metaData, index, 16);
        index += 16;
        String version =
            ConvertV2().bufferToStringUsingIndex(metaData, index, 8);
        index += 8;
        List<int> id = metaData.sublist(index, index + 5);
        index += 5;
        int dateTime = ConvertV2().bufferToUint32(metaData, index);
        index += 4;
        int timeUTC = ConvertV2().bufferToUint8(metaData, index);
        index += 1;
        double temperature = ConvertV2().bufferToFloat32(metaData, index);
        index += 4;
        double voltageBattery1 = ConvertV2().bufferToFloat32(metaData, index);
        index += 4;
        double voltageBattery2 = ConvertV2().bufferToFloat32(metaData, index);
        index += 4;
        int adjustmentRotation = ConvertV2().bufferToUint16(metaData, index);
        index += 2;
        String meterModel = ConvertV2().bufferToStringUTF8(metaData, index, 16);
        index += 16;
        String meterSN = ConvertV2().bufferToStringUTF8(metaData, index, 16);
        index += 16;
        String meterSeal = ConvertV2().bufferToStringUTF8(metaData, index, 16);
        index += 16;
        String custom = ConvertV2().bufferToStringUTF8(metaData, index, 32);
        index += 32;

        ImageMetaDataModel meta = ImageMetaDataModel(
          firmware: firmware,
          version: version,
          id: id,
          dateTimeTaken: dateTime,
          timeUTC: timeUTC,
          temperature: temperature,
          voltageBattery1: voltageBattery1,
          voltageBattery2: voltageBattery2,
          adjustmentRotation: adjustmentRotation,
          meterModel: meterModel,
          meterSN: meterSN,
          meterSeal: meterSeal,
          custom: custom,
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
