import 'dart:developer';

import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';

import 'ble.dart';

class CommandCode {
  static const int handshake = 11;
  static const int login = 12;
  static const int changePassword = 13;
  static const int formatFat = 14;
  static const int dataBufferTransmit = 15;
  static const int testCapture = 16;
  static const int imageExplorerPrepareTransmit = 17;
  static const int logFilePrepareTransmit = 18;
  static const int get = 99;
  static const int firmware = 101;
  static const int identity = 102;
  static const int role = 103;
  static const int enable = 104;
  static const int printToSerialMonitor = 105;
  static const int dateTime = 106;
  static const int temperature = 107;
  static const int batteryVoltage = 108;
  static const int batteryVoltageCoefficient = 109;
  static const int storage = 110;
  static const int imageExplorer = 111;
  static const int log = 112;
  static const int cameraSetting = 113;
  static const int captureSchedule = 114;
  static const int transmitSchedule = 115;
  static const int receiveSchedule = 116;
  static const int uploadSchedule = 117;
  static const int gateway = 118;
  static const int metaData = 119;
  static const int other = 120;
}

class ParameterImageExplorerFilter {
  static const int undefined = 0;
  static const int allFile = 1;
  static const int allSent = 2;
  static const int allUnsent = 3;
  static const int imgAll = 4;
  static const int imgSent = 5;
  static const int imgUnsent = 6;
  static const int nearAll = 7;
  static const int nearSent = 8;
  static const int nearUnsent = 9;
}

class BLEResponse {
  final List<int>? data;
  final bool status;
  final String message;

  BLEResponse({required this.status, required this.message, this.data});

  factory BLEResponse.error(String message, {List<int>? data}) {
    return BLEResponse(status: false, message: message, data: data);
  }

  factory BLEResponse.success(String message, {List<int>? data}) {
    return BLEResponse(status: true, message: message, data: data);
  }
}

class Command {
  Future<BLEResponse> handshake(
      BluetoothDevice device, BLEProvider bleProvider) async {
    try {
      // create message
      int command = CommandCode.handshake;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      MessageV2().createBegin(uniqueID, MessageV2.request, command, buffer);
      log("buffer create : $buffer");
      List<int> idata = MessageV2().createEnd(
        0,
        buffer,
        InitConfig.data().KEY,
        InitConfig.data().IV,
      );
      log("data end : $idata");
      log("data hasil : $idata");

      // init for request response struct
      // ini harusnya ada buat response struktur kyk apa
      Header headerBLE =
          Header(uniqueID: uniqueID, command: command, status: false);
      // send massage
      Response responseWrite = await bleProvider.writeData(
        idata,
        headerBLE,
      );
      log("response write : ${responseWrite}");
      // device.disconnect();

      return BLEResponse.error("test");

      // listen to response
      // await bleProvider.listenToNotifications

      log("buffer akhir : $buffer");
    } catch (e) {
      return BLEResponse.error("Error handshake : $e");
    }
  }
}
