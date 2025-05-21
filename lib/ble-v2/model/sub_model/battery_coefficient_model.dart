import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';

class BatteryCoefficientModel {
  double coefficient1;
  double coefficient2;

  BatteryCoefficientModel(
      {required this.coefficient1, required this.coefficient2});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
coefficient1 : $coefficient1 \ncoefficient2 : $coefficient2
      }
''';
  }

  void toDeviceConfiguration(BatteryVoltageCoefficientModelYaml c) {
    c.voltageCoefficient1 = coefficient1;
    c.voltageCoefficient2 = coefficient2;
  }

  static BatteryCoefficientModel fromDeviceConfiguration(
      BatteryVoltageCoefficientModelYaml c) {
    try {
      return BatteryCoefficientModel(
        coefficient1: c.voltageCoefficient1 ?? 0,
        coefficient2: c.voltageCoefficient2 ?? 0,
      );
    } catch (e) {
      throw "Error in BatteryCoefficientModel.fromDeviceConfiguration: $e";
    }
  }
}
