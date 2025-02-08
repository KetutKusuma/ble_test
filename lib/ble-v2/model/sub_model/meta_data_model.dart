class MetaDataModel {
  final String modelMeter;
  final String meterSN;
  final String meterSeal;
  final int timeUTC;

  MetaDataModel(
      {required this.modelMeter,
      required this.meterSN,
      required this.meterSeal,
      required this.timeUTC});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
modelMeter : $modelMeter \nmeterSN : $meterSN \nmeterSeal : $meterSeal \ntimeUTC : $timeUTC
      }
''';
  }
}
