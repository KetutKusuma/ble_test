import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/model/sub_model/battery_coefficient_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/camera_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/capture_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/gateway_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/identity_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/meta_data_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/receive_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/transmit_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/upload_model.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/message.dart';
import 'package:ble_test/utils/global.dart';
import 'package:ble_test/utils/extension/extension.dart';

class CommandSet {
  static final ivGlobal = InitConfig.data().IV;
  static final keyGlobal = InitConfig.data().KEY;
  static final messageV2 = MessageV2();

  Future<BLEResponse> setCaptureSchedule(
      BLEProvider bleProvider, CaptureModel captureModel) async {
    try {
      int command = CommandCode.captureSchedule;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];

      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addUint16(captureModel.schedule, buffer);
      messageV2.addUint8(captureModel.count, buffer);
      messageV2.addUint16(captureModel.interval, buffer);
      messageV2.addUint32(captureModel.specialDate, buffer);
      messageV2.addUint16(captureModel.specialSchedule, buffer);
      messageV2.addUint8(captureModel.specialCount, buffer);
      messageV2.addUint16(captureModel.specialInterval, buffer);
      messageV2.addUint16(captureModel.recentCaptureLimit, buffer);

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
      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah jadwal pengambilan gambar",
            data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah jadwal pengambilan gambar : $e");
    }
  }

  Future<BLEResponse> setTransmitSchedule(
      BLEProvider bleProvider, List<TransmitModel> transmit) async {
    if (transmit.isEmpty || transmit.length != 8) {
      return BLEResponse.error(
          "Error ubah jadwal kirim data : jumlah kirim data tidak sesuai ${transmit.length}");
    }
    try {
      int command = CommandCode.transmitSchedule;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      for (var m in transmit) {
        messageV2.addBool(m.enable, buffer);
        messageV2.addUint16(m.schedule, buffer);
        messageV2.addArrayOfUint8(m.destinationID, buffer);
      }

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah jadwal kirim data", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah jadwal kirim data : $e");
    }
  }

  Future<BLEResponse> setReceiveSchedule(
      BLEProvider bleProvider, List<ReceiveModel> listReceive) async {
    try {
      int command = CommandCode.receiveSchedule;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      for (var i = 0; i < 16; i++) {
        messageV2.addBool(listReceive[i].enable, buffer);
        messageV2.addUint16(listReceive[i].schedule, buffer);
        messageV2.addUint8(listReceive[i].timeAdjust, buffer);
      }

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah jadwal terima data",
            data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah jadwal terima data : $e");
    }
  }

  Future<BLEResponse> setUploadSchedule(
      BLEProvider bleProvider, List<UploadModel> upload) async {
    if (upload.isEmpty || upload.length != 8) {
      return BLEResponse.error(
          "Error ubah jadwal upload : jumlah upload tidak sesuai ${upload.length}");
    }
    try {
      int command = CommandCode.uploadSchedule;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      for (var m in upload) {
        messageV2.addBool(m.enable, buffer);
        messageV2.addUint16(m.schedule, buffer);
      }

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah jadwal upload", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah jadwal upload : $e");
    }
  }

  Future<BLEResponse> setIdentity(
      BLEProvider bleProvider, IdentityModel identity, String license) async {
    try {
      int command = CommandCode.identity;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> licenseList = ConvertV2().stringHexToArrayUint8(license, 4);

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addArrayOfUint8(identity.toppiID, buffer);
      messageV2.addArrayOfUint8(licenseList, buffer);

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

      log("response write set identity : ${responseWrite}");

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah identitas", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat ubah identitas : $e");
    }
  }

  Future<BLEResponse> setGateway(
      BLEProvider bleProvider, GatewayModel gateway) async {
    try {
      log("param countnya gateway : ${gateway.paramCount}");
      int command = CommandCode.gateway;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addString(gateway.server, buffer);
      messageV2.addUint16(gateway.port, buffer);
      messageV2.addUint8(gateway.uploadUsing, buffer);
      messageV2.addUint8(gateway.uploadInitialDelay, buffer);
      messageV2.addString(gateway.wifi.ssid, buffer);
      messageV2.addString(gateway.wifi.password, buffer);
      if (gateway.paramCount == 7) {
        messageV2.addString(gateway.modemAPN, buffer);
      } else if (gateway.paramCount == 12) {
        messageV2.addBool(gateway.wifi.secure, buffer);
        messageV2.addString(gateway.wifi.mikrotikIP, buffer);
        messageV2.addBool(gateway.wifi.mikrotikLoginSecure, buffer);
        messageV2.addString(gateway.wifi.mikrotikUsername, buffer);
        messageV2.addString(gateway.wifi.mikrotikPassword, buffer);
        messageV2.addString(gateway.modemAPN, buffer);
      } else {
        return BLEResponse.error(
            "Kesalahan pada panjang parameter gateway tidak sesuai");
      }

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah gateway", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah gateway : $e");
    }
  }

  Future<BLEResponse> setMetaData(
      BLEProvider bleProvider, MetaDataModel meta) async {
    try {
      int command = CommandCode.metaData;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addString(meta.meterModel.changeEmptyString(), buffer);
      messageV2.addString(meta.meterSN.changeEmptyString(), buffer);
      messageV2.addString(meta.meterSeal.changeEmptyString(), buffer);

      if (meta.paramCount == 4) {
        messageV2.addString(meta.custom.changeEmptyString(), buffer);
      } else if (meta.paramCount == 7) {
        messageV2.addString(meta.customerID ?? "-", buffer);
        messageV2.addUint8(meta.numberDigit ?? 0, buffer);
        messageV2.addUint8(meta.numberDecimal ?? 0, buffer);
        messageV2.addString(meta.custom.changeEmptyString(), buffer);
      } else {
        return BLEResponse.error("Kesalahan pada panjang parameter meta data");
      }
      // messageV2.addUint8(meta.timeUTC, buffer);

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah meta data", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah meta data : $e");
    }
  }

  Future<BLEResponse> setCamera(
      BLEProvider bleProvider, CameraModel camera) async {
    try {
      int command = CommandCode.cameraSetting;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addInt8(camera.brightness, buffer);
      messageV2.addInt8(camera.contrast, buffer);
      messageV2.addInt8(camera.saturation, buffer);
      messageV2.addUint8(camera.specialEffect, buffer);
      messageV2.addBool(camera.hMirror, buffer);
      messageV2.addBool(camera.vFlip, buffer);
      messageV2.addUint8(camera.jpegQuality, buffer);
      messageV2.addUint16(camera.adjustImageRotation, buffer);

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah kamera", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah kamera : $e");
    }
  }

  Future<BLEResponse> setPrintSerialMonitor(
      BLEProvider bleProvider, bool b) async {
    try {
      int command = CommandCode.printToSerialMonitor;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addBool(b, buffer);

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah layar serial", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah layar serial : $e");
    }
  }

  Future<BLEResponse> setEnable(BLEProvider bleProvider, bool b) async {
    try {
      int command = CommandCode.enable;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addBool(b, buffer);

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah status toppi", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah status Toppi : $e");
    }
  }

  Future<BLEResponse> setDateTime(BLEProvider bleProvider, int seconds) async {
    try {
      int command = CommandCode.dateTime;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addUint32(seconds, buffer);

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah waktu", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah waktu : $e");
    }
  }

  Future<BLEResponse> setRole(BLEProvider bleProvider, int role) async {
    try {
      int command = CommandCode.role;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);

      messageV2.addUint8(role, buffer);

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

      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah role", data: null);
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah role : $e");
    }
  }

  Future<BLEResponse> setBatteryVoltageCoef(
      BLEProvider bleProvider, BatteryCoefficientModel b) async {
    try {
      int command = CommandCode.batteryVoltageCoefficient;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addFloat32(b.coefficient1, buffer);
      messageV2.addFloat32(b.coefficient2, buffer);

      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE =
          Header(uniqueID: uniqueID, command: command, status: false);

      Response responseWrite = await bleProvider.writeData(data, headerBLE);
      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah baterai koefisien");
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error ubah koefisien tegangan");
    }
  }

  Future<BLEResponse> setPassword(
      BLEProvider bleProvider, String oldPassword, String newPassword) async {
    try {
      int command = CommandCode.changePassword;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addString(oldPassword, buffer);
      messageV2.addString(newPassword, buffer);

      List<int> data = messageV2.createEnd(
        sessionID,
        buffer,
        keyGlobal,
        ivGlobal,
      );

      Header headerBLE =
          Header(uniqueID: uniqueID, command: command, status: false);

      Response responseWrite = await bleProvider.writeData(data, headerBLE);
      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah password");
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat ubah password");
    }
  }

  Future<BLEResponse> setTimeUTC(BLEProvider bleProvider, int timeUTC) async {
    try {
      int command = CommandCode.timeUTC;
      int uniqueID = UniqueIDManager().getUniqueID();

      List<int> buffer = [];
      messageV2.createBegin(uniqueID, MessageV2.request, command, buffer);
      messageV2.addUint8(timeUTC, buffer);
      List<int> data =
          messageV2.createEnd(sessionID, buffer, keyGlobal, ivGlobal);

      Header headerBLE =
          Header(uniqueID: uniqueID, command: command, status: false);

      Response responseWrite = await bleProvider.writeData(data, headerBLE);
      if (responseWrite.header.status) {
        return BLEResponse.success("Sukses ubah waktu utc");
      } else {
        return BLEResponse.errorFromBLE(responseWrite);
      }
    } catch (e) {
      return BLEResponse.error("Error dapat ubah waktu utc");
    }
  }
}
