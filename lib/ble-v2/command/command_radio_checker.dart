import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:ble_test/utils/global.dart';

class CommandRadioChecker {
  static final ivGlobal = InitConfig.data().IV;
  static final keyGlobal = InitConfig.data().KEY;
  static final messageV2 = MessageV2();

  Future<BLEResponse> radioTestAsReceiverStart(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.radioTestAsReceiverStart;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE = Header(
        uniqueID: uniqueID,
        command: command,
        status: false,
      );

      Response responseWrite = await bleProvider.writeData(data, headerBLE);
      log("response write radio test as receiver start : $responseWrite");

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses test as receiver start", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat test as receiver : $e");
    }
  }

  Future<BLEResponse> radioTestAsReceiverStop(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.radioTestAsReceiverStop;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE = Header(
        uniqueID: uniqueID,
        command: command,
        status: false,
      );

      Response responseWrite = await bleProvider.writeData(data, headerBLE);

      log("response write radio test as receiver stop : $responseWrite");

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses test as receiver stop", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat test as receiver : $e");
    }
  }

  Future<BLEResponse> radioTestAsTransmitterStart(
    BLEProvider bleProvider,
    List<int> destinationID,
  ) async {
    try {
      int command = CommandCode.radioTestAsTransmitterStart;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8(destinationID, buffer);

      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE = Header(
        uniqueID: uniqueID,
        command: command,
        status: false,
      );

      Response responseWrite = await bleProvider.writeData(data, headerBLE);

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses test as transmitter start",
          data: null,
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat test as transmitter start : $e");
    }
  }

  Future<BLEResponse> radioTestAsTransmitterSequence(
    BLEProvider bleProvider,
    int sequence,
  ) async {
    try {
      int command = CommandCode.radioTestAsTransmitterSequence;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addUint32(sequence, buffer);
      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE = Header(
        uniqueID: uniqueID,
        command: command,
        status: false,
      );

      Response responseWrite = await bleProvider.writeData(data, headerBLE);

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses test as transmitter sequence",
          data: null,
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat test as transmitter sequence : $e");
    }
  }

  Future<BLEResponse> radioTestAsTransmitterStop(
    BLEProvider bleProvider,
  ) async {
    try {
      int command = CommandCode.radioTestAsTransmitterStop;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE = Header(
        uniqueID: uniqueID,
        command: command,
        status: false,
      );

      Response responseWrite = await bleProvider.writeData(data, headerBLE);

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses test as transmitter stop",
          data: null,
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat test as transmitter stop : $e");
    }
  }
}
