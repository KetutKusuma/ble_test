import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/model/sub_model/test_capture_model.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/crypto.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:ble_test/utils/global.dart';

/// parameter untuk filter image explorer
class ParameterImageExplorer {
  static const int filterUndefined = 0;
  static const int filterAllFile = 1;
  static const int filterAllSent = 2;
  static const int filterAllUnsent = 3;
  static const int filterImgAll = 4;
  static const int filterImgSent = 5;
  static const int filterImgUnsent = 6;
  static const int filterNearAll = 7;
  static const int filterNearSent = 8;
  static const int filterNearUnsent = 9;
}

/// this command capture and explorer (image and log explorer)
/// and delete image file
class CommandImageFile {
  static final ivGlobal = InitConfig.data().IV;
  static final keyGlobal = InitConfig.data().KEY;
  static final messageV2 = MessageV2();

  // test capture [V]
  // data buffer transmit [V]
  // get image file list []
  // image file prepare transmit []

  Future<BLEResponse<ToppiFileModel>> testCapture(
      BLEProvider bleProvider, int bytePerChunk) async {
    try {
      int command = CommandCode.captureTest;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addUint8(bytePerChunk, buffer);
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
        if (param == null) {
          return BLEResponse.error("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params test capture : $params");

      if (params.length != 3) {
        return BLEResponse.error(
            "Error tes pengambilan gambar : parameter tidak sesuai");
      }

      int fileSize = ConvertV2().bufferToUint16(params[0], 0);
      int totalChunck = ConvertV2().bufferToUint16(params[1], 0);
      int crc32 = ConvertV2().bufferToUint32(params[2], 0);

      ToppiFileModel toppiFileModel = ToppiFileModel(
        fileSize: fileSize,
        totalChunck: totalChunck,
        crc32: crc32,
      );

      return BLEResponse.success(
        "Sukses pengambilan gambar",
        data: toppiFileModel,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat pengambilan gambar : $e");
    }
  }

  Future<BLEResponse<List<int>>> dataBufferTransmit(BLEProvider bleProvider,
      ToppiFileModel toppiFileModel, int bytePerChunk) async {
    try {
      int command = CommandCode.dataBufferTransmit;

      List<int> buffer = [];
      for (var i = 0; i < toppiFileModel.totalChunck; i++) {
        bool _success = false;
        for (var j = 0; j < 5; i++) {
          int uniqueID = UniqueIDManager().getUniqueID();

          List<int> bufferTx = [];
          messageV2.createBegin(uniqueID, MessageV2.request, command, bufferTx);
          messageV2.addUint16(i, bufferTx);

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

          int chunckCrc32 = ConvertV2().bufferToUint32(params[2], 0);
          if (CryptoUtilsV2.crc32(params[1]) != chunckCrc32) {
            throw Exception("crc32 tidak sesuai");
          }

          int startIndex = i * bytePerChunk;
          int endIndex = (i + 1) * bytePerChunk;
          // buffer.setRange(startIndex, endIndex, params[1]);
          buffer.addAll(params[1]);
          _success = true;
          break;
        }
        if (!_success) {
          return BLEResponse.error("tidak sukses kirim data buffer");
        }
      }
      if (CryptoUtilsV2.crc32(buffer) != toppiFileModel.crc32) {
        throw Exception("crc32 diterima tidak sesuai");
      }
      return BLEResponse.success("Sukses kirim data buffer", data: buffer);
    } catch (e) {
      return BLEResponse.error("Error dapat kirim data buffer : $e");
    }
  }

  Future<BLEResponse> imageFileDelete(
      BLEProvider bleProvider, int flagDir, List<int> fileName) async {
    try {
      int command = CommandCode.imageFileDelete;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> bufferTx = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, bufferTx);
      messageV2.addUint8(flagDir, bufferTx);
      messageV2.addArrayOfUint8(fileName, bufferTx);

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
      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses hapus berkas gambar");
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat hapus berkas gambar");
    }
  }

  Future<BLEResponse<ToppiExplorerModel>> getImageFileExplorer(
    BLEProvider bleProvider,
    int filter,
    int bytePerChunk,
  ) async {
    try {
      int command = CommandCode.imageExplorer;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addUint8(filter, buffer);
      messageV2.addUint8(bytePerChunk, buffer);

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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }
      if (params.length != 4) {
        throw Exception("Gagal buffer transmit : parameter tidak sesuai");
      }

      ToppiExplorerModel imageExplorer = ToppiExplorerModel(
        totalFile: ConvertV2().bufferToUint16(params[0], 0),
        fileSize: ConvertV2().bufferToUint16(params[1], 0),
        totalChunck: ConvertV2().bufferToUint16(params[2], 0),
        crc32: ConvertV2().bufferToUint32(params[3], 0),
      );
      return BLEResponse.success(
        "Sukses dapat daftar berkas gambar",
        data: imageExplorer,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat daftar berkas gambar");
    }
  }

  Future<BLEResponse<ToppiFileModel>> imageFilePrepareTransmit(
      BLEProvider bleProvider,
      int flagDir,
      List<int> fileName,
      int bytePerChunk) async {
    try {
      int command = CommandCode.imageFilePrepareTransmit;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addUint8(flagDir, buffer);
      messageV2.addArrayOfUint8(fileName, buffer);
      messageV2.addUint8(bytePerChunk, buffer);

      List<int> idata = messageV2.createEnd(
        sessionID,
        buffer,
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
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params image file prepare transmit : $params");

      if (params.length != 3) {
        throw Exception(
            "Gagal persiapan mengirim berkas gambar : parameter tidak sesuai");
      }

      ToppiFileModel img = ToppiFileModel(
        fileSize: ConvertV2().bufferToUint16(params[0], 0),
        totalChunck: ConvertV2().bufferToUint16(params[1], 0),
        crc32: ConvertV2().bufferToUint32(params[2], 0),
      );

      return BLEResponse.success(
        "Sukses persiapan mengirim berkas gambar",
        data: img,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat persiapan mengirim berkas gambar");
    }
  }

  Future<BLEResponse<ToppiExplorerModel>> getLogExplorer(
      BLEProvider bleProvider, int bytePerChunk) async {
    try {
      int command = CommandCode.logExplorer;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addUint8(bytePerChunk, buffer);

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

      Response responseWrite = await bleProvider.writeData(
        data,
        headerBLE,
      );

      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params log explorer : $params");

      if (params.length != 4) {
        throw Exception("Gagal ambil daftar catatan : parameter tidak sesuai");
      }

      ToppiExplorerModel logExplorer = ToppiExplorerModel(
        totalFile: ConvertV2().bufferToUint16(params[0], 0),
        fileSize: ConvertV2().bufferToUint16(params[1], 0),
        totalChunck: ConvertV2().bufferToUint16(params[2], 0),
        crc32: ConvertV2().bufferToUint32(params[3], 0),
      );

      return BLEResponse.success("Sukses ambil daftar catatan",
          data: logExplorer);
    } catch (e) {
      return BLEResponse.error("Error dapat ambil daftar catatan ; $e");
    }
  }

  Future<BLEResponse<ToppiFileModel>> logFilePrepareTransmit(
      BLEProvider bleProvider, List<int> fileName, int bytePerChunk) async {
    try {
      int command = CommandCode.logFilePrepareTransmit;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8(fileName, buffer);
      messageV2.addUint8(bytePerChunk, buffer);

      List<int> idata = messageV2.createEnd(
        sessionID,
        buffer,
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
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params log file prepare transmit : $params");

      if (params.length != 3) {
        throw Exception(
            "Gagal persiapan mengirim berkas catatan : parameter tidak sesuai");
      }

      ToppiFileModel img = ToppiFileModel(
        fileSize: ConvertV2().bufferToUint16(params[0], 0),
        totalChunck: ConvertV2().bufferToUint16(params[1], 0),
        crc32: ConvertV2().bufferToUint32(params[2], 0),
      );

      return BLEResponse.success(
        "Sukses persiapan mengirim berkas catatan",
        data: img,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat persiapan mengirim berkas catatan");
    }
  }
}
