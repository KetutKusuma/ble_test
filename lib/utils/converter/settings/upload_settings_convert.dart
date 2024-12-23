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
    bool uploadEnableBool = bytes[51] == 1;
    int uploadScheduleInt = BytesConvert.bytesToInt16(bytes.sublist(52, 62));
    int uploadUsingInt = BytesConvert.bytesToInt8([bytes[62]]);
    int uploadInitialDelay = BytesConvert.bytesToInt16(bytes.sublist(63, 65));
    String wifiSsid = BytesConvert.bytesToString(bytes.sublist(65, 81));
    String wifiPassword = BytesConvert.bytesToString(bytes.sublist(81, 97));
    String modemApn = BytesConvert.bytesToString(bytes.sublist(97, 113));

    log("server : '$server'");
    log("port : $port");
    log("upload enable : $uploadEnableBool");
    log("upload schedule : $uploadScheduleInt");
    log("upload using : $uploadUsingInt");
    log("upload initial delay : $uploadInitialDelay");
    log("wifi ssid : $wifiSsid");
    log("wifi password : $wifiPassword");
    log("modem apn : $modemApn");

    if (bytes.sublist(1, 49).every((element) => element == 0)) {
      server = '-';
    }

    if (bytes.sublist(65, 81).every((element) => element == 0)) {
      wifiSsid = '-';
    }

    if (bytes.sublist(81, 97).every((element) => element == 0)) {
      wifiPassword = '-';
    }

    if (bytes.sublist(97, 113).every((element) => element == 0)) {
      modemApn = '-';
    }

    return [
      statusBool,
      server,
      port,
      uploadEnableBool,
      uploadScheduleInt,
      uploadUsingInt,
      uploadInitialDelay,
      wifiSsid,
      wifiPassword,
      modemApn
    ];
  }

  static String checkString(String ss) {
    String result = '' * 48;
    log("${ss.length == result}");
    if (ss.length == result) {}

    return ss;
  }
}
