import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';

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

  Future<String> encryptCustomV2(
      String key, String iv, String plaintext) async {
    List<int> keyBytes = convResultMD5toBytes(key);
    List<int> ivBytes = convResultMD5toBytes(iv);

    String resultAesHexString =
        await AESService.encrypt(plaintext, keyBytes, ivBytes);

    return resultAesHexString;
  }

  String encryptCustom(String key, String iv, String plaintext,
      {String? padding}) {
    List<int> keyBytes = convResultMD5toBytes(key);
    List<int> ivBytes = convResultMD5toBytes(iv);

    final keyLength = keyBytes.length == 32 ? 32 : 16;
    final encrypter = encrypt.Encrypter(encrypt.AES(
      encrypt.Key(Uint8List.fromList(keyBytes.sublist(0, keyLength))),
      mode: encrypt.AESMode.cbc,
      padding: padding ?? 'PKCS7', // Specify padding here
    ));

    final ivFinal = encrypt.IV(Uint8List.fromList(ivBytes));

    final encrypted = encrypter.encrypt(plaintext, iv: ivFinal);
    Uint8List resultEncrypted = encrypted.bytes;
    String hexString = resultEncrypted.map((byte) {
      return byte.toRadixString(16).padLeft(2, '0'); // Convert each byte to hex
    }).join();
    return hexString;
  }

  List<int> convResultMD5toBytes(String resMD5) {
    List<int> bytes = [];
    for (int i = 0; i < resMD5.length; i += 2) {
      // Parse each pair of hex characters into a byte
      // print("$i ${resMD5.substring(i, i + 2)}");
      bytes.add(int.parse(resMD5.substring(i, i + 2), radix: 16));
    }

    return bytes;
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

class AESService {
  static const platform = MethodChannel('com.example.ble_test/aes');
  static Future<String> encrypt(
      String plaintext, List<int> key, List<int> iv) async {
    try {
      final encryptedText = await platform.invokeMethod('encrypt', {
        'plaintext': plaintext,
        'key': key,
        'iv': iv,
      });
      return encryptedText;
    } catch (e) {
      throw 'Encryption failed: $e';
    }
  }
}
