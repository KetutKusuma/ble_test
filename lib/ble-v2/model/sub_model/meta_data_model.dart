class MetaDataModel {
  String meterModel;
  String meterSN;
  String meterSeal;
  int timeUTC;

  MetaDataModel(
      {required this.meterModel,
      required this.meterSN,
      required this.meterSeal,
      required this.timeUTC});

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
meterModel : $meterModel \nmeterSN : $meterSN \nmeterSeal : $meterSeal \ntimeUTC : $timeUTC
      }
''';
  }
}
