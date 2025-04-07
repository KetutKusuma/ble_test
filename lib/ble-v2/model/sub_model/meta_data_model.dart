class MetaDataModel {
  String meterModel;
  String meterSN;
  String meterSeal;
  String custom;

  MetaDataModel({
    required this.meterModel,
    required this.meterSN,
    required this.meterSeal,
    required this.custom,
  });

  @override
  String toString() {
    // TODO: implement toString
    return '''
{
meterModel : $meterModel \nmeterSN : $meterSN \nmeterSeal : $meterSeal \ncustom : $custom 
      }
''';
  }
}
