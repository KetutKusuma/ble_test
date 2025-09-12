import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';
import 'package:ble_test/ble-v2/model/sub_model/battery_coefficient_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/camera_model.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:ble_test/utils/global.dart';

class CommandEachGet {
  static MessageV2 messageV2 = MessageV2();
  static final ivGlobal = InitConfig.data().IV;
  static final keyGlobal = InitConfig.data().KEY;

  Future<BLEResponse<int>> getRole(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.role], buffer);

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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 1;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses dapat role", data: params[0][0]);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get role : $e");
    }
  }

  Future<BLEResponse<bool>> getEnable(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.enable;
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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 1;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat enable",
          data: params[0][0] == 1 ? true : false,
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get enable : $e");
    }
  }

  Future<BLEResponse<bool>> getEnableModem(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.enableModem;
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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 1;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat enable",
          data: params[0][0] == 1 ? true : false,
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get enable : $e");
    }
  }

  Future<BLEResponse<int>> getAvailableMemory(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.availableMemory;
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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 1;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat available memory",
          data: params[0][0],
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get available memory : $e");
    }
  }

  Future<BLEResponse<bool>> getPrintToSerial(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.printToSerialMonitor], buffer);

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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 1;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat print to serial",
          data: params[0][0] == 1 ? true : false,
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get print to serial : $e");
    }
  }

  Future<BLEResponse<DateTime>> getDateTime(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.dateTime;
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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 1;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      int dateTimeMiliSeconds =
          ConvertV2().bufferToUint32(params[0], 0) + (946684800);
      // log("datetime before : ${}")
      DateTime dateTimeFromBle = DateTime.fromMillisecondsSinceEpoch(
        dateTimeMiliSeconds * 1000,
      ).toUtc();

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat date time",
          data: dateTimeFromBle,
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get date time : $e");
    }
  }

  Future<BLEResponse<int>> getTimeUTC(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.timeUTC;
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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 1;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat time UTC",
          data: ConvertV2().bufferToUint32(params[0], 0),
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get time UTC : $e");
    }
  }

  Future<BLEResponse<DateTimeWithUTCModelModelYaml>> getDateTimeWithUTC(
    BLEProvider bleProvider,
  ) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([
        CommandCode.dateTime,
        CommandCode.timeUTC,
      ], buffer);

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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 2;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      int dateTimeMiliSeconds =
          ConvertV2().bufferToUint32(params[0], 0) + (946684800);
      // log("datetime before : ${}")
      DateTime dateTimeFromBle = DateTime.fromMillisecondsSinceEpoch(
        dateTimeMiliSeconds * 1000,
      ).toUtc();

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat date time",
          data: DateTimeWithUTCModelModelYaml(
            dateTime: dateTimeFromBle,
            utc: ConvertV2().bufferToUint32(params[1], 0),
          ),
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get date time : $e");
    }
  }

  Future<BLEResponse<BatteryCoefficientModel>> getBatteryVoltageCoefficient(
    BLEProvider bleProvider,
  ) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([
        CommandCode.batteryVoltageCoefficient,
      ], buffer);

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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 2;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        int starIndex = 0;
        return BLEResponse.success(
          "Sukses dapat battery voltage coefficient",
          data: BatteryCoefficientModel(
            coefficient1: ConvertV2().bufferToFloat32(params[starIndex], 0),
            coefficient2: ConvertV2().bufferToFloat32(params[starIndex + 1], 0),
          ),
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error(
        "Error dapat get battery voltage coefficient : $e",
      );
    }
  }

  Future<BLEResponse<CameraModel>> getCameraSetting(
    BLEProvider bleProvider,
  ) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.cameraSetting], buffer);

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

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = messageV2.getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      int expectedParameterCount = 8;
      if (params.length != expectedParameterCount) {
        throw Exception("Jumlah parameter tidak sesuai");
      }

      if (responseWrite.header.status) {
        int startIndex = 0;
        return BLEResponse.success(
          "Sukses dapat camera setting",
          data: CameraModel(
            brightness: ConvertV2().bufferToUint8(params[startIndex], 0),
            contrast: ConvertV2().bufferToUint8(params[startIndex + 1], 0),
            saturation: ConvertV2().bufferToUint8(params[startIndex + 2], 0),
            specialEffect: ConvertV2().bufferToUint8(params[startIndex + 3], 0),
            hMirror: ConvertV2().bufferToBool(params[startIndex + 4], 0),
            vFlip: ConvertV2().bufferToBool(params[startIndex + 5], 0),
            jpegQuality: ConvertV2().bufferToUint8(params[startIndex + 6], 0),
            adjustImageRotation: ConvertV2().bufferToUint16(
              params[startIndex + 7],
              0,
            ),
          ),
        );
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat get camera setting : $e");
    }
  }
}
