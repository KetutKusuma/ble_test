import 'dart:developer';

import 'package:ble_test/utils/converter/bytes_convert.dart';

class UploadSettingsConverter {
  static List<dynamic> convertUploadSettings(List<int> bytes) {
    if (bytes.isEmpty || bytes.length < 2) {
      throw Exception("Invalid bytes convert");
    }

    bool statusBool = bytes[0] == 1;
    String upload = BytesConvert.bytesToString(bytes.sublist(1, 49));
    int port = BytesConvert.bytesToInt16(bytes.sublist(49, 51));
    bool uploadEnableBool = bytes[51] == 1;
    int uploadScheduleInt = BytesConvert.bytesToInt16(bytes.sublist(52, 62));
    int uploadUsingInt = BytesConvert.bytesToInt8([bytes[62]]);
    int uploadInitialDelay = BytesConvert.bytesToInt16(bytes.sublist(63, 65));
    String wifiSsid = BytesConvert.bytesToString(bytes.sublist(65, 81));
    String wifiPassword = BytesConvert.bytesToString(bytes.sublist(81, 97));
    String modemApn = BytesConvert.bytesToString(bytes.sublist(97, 113));

    log("upload : $upload");
    log("port : $port");
    log("upload enable : $uploadEnableBool");
    log("upload schedule : $uploadScheduleInt");
    log("upload using : $uploadUsingInt");
    log("upload initial delay : $uploadInitialDelay");
    log("wifi ssid : $wifiSsid");
    log("wifi password : $wifiPassword");
    log("modem apn : $modemApn");

    return [
      statusBool,
      upload,
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
}
