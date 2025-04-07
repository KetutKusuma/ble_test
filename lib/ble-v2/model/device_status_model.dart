import 'dart:ffi';

import 'package:ble_test/ble-v2/model/sub_model/battery_voltage_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/firmware_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/image_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/other_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/storage_model.dart';

class DeviceStatusModels {
  FirmwareModel? firmwareModel;
  double? temperature;
  BatteryVoltageModel? batteryVoltageModel;
  StorageModel? storageModel;
  ImageModel? imageModel;
  DateTime? dateTime;
  int? timeUTC;
  OtherModel? otherModel;

  DeviceStatusModels({
    this.firmwareModel,
    this.temperature,
    this.batteryVoltageModel,
    this.storageModel,
    this.imageModel,
    this.dateTime,
    this.timeUTC,
    this.otherModel,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
firmwareModel : $firmwareModel \ntemperature : $temperature \nbatteryVoltageModel : $batteryVoltageModel \nstorageModel : $storageModel \nimageModel : $imageModel \ndateTime : $dateTime, timeUTC : $timeUTC, otherModel : $otherModel
    }
''';
  }
}
