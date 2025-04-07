import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

class AESUtil {
  static Uint8List pkcs5Padding(Uint8List src, int blockSize) {
    int padding = blockSize - (src.length % blockSize);
    print("padding : $padding");
    Uint8List data =
        Uint8List.fromList([...src, ...List.filled(padding, padding)]);
    print("padding data : $data");
    return data;
  }

  static Uint8List pkcs5UnPadding(Uint8List src) {
    int padding = src.last;
    return src.sublist(0, src.length - padding);
  }

  static Uint8List aesEncrypt(Uint8List input, Uint8List key, Uint8List iv) {
    final encrypter =
        Encrypter(AES(Key(key), mode: AESMode.cbc, padding: null));
    final encrypted =
        encrypter.encryptBytes(pkcs5Padding(input, 16), iv: IV(iv));
    return Uint8List.fromList(encrypted.bytes);
  }

  static Uint8List aesDecrypt(Uint8List input, Uint8List key, Uint8List iv) {
    final encrypter =
        Encrypter(AES(Key(key), mode: AESMode.cbc, padding: null));
    final decrypted = encrypter.decryptBytes(Encrypted(input), iv: IV(iv));
    return pkcs5UnPadding(Uint8List.fromList(decrypted));
  }
}
