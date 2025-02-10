import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/model/sub_model/test_capture_model.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/crypto.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:ble_test/utils/global.dart';

class CommandCapture {
  static final ivGlobal = InitConfig.data().IV;
  static final keyGlobal = InitConfig.data().KEY;
  static final messageV2 = MessageV2();

  // test capture [V]
  // data buffer transmit []
  // get image file list []
  // image file prepare transmit []

  Future<BLEResponse<TestCaptureModel>> testCapture(
      BLEProvider bleProvider, int bytePerChunck) async {
    try {
      int command = CommandCode.testCapture;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addUint8(bytePerChunck, buffer);
      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE =
          Header(uniqueID: uniqueID, command: command, status: false);

      Response responseWrite = await bleProvider.writeData(
        data,
        headerBLE,
      );

      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      log("response write test capture : $responseWrite");

      List<List<int>> params = [];
      for (var i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param != null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
      }

      if (params.length != 3) {
        return BLEResponse.error(
            "Error tes pengambilan gambar : parameter tidak sesuai");
      }

      int fileSize = ConvertV2().bufferToUint16(params[0], 0);
      int totalChunck = ConvertV2().bufferToUint16(params[1], 0);
      int crc32 = ConvertV2().bufferToUint32(params[2], 0);

      TestCaptureModel testCaptureModel = TestCaptureModel(
        fileSize: fileSize,
        totalChunck: totalChunck,
        crc32: crc32,
      );

      return BLEResponse.success("Sukses tes pengambilan gambar",
          data: testCaptureModel);
    } catch (e) {
      return BLEResponse.error("Error dapat tes pengambilan gambar");
    }
  }

  Future<BLEResponse> dataBufferTransmit(BLEProvider bleProvider,
      TestCaptureModel testCapture, int bytePerChunck) async {
    try {
      int command = CommandCode.dataBufferTransmit;

      List<int> buffer = [];
      for (var i = 0; i < testCapture.totalChunck; i++) {
        bool _success = false;
        for (var j = 0; j < 5; i++) {
          int uniqueID = UniqueIDManager().getUniqueID();

          List<int> bufferTx = [];
          messageV2.createBegin(uniqueID, MessageV2.request, command, bufferTx);
          messageV2.addUint16(i, buffer);

          List<int> idata = messageV2.createEnd(
            sessionID,
            bufferTx,
            keyGlobal,
            ivGlobal,
          );

          Header headerBLE =
              Header(uniqueID: uniqueID, command: command, status: false);

          Response responseWrite = await bleProvider.writeData(
            idata,
            headerBLE,
          );

          if (!responseWrite.header.status) {
            return BLEResponse.errorFromBLE(responseWrite);
          }

          List<List<int>> params = [];
          for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
            List<int>? param =
                MessageV2().getParameter(responseWrite.buffer, i);
            if (param == null) {
              throw Exception("Gagal untuk mengembalikan parameter");
            }
            params.add(param);
          }

          if (params.length != 3) {
            throw Exception("Gagal buffer transmit : parameter tidak sesuai");
          }

          if (i != ConvertV2().bufferToUint16(params[0], 0)) {
            throw Exception("melebihi batas nomor chunk sequence");
          }

          int chunckCrc32 = ConvertV2().bufferToUint32(buffer, 0);
          if (CryptoUtilsV2.crc32(params[1]) != chunckCrc32) {
            throw Exception("crc32 tidak sesuai");
          }

          int startIndex = i * bytePerChunck;
          int endIndex = (i + 1) * bytePerChunck;
          params[1].addAll(buffer.sublist(startIndex, endIndex));
          _success = true;
          break;
        }
        if (!_success) {
          return BLEResponse.error("tidak sukses kirim data buffer");
        }
      }
      if (CryptoUtilsV2.crc32(buffer) != testCapture.crc32) {
        throw Exception("crc32 diterima tidak sesuai");
      }
      return BLEResponse.success("Sukses kirim data buffer", data: buffer);
    } catch (e) {
      return BLEResponse.error("Error dapat kirim data buffer : $e");
    }
  }
}
