import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoUtils {
  static String md5Hash(String text) {
    final bytes = utf8.encode(text);
    final digest = md5.convert(bytes);
    return digest.toString();
  }

  static int crc32(Uint8List bytes) {
    int crc = 0xFFFFFFFF;
    List<int> table = List<int>.generate(256, (i) {
      int c = i;
      for (int j = 0; j < 8; j++) {
        if ((c & 1) != 0) {
          c = 0xedb88320 ^ (c >> 1);
        } else {
          c >>= 1;
        }
      }
      return c;
    });
    for (final byte in bytes) {
      crc = table[(crc ^ byte) & 0xff] ^ (crc >> 8);
    }
    return ~crc & 0xFFFFFFFF;
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

  static Uint8List aesEncrypt(Uint8List input, Uint8List key, Uint8List iv) {
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(
          true, ParametersWithIV(KeyParameter(key), iv)); // true untuk encrypt
    return _processBlocks(cipher, pkcs5Padding(input, cipher.blockSize));
  }

  static Uint8List aesDecrypt(Uint8List input, Uint8List key, Uint8List iv) {
    final cipher = CBCBlockCipher(AESFastEngine())
      ..init(false,
          ParametersWithIV(KeyParameter(key), iv)); // false untuk decrypt
    print("mama sampe process blocks");
    final decrypted = _processBlocks(cipher, input);
    print("mama sampe process unpadding");
    return pkcs5Unpadding(decrypted);
  }

  static String base64Encode(Uint8List bytes) {
    return base64.encode(bytes);
  }

  static Uint8List base64Decode(String encoded) {
    return Uint8List.fromList(base64.decode(encoded));
  }

  static Uint8List _processBlocks(BlockCipher cipher, Uint8List input) {
    final output = Uint8List(input.length);
    for (int offset = 0; offset < input.length;) {
      offset += cipher.processBlock(input, offset, output, offset);
    }
    return output;
  }
}
