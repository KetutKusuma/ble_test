import 'package:ble_test/ble-v2/model/sub_model/camera_model.dart';
import 'package:ble_test/ble-v2/model/sub_model/identity_model.dart';

import 'sub_model/battery_coefficient_model.dart';

class AdminModels {
  IdentityModel? identityModel;
  BatteryCoefficientModel? batteryCoefficientModel;
  CameraModel? cameraModel;
  int? role;
  bool? enable;
  bool? printToSerialMonitor;

  AdminModels({
    this.identityModel,
    this.batteryCoefficientModel,
    this.cameraModel,
    this.role,
    this.enable,
    this.printToSerialMonitor,
  });

  String getLicenseValidString() {
    if (identityModel!.isLicense) {
      return "Valid";
    } else {
      return "Invalid";
    }
  }

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
identityModel : $identityModel \nbatteryCoefficientModel : $batteryCoefficientModel \ncameraModel : $cameraModel \nrole : $role \nenable : $enable \nprintToSerialMonitor : $printToSerialMonitor
    }''';
  }
}
