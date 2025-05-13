import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_each_get.dart';
import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';
import 'package:ble_test/ble-v2/model/sub_model/battery_coefficient_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/capture_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/gateway_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/meta_data_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/receive_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/transmit_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/upload_model.dart';

import '../model/sub_model/camera_model.dart';

class FunctionDeviceConfiguration {
  final CommandEachGet _commandEachGet = CommandEachGet();
  final Command _command = Command();
  Future<DeviceConfiguration?> getDeviceConfiguration(
      BLEProvider bleProvider) async {
    // try {
    AdministratorModelYaml administrator = AdministratorModelYaml(
      setRole: "regular",
      setEnable: false,
      setDateTime: false,
      gateway: GatewayModelYaml(),
      metaData: MetaDataModelYaml(),
      batteryVoltageCoefficient: BatteryVoltageCoefficientModelYaml(),
      cameraSetting: CameraSettingModelYaml(),
      printToSerialMonitor: false,
    );

    BLEResponse<int> bufferRole = await _commandEachGet.getRole(bleProvider);
    administrator.setRoleFromUint8(bufferRole.data ?? 0);

    BLEResponse<bool> bufferEnable =
        await _commandEachGet.getEnable(bleProvider);
    administrator.setEnable = bufferEnable.data ?? false;

    administrator.setDateTime = true;

    /// FOR GATEWAY
    BLEResponse<GatewayModel> gatewayModel =
        await _command.getGateway(bleProvider);
    if (gatewayModel.data == null) {
      log("Error gatewayModel is null : $gatewayModel");
      throw "Error gatewayModel is null";
    }

    // memasukan gateway data ke administrator
    gatewayModel.data?.toDeviceConfiguration(administrator.gateway!);

    /// FOR METADATA
    BLEResponse<MetaDataModel> metaDataModel =
        await _command.getMetaData(bleProvider);

    if (metaDataModel.data == null) {
      log("Error metaDataModel is null : $metaDataModel");
      throw "Error metaDataModel is null";
    }
    // memasukan meta data ke administrator
    metaDataModel.data?.toDeviceConfiguration(administrator.metaData!);

    // get time utc
    BLEResponse<int> timeUTC = await _commandEachGet.getTimeUTC(bleProvider);
    administrator.metaData!.timeUTC = MetaDataModelYaml()
        .setTimeUTCFromUint8(timeUTC.data ?? 0); // set time utc();
    // FOR BATTERY
    BLEResponse<BatteryCoefficientModel> batteryCoefficientModel =
        await _commandEachGet.getBatteryVoltageCoefficient(bleProvider);

    if (batteryCoefficientModel.data == null) {
      log("Error batteryCoefficientModel is null : $batteryCoefficientModel");
      throw "Error batteryCoefficientModel is null";
    }
    // memasukan battery data ke administrator
    batteryCoefficientModel.data
        ?.toDeviceConfiguration(administrator.batteryVoltageCoefficient!);

    // FOR CAMERA
    BLEResponse<CameraModel> cameraModel =
        await _commandEachGet.getCameraSetting(bleProvider);

    if (cameraModel.data == null) {
      log("Error cameraModel is null : $cameraModel");
      throw "Error cameraModel is null";
    }
    // memasukan camera data ke administrator
    cameraModel.data?.toDeviceConfiguration(administrator.cameraSetting!);

    // FOR PRINT TO SERIAL MONITOR
    BLEResponse<bool> printToSerialMonitor =
        await _commandEachGet.getPrintToSerial(bleProvider);

    if (printToSerialMonitor.data == null) {
      log("Error printToSerialMonitor is null : $printToSerialMonitor");
      throw "Error printToSerialMonitor is null";
    }
    administrator.printToSerialMonitor = printToSerialMonitor.data ?? false;

    // !! CAPTURE MODEL
    BLEResponse<CaptureModel> captureModel =
        await _command.getCaptureSchedule(bleProvider);

    if (captureModel.data == null) {
      log("Error captureModel is null : $captureModel");
      throw "Error captureModel is null";
    }

    CaptureScheduleModelYaml captureScheduleModelYaml =
        CaptureScheduleModelYaml();
    captureModel.data?.toDeviceConfiguration(captureScheduleModelYaml);

    // !! TRANSMIT MODEL
    BLEResponse<List<TransmitModel>> transmitModel =
        await _command.getTransmitSchedule(bleProvider);

    if (transmitModel.data == null) {
      log("Error transmitModel is null : $transmitModel");
      throw "Error transmitModel is null";
    }

    TransmitScheduleModelYaml transmitScheduleModelYaml =
        TransmitScheduleModelYaml();
    transmitModel.data?[0].toDeviceConfiguration(
        transmitScheduleModelYaml, transmitModel.data ?? []);

    // !! RECEIVE MODEL
    BLEResponse<List<ReceiveModel>> receiveModel =
        await _command.getReceiveSchedule(bleProvider);

    if (receiveModel.data == null) {
      log("Error receiveModel is null : $receiveModel");
      throw "Error receiveModel is null";
    }

    ReceiveScheduleModelYaml receiveScheduleModelYaml =
        ReceiveScheduleModelYaml();
    receiveModel.data?[0].toDeviceConfiguration(
      receiveScheduleModelYaml,
      receiveModel.data ?? [],
    );

    // !! UPLOAD MODEL
    BLEResponse<List<UploadModel>> uploadModel =
        await _command.getUploadSchedule(bleProvider);

    if (uploadModel.data == null) {
      log("Error uploadModel is null : $uploadModel");
      throw "Error uploadModel is null";
    }

    UploadScheduleModelYaml uploadScheduleModelYaml = UploadScheduleModelYaml();
    uploadModel.data?[0].toDeviceConfiguration(
      uploadScheduleModelYaml,
      uploadModel.data ?? [],
    );

    DeviceConfiguration dc = DeviceConfiguration(
      administrator: administrator,
      captureSchedule: captureScheduleModelYaml,
      transmitSchedule: transmitScheduleModelYaml,
      receiveSchedule: receiveScheduleModelYaml,
      uploadSchedule: uploadScheduleModelYaml,
    );

    return dc;
    // } catch (e) {
    //   log("Error getDeviceConfiguration - $e");
    //   throw "Error getDeviceConfiguration - $e");
    // }
  }
}
