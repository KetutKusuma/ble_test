import 'bytes_convert.dart';

enum Translation {
  string,
  int8,
  int16,
  int32,
}

class TranslationCustom {
  static dynamic getTranslation(Translation type, List<int> bytes) {
    switch (type) {
      case Translation.string:
        return BytesConvert.bytesToString(bytes);
      case Translation.int8:
        return BytesConvert.bytesToInt8(bytes);
      case Translation.int16:
        return BytesConvert.bytesToInt16(bytes);
      case Translation.int32:
        return BytesConvert.bytesToInt32(bytes);
    }
  }
}
