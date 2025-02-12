class MetaDataModel {
  String meterModel;
  String meterSN;
  String meterSeal;
  String custom;
  int timeUTC;

  MetaDataModel({
    required this.meterModel,
    required this.meterSN,
    required this.meterSeal,
    required this.custom,
    required this.timeUTC,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
meterModel : $meterModel \nmeterSN : $meterSN \nmeterSeal : $meterSeal \ncustom : $custom \ntimeUTC : $timeUTC
      }
''';
  }
}
