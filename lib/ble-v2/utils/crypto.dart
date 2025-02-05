import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

import '../../utils/crc32.dart';

class CryptoUtilsV2 {
  static String md5Hash(String text) {
    final bytes = utf8.encode(text);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  static int crc32(List<int> bytes) {
    return CRC32.compute(bytes);
  }

  static Uint8List pkcs5Padding(Uint8List src, int blockSize) {
    final padding = blockSize - (src.length % blockSize);
    return Uint8List.fromList(src + List.filled(padding, padding));
  }

  static Uint8List pkcs5Unpadding(Uint8List src) {
    final unpadding = src.last;
    if (unpadding > src.length) {
      throw Exception("Invalid padding length");
    }
    return src.sublist(0, src.length - unpadding);
  }

  static Uint8List aesEncrypt(List<int> input, List<int> key, List<int> iv) {
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(
          true,
          ParametersWithIV(KeyParameter(Uint8List.fromList(key)),
              Uint8List.fromList(iv))); // true untuk encrypt
    return _processBlocks(
        cipher, pkcs5Padding(Uint8List.fromList(input), cipher.blockSize));
  }

  static Uint8List aesDecrypt(List<int> input, List<int> key, List<int> iv) {
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(
          false,
          ParametersWithIV(KeyParameter(Uint8List.fromList(key)),
              Uint8List.fromList(iv))); // false untuk decrypt
    final decrypted = _processBlocks(cipher, Uint8List.fromList(input));
    return pkcs5Unpadding(decrypted);
  }

  static String base64Encode(List<int> bytes) {
    return base64.encode(bytes);
  }

  static Uint8List base64Decode(String encoded) {
    return Uint8List.fromList(base64.decode(encoded));
  }

  static Uint8List _processBlocks(BlockCipher cipher, List<int> input) {
    final output = Uint8List(input.length);
    for (int offset = 0; offset < input.length;) {
      offset += cipher.processBlock(
          Uint8List.fromList(input), offset, output, offset);
    }
    return output;
  }
}
