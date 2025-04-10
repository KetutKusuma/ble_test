class MetaDataModel {
  String meterModel;
  String meterSN;
  String meterSeal;
  String custom;

  // untuk handle versi >= 2.21
  int? paramCount;
  int? numberDigit;
  int? numberDecimal;
  String? customerID;

  MetaDataModel({
    required this.meterModel,
    required this.meterSN,
    required this.meterSeal,
    required this.custom,
    this.paramCount,
    this.numberDigit,
    this.numberDecimal,
    this.customerID,
  });

  @override
  String toString() {
    return '''
{
meterModel : $meterModel \nmeterSN : $meterSN \nmeterSeal : $meterSeal \ncustom : $custom, \nparamCount : $paramCount \nnumberDigit : $numberDigit \nnumberDecimal : $numberDecimal \ncustomerID: $customerID
      }
''';
  }
}
