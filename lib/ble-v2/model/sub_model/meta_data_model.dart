import 'package:ble_test/ble-v2/device_configuration/device_configuration.dart';

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

  static MetaDataModel fromDeviceConfiguration(MetaDataModelYaml c) {
    try {
      return MetaDataModel(
        paramCount: 7,
        meterModel: c.meterModel ?? "",
        meterSN: c.meterSN ?? "",
        meterSeal: c.meterSeal ?? "",
        custom: c.custom ?? "",
        numberDigit: c.numberDigit,
        numberDecimal: c.numberDecimal,
        customerID: c.customerId,
      );
    } catch (e) {
      throw "Error in MetaDataModel.fromDeviceConfiguration: $e";
    }
  }

  void toDeviceConfiguration(MetaDataModelYaml c) {
    c.meterModel = meterModel;
    c.meterSN = meterSN;
    c.meterSeal = meterSeal;
    c.custom = custom;
    c.numberDigit = numberDigit;
    c.numberDecimal = numberDecimal;
    c.customerId = customerID;
  }
}
