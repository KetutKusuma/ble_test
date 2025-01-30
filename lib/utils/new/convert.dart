import 'dart:convert';
import 'dart:typed_data';
import 'package:ble_test/utils/crc32.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

class ConvertNew {
  String md5Hash(String text) {
    return md5.convert(utf8.encode(text)).toString();
  }

  int crc32Hash(Uint8List data) {
    return CRC32.compute(data);
  }

  Uint8List pkcs5Padding(Uint8List src, int blockSize) {
    final padding = blockSize - (src.length % blockSize);
    return Uint8List.fromList(src + List<int>.filled(padding, padding));
  }

  Uint8List pkcs5UnPadding(Uint8List src) {
    final padding = src.last;
    if (padding > src.length) {
      throw ArgumentError('Invalid padding size');
    }
    return src.sublist(0, src.length - padding);
  }

  Uint8List aesEncrypt(Uint8List input, Uint8List key, Uint8List iv) {
    final encrypter = Encrypter(AES(Key(key), mode: AESMode.cbc));
    final encrypted = encrypter.encryptBytes(input, iv: IV(iv));
    return Uint8List.fromList(encrypted.bytes);
  }

  Uint8List aesDecrypt(Uint8List input, Uint8List key, Uint8List iv) {
    final encrypter = Encrypter(AES(Key(key), mode: AESMode.cbc));
    final decrypted = encrypter.decryptBytes(Encrypted(input), iv: IV(iv));
    return pkcs5UnPadding(Uint8List.fromList(decrypted));
  }

  String base64Encode(Uint8List data) {
    return base64.encode(data);
  }

  Uint8List base64Decode(String base64String) {
    return Uint8List.fromList(base64.decode(base64String));
  }
}
