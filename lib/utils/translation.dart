import 'package:ble_test/utils/converter/bytes_convert.dart';
import 'package:ble_test/utils/feature/enum_feature.dart';

class TranslationCustom {
  static dynamic getTranslation(ReturnType type, List<int> bytes) {
    switch (type) {
      case ReturnType.string:
        return BytesConvert.bytesToString(bytes);
      case ReturnType.int8:
        return BytesConvert.bytesToInt8(bytes);
      case ReturnType.int16:
        return BytesConvert.bytesToInt16(bytes);
      case ReturnType.int32:
        return BytesConvert.bytesToInt32(bytes);
      case ReturnType.bool:
        return BytesConvert.bytesToBool(bytes);
    }
  }
}
