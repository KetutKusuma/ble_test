import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class UploadSettingsConverter {
  static List<dynamic> convertUploadSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 2) {
      throw Exception("Invalid bytes convert");
    }

    bool statusBool = bytes[0] == 1;
    String server = BytesConvert.bytesToString(bytes.sublist(1, 49));
    int port = BytesConvert.bytesToInt16(bytes.sublist(49, 51));
    // =======
    List<bool> uploadEnable = convertUploadEnable(
      bytes[51],
    ).map((value) => value == 1).toList();
    List<int> uploadSchedule = convertUploadSchedule(bytes.sublist(52, 68));
    // =======
    int uploadUsingInt = BytesConvert.bytesToInt8([bytes[68]]);
    int uploadInitialDelay = BytesConvert.bytesToInt16(
      bytes.sublist(69, 71),
      isBigEndian: false,
    );
    String wifiSsid = BytesConvert.bytesToString(bytes.sublist(71, 87));
    String wifiPassword = BytesConvert.bytesToString(bytes.sublist(87, 103));
    String modemApn = BytesConvert.bytesToString(bytes.sublist(103, 119));

    log("server : '$server'");
    log("port : $port");
    log("upload enable : $uploadEnable");
    log("upload schedule : $uploadSchedule");
    log("upload using : $uploadUsingInt");
    log("upload initial delay : $uploadInitialDelay");
    log("wifi ssid : $wifiSsid");
    log("wifi password : $wifiPassword");
    log("modem apn : $modemApn");

    if (bytes.sublist(1, 49).every((element) => element == 0)) {
      server = '-';
    }

    if (bytes.sublist(71, 87).every((element) => element == 0)) {
      wifiSsid = '-';
    }

    if (bytes.sublist(87, 103).every((element) => element == 0)) {
      wifiPassword = '-';
    }

    if (bytes.sublist(103, 119).every((element) => element == 0)) {
      modemApn = '-';
    }

    return [
      statusBool,
      server,
      port,
      uploadEnable,
      uploadSchedule,
      uploadUsingInt,
      uploadInitialDelay,
      wifiSsid,
      wifiPassword,
      modemApn,
    ];
  }

  static List<int> convertUploadEnable(int value) {
    // Convert to binary string
    String binaryString = value.toRadixString(2);

    // Pad to 8 bits (if necessary)
    binaryString = binaryString.padLeft(8, '0');

    // Convert to a list of integers
    List<int> binaryArray = binaryString.split('').map(int.parse).toList();

    List<int> resultReverse = binaryArray.reversed.toList();

    /// get the 5 first
    List<int> result = resultReverse.sublist(0, 8);

    return result;
  }

  static List<int> convertUploadSchedule(List<int> bytes) {
    List<int> listResultInt = [];
    for (int i = 0; i < bytes.length; i += 2) {
      List<int> chunk = bytes.sublist(i, i + 2);
      int rees = BytesConvert.bytesToInt16(chunk, isBigEndian: false);
      listResultInt.add(rees);
    }
    return listResultInt;
  }
}
