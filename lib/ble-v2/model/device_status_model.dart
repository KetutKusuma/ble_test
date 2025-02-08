import 'package:ble_test/ble-v2/model/models.dart';

class DeviceStatusModels {
  FirmwareModel? firmwareModel;
  double? temperature;
  BatteryVoltageModel? batteryVoltageModel;
  StorageModel? storageModel;
  ImageModel? imageModel;
  DateTime? dateTime;

  DeviceStatusModels({
    this.firmwareModel,
    this.temperature,
    this.batteryVoltageModel,
    this.storageModel,
    this.imageModel,
    this.dateTime,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
firmwareModel : $firmwareModel \ntemperature : $temperature \nbatteryVoltageModel : $batteryVoltageModel \nstorageModel : $storageModel \nimageModel : $imageModel \ndateTime : $dateTime
    }
''';
  }
}
