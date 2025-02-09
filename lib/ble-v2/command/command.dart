import 'dart:convert';
import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/model/admin_model.dart';
import 'package:ble_test/ble-v2/model/device_status_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/battery_coefficient_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/battery_voltage_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/camera_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/capture_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/firmware_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/gateway_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/identity_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/image_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/meta_data_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/receive_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/storage_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/transmit_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/upload_model.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/crypto.dart';
import 'package:ble_test/ble-v2/utils/crypto_tut.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/global.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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

class BLEResponse<T> {
  final T? data;
  final bool status;
  final String message;

  BLEResponse({required this.status, required this.message, this.data});

  factory BLEResponse.error(String message, {T? data}) {
    return BLEResponse(status: false, message: message, data: data);
  }

  factory BLEResponse.success(String message, {T? data}) {
    return BLEResponse(status: true, message: message, data: data);
  }

  factory BLEResponse.errorFromBLE(Response response) {
    List<List<int>> params = [];
    for (int i = 0; i < (response.header.parameterCount ?? 0); i++) {
      List<int>? param = MessageV2().getParameter(response.buffer, i);
      if (param == null) {
        log("Gagal mengambil parameter - error dari BLE");
        return BLEResponse.error("Gagal mengambil parameter - error dari BLE");
      }
      params.add(param);
    }
    int errorCode = ConvertV2().bufferToUint8(params[0], 0);
    String errorMsg = ConvertV2().bufferToString(params[1]);
    log("Error dari BLE code : $errorCode message : $errorMsg");
    return BLEResponse.error(
      "Error dari BLE code : $errorCode message : $errorMsg",
    );
  }

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
status : $status \nmessage : $message \ndata : $data
        }''';
  }
}

class Command {
  static MessageV2 messageV2 = MessageV2();
  static final ivGlobal = InitConfig.data().IV;
  static final keyGlobal = InitConfig.data().KEY;

  Future<BLEResponse<List<int>>> handshake(
      BluetoothDevice device, BLEProvider bleProvider) async {
    try {
      // create message
      int command = CommandCode.handshake;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      MessageV2().createBegin(uniqueID, MessageV2.request, command, buffer);
      List<int> idata = MessageV2().createEnd(
        0,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      // init for request response struct
      // ini harusnya ada buat response struktur kyk apa
      Header headerBLE =
          Header(uniqueID: uniqueID, command: command, status: false);
      // send massage
      Response responseWrite = await bleProvider.writeData(
        idata,
        headerBLE,
      );
      List<int>? challange = messageV2.getParameter(responseWrite.buffer, 0);
      if (challange == null) {
        return BLEResponse.error("Error handshake challange : $challange");
      }

      return BLEResponse.success("Sukses handshake", data: challange);
    } catch (e) {
      return BLEResponse.error("Error handshake : $e");
    }
  }

  Future<BLEResponse> login(BluetoothDevice device, BLEProvider bleProvider,
      String username, String password, List<int> challange) async {
    try {
      int command = CommandCode.login;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];

      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addString(username, buffer);

      List<int> forIV = challange + InitConfig.data().SALT1;
      List<int> forKey1 = challange + InitConfig.data().SALT2;
      List<int> forKey2 = challange + InitConfig.data().SALT3;

      List<int> iv = CryptoUtilsV2.md5Hash(forIV);

      List<int> key =
          CryptoUtilsV2.md5Hash(forKey1) + CryptoUtilsV2.md5Hash(forKey2);
      // String resultAES256 = await AESService.encrypt(password, key, iv);
      List<int> resultAES256 = AESUtil.aesEncrypt(
        Uint8List.fromList(utf8.encode(password)),
        Uint8List.fromList(key),
        Uint8List.fromList(iv),
      );

      bool resultaddArray = messageV2.addArrayOfUint8(resultAES256, buffer);
      if (!resultaddArray) {
        return BLEResponse.error("Error when add array uint8");
      }

      List<int> idata = MessageV2().createEnd(
        0,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      // create struktur header for matching
      Header headerBLE =
          Header(uniqueID: uniqueID, command: command, status: false);

      // response write
      Response responseWrite = await bleProvider.writeData(
        idata,
        headerBLE,
      );

      if (responseWrite.header.status == false) {
        List<List<int>> params = [];
        for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
          List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
          if (param == null) {
            throw Exception("Fail to retrieve parameter error");
          }
          params.add(param);
        }

        String errorMsg = ConvertV2().bufferToString(params[1]);
        log("Error msg login : $errorMsg");
        return BLEResponse.error("Error write data : $errorMsg");
      }

      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Fail to retrieve parameter");
        }
        params.add(param);
      }
      log("params : $params");

      if (params.length != 2) {
        throw Exception("Retrieve parameter expected 2 parameters");
      }

      int logisAs = ConvertV2().bufferToUint8(params[0], 0);
      int sessionIDNow = ConvertV2().bufferToUint8(params[1], 0);
      log("logisAs : $logisAs");
      log("sessionID : $sessionIDNow");

      _setRoleLoginAs(1);
      sessionID = sessionIDNow;

      return BLEResponse.success("Sukses login", data: null);
    } catch (e) {
      return BLEResponse.error("Error login : $e");
    }
  }

  _setRoleLoginAs(int role) {
    if (role == LoginAs.admin) {
      roleUser = Role.ADMIN;
    } else if (role == LoginAs.operator) {
      roleUser = Role.OPERATOR;
    } else if (role == LoginAs.guest) {
      roleUser = Role.GUEST;
    } else if (role == LoginAs.none) {
      roleUser = Role.NONE;
    } else if (role == LoginAs.forgetPassword) {
      roleUser = Role.FORGETPASSWORD;
    }
  }

  Future<BLEResponse> formatFAT(
      BluetoothDevice device, BLEProvider bleProvider) async {
    try {
      // create message
      int command = CommandCode.formatFat;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      MessageV2().createBegin(uniqueID, MessageV2.request, command, buffer);
      List<int> idata = MessageV2().createEnd(
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
        idata,
        headerBLE,
      );
      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses format FAT", data: null);
      } else {
        return BLEResponse.error("Gagal format FAT");
      }
    } catch (e) {
      return BLEResponse.error("Error format FAT : $e");
    }
  }

  // Future<BLEResponse> reset

  Future<BLEResponse<AdminModels>> getAdminData(
      BluetoothDevice device, BLEProvider bleProvider) async {
    try {
      AdminModels adminModels = AdminModels();
      // create message
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      MessageV2().createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([
        CommandCode.identity,
        CommandCode.batteryVoltageCoefficient,
        CommandCode.cameraSetting,
        CommandCode.role,
        CommandCode.enable,
        CommandCode.printToSerialMonitor
      ], buffer);
      List<int> idata = MessageV2().createEnd(
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
        idata,
        headerBLE,
      );
      log("response write get admin data : ${responseWrite}");

      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Fail to retrieve parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;
      // identity
      List<int> hardwareID = params[startIndex];
      List<int> toppiID = params[startIndex + 1];
      bool isLicensed = ConvertV2().bufferToBool(params[startIndex + 2], 0);

      startIndex = 3;
      // battery voltage coefficient
      double batteryVoltageCoefficient1 =
          ConvertV2().bufferToFloat32(params[startIndex], 0);
      double batteryVoltageCoefficient2 =
          ConvertV2().bufferToFloat32(params[startIndex + 1], 0);

      // camera setting
      startIndex = 5;
      int brightness = ConvertV2().bufferToUint8(params[startIndex], 0);
      int contrast = ConvertV2().bufferToUint8(params[startIndex + 1], 0);
      int saturation = ConvertV2().bufferToUint8(params[startIndex + 2], 0);
      int specialEffect = ConvertV2().bufferToUint8(params[startIndex + 3], 0);
      bool hMirror = ConvertV2().bufferToBool(params[startIndex + 4], 0);
      bool vFlip = ConvertV2().bufferToBool(params[startIndex + 5], 0);
      int jpegQuality = ConvertV2().bufferToUint8(params[startIndex + 6], 0);

      // role
      startIndex = 12;
      int role = ConvertV2().bufferToUint8(params[startIndex], 0);

      // enable
      startIndex = 13;
      bool enable = ConvertV2().bufferToBool(params[startIndex], 0);

      // print to serial monitor
      startIndex = 14;
      bool printToSerialMonitor =
          ConvertV2().bufferToBool(params[startIndex], 0);

      adminModels = AdminModels(
        identityModel: IdentityModel(
          hardwareID: hardwareID,
          toppiID: toppiID,
          isLicense: isLicensed,
        ),
        batteryCoefficientModel: BatteryCoefficientModel(
          coefficient1: batteryVoltageCoefficient1,
          coefficient2: batteryVoltageCoefficient2,
        ),
        cameraModel: CameraModel(
          brightness: brightness,
          contrast: contrast,
          saturation: saturation,
          specialEffect: specialEffect,
          hMirror: hMirror,
          vFlip: vFlip,
          jpegQuality: jpegQuality,
        ),
        role: role,
        enable: enable,
        printToSerialMonitor: printToSerialMonitor,
      );

      log("admin model : $adminModels");

      if (responseWrite.header.status) {
        return BLEResponse.success(
          "Sukses dapat admin data",
          data: adminModels,
        );
      } else {
        return BLEResponse.error("Gagal get admin data");
      }
    } catch (e) {
      return BLEResponse.error("Error get admin data : $e");
    }
  }

  Future<BLEResponse<DeviceStatusModels>> getDeviceStatus(
      BluetoothDevice device, BLEProvider bleProvider) async {
    try {
      // create message
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      MessageV2().createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([
        CommandCode.firmware,
        CommandCode.temperature,
        CommandCode.batteryVoltage,
        CommandCode.storage,
        CommandCode.imageExplorer,
        CommandCode.dateTime,
      ], buffer);
      List<int> idata = MessageV2().createEnd(
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
        idata,
        headerBLE,
      );
      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      log("response write get device status : ${responseWrite}");
      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Fail to retrieve parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;
      String nameFirmware = ConvertV2().bufferToString(params[startIndex]);
      String versionFirmware =
          ConvertV2().bufferToString(params[startIndex + 1]);

      startIndex = 2;
      double temperature = ConvertV2().bufferToFloat32(params[startIndex], 0);
      double batteryVoltage1 =
          ConvertV2().bufferToFloat32(params[startIndex + 1], 0);
      double batteryVoltage2 =
          ConvertV2().bufferToFloat32(params[startIndex + 2], 0);

      startIndex = 5;
      int totalStorage = ConvertV2().bufferToUint32(params[startIndex], 0);
      int usedStorage = ConvertV2().bufferToUint32(params[startIndex + 1], 0);

      startIndex = 7;
      // image
      int allImage = ConvertV2().bufferToUint16(params[startIndex], 0);
      int allUnsent = ConvertV2().bufferToUint16(params[startIndex + 1], 0);
      int selfAll = ConvertV2().bufferToUint16(params[startIndex + 2], 0);
      int selfUnsent = ConvertV2().bufferToUint16(params[startIndex + 3], 0);
      int nearAll = ConvertV2().bufferToUint16(params[startIndex + 4], 0);
      int nearUnsent = ConvertV2().bufferToUint16(params[startIndex + 5], 0);

      startIndex = 13;
      int dateTimeMiliSeconds =
          ConvertV2().bufferToUint32(params[startIndex], 0) + 946659600;
      DateTime dateTime =
          DateTime.fromMillisecondsSinceEpoch(dateTimeMiliSeconds);

      DeviceStatusModels deviceStatusModels = DeviceStatusModels(
        firmwareModel: FirmwareModel(
          name: nameFirmware,
          version: versionFirmware,
        ),
        temperature: temperature,
        batteryVoltageModel: BatteryVoltageModel(
          batteryVoltage1: batteryVoltage1,
          batteryVoltage2: batteryVoltage2,
        ),
        storageModel: StorageModel(
          total: totalStorage,
          used: usedStorage,
        ),
        imageModel: ImageModel(
          allImage: allImage,
          allUnsent: allUnsent,
          selfAll: selfAll,
          selfUnsent: selfUnsent,
          nearAll: nearAll,
          nearUnsent: nearUnsent,
        ),
        dateTime: dateTime,
      );

      return BLEResponse.success(
        "Sukses dapat status perangakt",
        data: deviceStatusModels,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat status perangkat : $e");
    }
  }

  Future<BLEResponse<CaptureModel>> getCaptureSchedule(
      BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      MessageV2().createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.captureSchedule], buffer);
      List<int> idata = MessageV2().createEnd(
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
        idata,
        headerBLE,
      );
      log("response wriste get capture schedule : ${responseWrite}");

      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Fail to retrieve parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;

      int schedule = ConvertV2().bufferToUint16V2(params[startIndex]);
      int count = ConvertV2().bufferToUint8(params[startIndex + 1], 0);
      int interval = ConvertV2().bufferToUint16(params[startIndex + 2], 0);
      int spDate = ConvertV2().bufferToUint32(params[startIndex + 3], 0);
      log("MAMA from ${params[startIndex + 3]} to $spDate");
      int spSchedule = ConvertV2().bufferToUint16(params[startIndex + 4], 0);
      int spCount = ConvertV2().bufferToUint8(params[startIndex + 5], 0);
      int spInterval = ConvertV2().bufferToUint16(params[startIndex + 6], 0);
      int recentCaptureLimit =
          ConvertV2().bufferToUint16(params[startIndex + 7], 0);

      CaptureModel captureModel = CaptureModel(
        schedule: schedule,
        count: count,
        interval: interval,
        specialDate: spDate,
        specialSchedule: spSchedule,
        specialCount: spCount,
        specialInterval: spInterval,
        recentCaptureLimit: recentCaptureLimit,
      );

      return BLEResponse.success(
        "Sukses dapat jadwal pengambilan gambar",
        data: captureModel,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat jadwal pengambilan gambar : $e");
    }
  }

  Future<BLEResponse<ReceiveModel>> getReceiveSchedule(
      BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.receiveSchedule], buffer);

      List<int> idata = messageV2.createEnd(
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
        idata,
        headerBLE,
      );
      log("response write get receive schedule : $responseWrite");

      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Fail to retrieve parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;

      bool enable = ConvertV2().bufferToBool(params[startIndex], 0);
      int schedule = ConvertV2().bufferToUint16(params[startIndex + 1], 0);
      int count = ConvertV2().bufferToUint8(params[startIndex + 2], 0);
      int interval = ConvertV2().bufferToUint16(params[startIndex + 3], 0);
      int timeAdjust = ConvertV2().bufferToUint8(params[startIndex + 4], 0);
      log("masok end ga nih");
      ReceiveModel receiveModel = ReceiveModel(
        enable: enable,
        schedule: schedule,
        count: count,
        interval: interval,
        timeAdjust: timeAdjust,
      );

      return BLEResponse.success(
        "Sukses dapat jadwal pengambilan gambar",
        data: receiveModel,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat jadwal pengambilan gambar : $e");
    }
  }

  Future<BLEResponse<List<TransmitModel>>> getTransmitSchedule(
      BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.transmitSchedule], buffer);

      List<int> idata = messageV2.createEnd(
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
        idata,
        headerBLE,
      );
      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      log("response write get transmit schedule : $responseWrite");
      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      List<TransmitModel> listTransmitModel = [];
      int startIndex = 0;
      for (var i = 0; i < 8; i++) {
        listTransmitModel.add(TransmitModel(
          enable: ConvertV2().bufferToBool(params[(i * 3) + startIndex], 0),
          schedule:
              ConvertV2().bufferToUint16(params[(i * 3) + startIndex + 1], 0),
          destinationID: params[(i * 3) + startIndex + 2],
        ));
      }

      if (listTransmitModel.length != 8) {
        return BLEResponse.error(
            "Gagal panjang jadwal pengiriman tidak sesuai");
      }

      return BLEResponse.success(
        "Sukses dapat jadwal pengambilan gambar",
        data: listTransmitModel,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat jadwal pengambilan gambar : $e");
    }
  }

  Future<BLEResponse<List<UploadModel>>> getUploadSchedule(
      BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.uploadSchedule], buffer);

      List<int> idata = messageV2.createEnd(
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
        idata,
        headerBLE,
      );
      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      log("response write get upload schedule : $responseWrite");
      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      if (params.length != (8 * 2)) {
        throw Exception("Gagal panjang jadwal upload tidak sesuai");
      }

      List<UploadModel> listUploadModel = [];
      int startIndex = 0;
      for (var i = 0; i < 8; i++) {
        listUploadModel.add(UploadModel(
          enable: ConvertV2().bufferToBool(params[(i * 2) + startIndex], 0),
          schedule:
              ConvertV2().bufferToUint16(params[(i * 2) + startIndex + 1], 0),
        ));
      }

      return BLEResponse.success(
        "Sukses dapat jadwal pengambilan gambar",
        data: listUploadModel,
      );
    } catch (e) {
      return BLEResponse.error("Error dapat jadwal pengambilan gambar : $e");
    }
  }

  Future<BLEResponse<GatewayModel>> getGateway(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.gateway], buffer);

      List<int> idata = messageV2.createEnd(
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
        idata,
        headerBLE,
      );
      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      log("response write get gateway : $responseWrite");
      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;
      String server = ConvertV2().bufferToString(params[startIndex]);
      int port = ConvertV2().bufferToUint16(params[startIndex + 1], 0);
      int uploadUsing = ConvertV2().bufferToUint8(params[startIndex + 2], 0);
      int uploadInitialDelay =
          ConvertV2().bufferToUint8(params[startIndex + 3], 0);
      String wifiSSID = ConvertV2().bufferToString(params[startIndex + 4]);
      String wifiPassword = ConvertV2().bufferToString(params[startIndex + 5]);
      String modemAPN = ConvertV2().bufferToString(params[startIndex + 6]);

      return BLEResponse.success(
        "Sukses dapat gateway",
        data: GatewayModel(
          server: server,
          port: port,
          uploadUsing: uploadUsing,
          uploadInitialDelay: uploadInitialDelay,
          wifiSSID: wifiSSID,
          wifiPassword: wifiPassword,
          modemAPN: modemAPN,
        ),
      );
    } catch (e) {
      return BLEResponse.error("Error dapat gateway : $e");
    }
  }

  Future<BLEResponse<MetaDataModel>> getMetaData(
      BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.metaData], buffer);

      List<int> idata = messageV2.createEnd(
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
        idata,
        headerBLE,
      );
      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      log("response write get meta data : $responseWrite");
      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;
      String meterModel = ConvertV2().bufferToString(params[startIndex]);
      String meterSN = ConvertV2().bufferToString(params[startIndex + 1]);
      String meterSeal = ConvertV2().bufferToString(params[startIndex + 2]);
      int timeUTC = ConvertV2().bufferToUint8(params[startIndex + 3], 0);

      return BLEResponse.success(
        "Sukses dapat meta data",
        data: MetaDataModel(
          meterModel: meterModel,
          meterSN: meterSN,
          meterSeal: meterSeal,
          timeUTC: timeUTC,
        ),
      );
    } catch (e) {
      return BLEResponse.error("Error dapat meta data : $e");
    }
  }

  Future<BLEResponse<ImageModel>> getImage(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.imageExplorer], buffer);

      List<int> idata = messageV2.createEnd(
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
        idata,
        headerBLE,
      );
      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      log("response write get image : $responseWrite");
      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;
      int allImage = ConvertV2().bufferToUint16(params[startIndex], 0);
      int allUnsent = ConvertV2().bufferToUint16(params[startIndex + 1], 0);
      int selfAll = ConvertV2().bufferToUint16(params[startIndex + 2], 0);
      int selfUnsent = ConvertV2().bufferToUint16(params[startIndex + 3], 0);
      int nearAll = ConvertV2().bufferToUint16(params[startIndex + 4], 0);
      int nearUnsent = ConvertV2().bufferToUint16(params[startIndex + 5], 0);

      return BLEResponse.success(
        "Sukses dapat image",
        data: ImageModel(
          allImage: allImage,
          allUnsent: allUnsent,
          selfAll: selfAll,
          selfUnsent: selfUnsent,
          nearAll: nearAll,
          nearUnsent: nearUnsent,
        ),
      );
    } catch (e) {
      return BLEResponse.error("Error dapat image : $e");
    }
  }

  Future<BLEResponse<StorageModel>> getStorage(BLEProvider bleProvider) async {
    try {
      int command = CommandCode.get;
      int uniqueID = UniqueIDManager().getUniqueID();
      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8([CommandCode.storage], buffer);

      List<int> idata = messageV2.createEnd(
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
        idata,
        headerBLE,
      );
      log("response write get storage : $responseWrite");
      if (!responseWrite.header.status) {
        return BLEResponse.errorFromBLE(responseWrite);
      }

      // turn to a model
      List<List<int>> params = [];
      for (int i = 0; i < (responseWrite.header.parameterCount ?? 0); i++) {
        List<int>? param = MessageV2().getParameter(responseWrite.buffer, i);
        if (param == null) {
          throw Exception("Gagal untuk mengembalikan parameter");
        }
        params.add(param);
      }

      log("params : ${params}");

      int startIndex = 0;

      int totalStorage = ConvertV2().bufferToUint16(params[startIndex], 0);
      int usedStorage = ConvertV2().bufferToUint16(params[startIndex + 1], 0);

      return BLEResponse.success(
        "Sukses dapat penyimpanan",
        data: StorageModel(total: totalStorage, used: usedStorage),
      );
    } catch (e) {
      return BLEResponse.error("Error dapat penyimpanan : $e");
    }
  }
}
