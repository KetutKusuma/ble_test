import 'dart:convert';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/rtc.dart';
import 'package:ble_test/utils/crc32.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

class OCRBLE {
  Future<String> helperUploadImg(
    String url,
    List<int> data,
    String nameData,
  ) async {
    try {
      List<int> idBuffer = List.filled(5, 0);
      int timestamp = RTC.getSeconds();
      List<int> timestampBuffer = List<int>.filled(4, 0, growable: false);
      ConvertV2().insertUint32ToBuffer(timestamp, timestampBuffer, 0);

      int checksum = CRC32.compute(data);
      List<int> checksumBuffer = List<int>.filled(4, 0, growable: false);
      ConvertV2().insertUint32ToBuffer(checksum, checksumBuffer, 0);

      List<int> signatureInput = [
        ...idBuffer,
        ...timestampBuffer,
        ...checksumBuffer,
        ...InitConfig.data().md5Salt
      ];

      Digest signature = md5.convert(signatureInput);

      Map<String, String> headers = {
        "X-ID": _bytesToHex(idBuffer),
        "X-TIMESTAMP": timestamp.toString(),
        "X-CHECKSUM": checksum.toString(),
        "X-SIGNATURE": signature.toString(),
      };

      var request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll(headers);
      request.files.add(http.MultipartFile.fromBytes(
        'DATA',
        data,
        filename: nameData,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // return {
      //   "status": response.statusCode,
      //   "body": response.body,
      // };
      return response.body;
    } catch (e) {
      throw Exception("OCR request failed: $e");
    }
  }

  Future<String> ocr(
    String url,
    List<int> data,
  ) async {
    try {
      List<int> idBuffer = List.filled(5, 0);
      int timestamp = RTC.getSeconds();
      List<int> timestampBuffer = List<int>.filled(4, 0, growable: false);
      ConvertV2().insertUint32ToBuffer(timestamp, timestampBuffer, 0);

      int checksum = CRC32.compute(data);
      List<int> checksumBuffer = List<int>.filled(4, 0, growable: false);
      ConvertV2().insertUint32ToBuffer(checksum, checksumBuffer, 0);

      List<int> signatureInput = [
        ...idBuffer,
        ...timestampBuffer,
        ...checksumBuffer,
        ...InitConfig.data().md5Salt
      ];

      Digest signature = md5.convert(signatureInput);

      Map<String, String> headers = {
        "X-ID": _bytesToHex(idBuffer),
        "X-TIMESTAMP": timestamp.toString(),
        "X-CHECKSUM": checksum.toString(),
        "X-SIGNATURE": signature.toString(),
      };

      var request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll(headers);
      request.files.add(http.MultipartFile.fromBytes(
        'DATA',
        data,
        filename: 'image.jpg',
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // return {
      //   "status": response.statusCode,
      //   "body": response.body,
      // };
      return response.body;
    } catch (e) {
      throw Exception("OCR request failed: $e");
    }
  }

  static String formatResponse(String data) {
    try {
      // Try parsing as JSON
      var decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return "Status : ${decoded['Status']}\nResults : ${decoded['Results']}";
      }
    } catch (e) {
      // If parsing fails, treat it as an error string
      return "Kesalahan : $data";
    }

    return "Invalid data format";
  }

  String _bytesToHex(List<int> bytes) {
    return bytes
        .map((e) => e.toRadixString(16).padLeft(2, '0').toUpperCase())
        .join(':');
  }
}
