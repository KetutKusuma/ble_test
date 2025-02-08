class BatteryVoltageModel {
  final double batteryVoltage1;
  final double batteryVoltage2;

  BatteryVoltageModel(
      {required this.batteryVoltage1, required this.batteryVoltage2});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
batteryVoltage1 : $batteryVoltage1 \nbatteryVoltage2 : $batteryVoltage2
      }
''';
  }
}
