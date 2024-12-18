import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class CryptoAES256 {
  String encryptData(String key, String iv, String plaintext) {
    final keyBytes = utf8.encode(key);
    final ivBytes = utf8.encode(iv);

    final keyLength = keyBytes.length == 32 ? 32 : 16;
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, keyLength))),
      mode: encrypt.AESMode.cbc,
      padding: 'PKCS7', // Specify padding here
    ));

    final ivFinal = encrypt.IV(Uint8List.fromList(ivBytes));

    final encrypted = encrypter.encrypt(plaintext, iv: ivFinal);
    return encrypted.base64;
  }

  String encryptWPadding(
      String key, String iv, String plaintext, String padding) {
    final keyBytes = utf8.encode(key);
    final ivBytes = utf8.encode(iv);

    final keyLength = keyBytes.length == 32 ? 32 : 16;
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, keyLength))),
      mode: encrypt.AESMode.cbc,
      padding: padding, // Specify padding here
    ));

    final ivFinal = encrypt.IV(Uint8List.fromList(ivBytes));

    final encrypted = encrypter.encrypt(plaintext, iv: ivFinal);
    return encrypted.base64;
  }

  String decryptWPadding(
      String key, String iv, String encryptedData, String padding) {
    final keyBytes = utf8.encode(key);
    final ivBytes = utf8.encode(iv);

    final keyLength = keyBytes.length == 32 ? 32 : 16;
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, keyLength))),
      mode: encrypt.AESMode.cbc,
      padding: padding, // Specify padding here
    ));

    final ivFinal = encrypt.IV(Uint8List.fromList(ivBytes));

    final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
    final decrypted = encrypter.decrypt(encrypted, iv: ivFinal);

    return decrypted;
  }
}

class CryptoMD5 {
  static String computeMd5(String input) {
    // Convert the input string to bytes
    List<int> bytes = utf8.encode(input);

    // Compute the MD5 hash
    Digest digest = md5.convert(bytes);

    // Return the hash as a hexadecimal string
    return digest.toString(); // This is the MD5 hash as a string
  }
}
