import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/ble-v2/model/image_meta_data_model/image_meta_data_model.dart';
import 'package:ble_test/ble-v2/utils/config.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/ble-v2/utils/rtc.dart';
import 'package:ble_test/utils/crc32.dart';
import 'package:ble_test/utils/global.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class ToServer {
  Future<String> _getVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    String versionApp = packageInfo.version;
    return versionApp;
  }

  Future<http.Response> postRequest(
    String url,
    List<int> data,
    ImageMetaDataModel imageMetaData,
  ) async {
    try {
      int timestamp = RTC.getSeconds();
      List<int> timestampBuffer = List<int>.filled(4, 0, growable: false);
      ConvertV2().insertUint32ToBuffer(timestamp, timestampBuffer, 0);

      int checksum = CRC32.compute(data);
      List<int> checksumBuffer = List<int>.filled(4, 0, growable: false);
      ConvertV2().insertUint32ToBuffer(checksum, checksumBuffer, 0);

      // # ini untuk handle versi v2.21
      String version = await _getVersion();
      String fileName = ConvertV2().arrayUint8ToStringHexAddress(
        (imageMetaData.id ?? []),
      ); // ini untuk requestID

      int utc = RTC.getTimeUTC();
      // ### ---- ###

      // log("list-> appName : ${appName.codeUnits}, version : ${version.codeUnits}, filename : ${fileName.codeUnits}, id : ${imageMetaData.id}, timestamp : ${timestampBuffer}, utc : ${utc.toString().codeUnits}, checksum : ${checksumBuffer}, md5Salt : ${InitConfig.data().md5Salt}");
      List<int> signatureInput = [
        ...appName.codeUnits, // v2.21
        ...version.codeUnits, // v2.21
        ...fileName.codeUnits, // v2.21
        ...imageMetaData.id ?? [],
        ...timestampBuffer,
        ...[utc], // v2.21
        ...checksumBuffer,
        ...InitConfig.data().md5Salt
      ];

      Digest signature = md5.convert(signatureInput);

      Map<String, String> headers = {
        "X-FIRMWARE": appName,
        "X-VERSION": version,
        "X-REQUEST-ID": fileName, // nama filenya
        "X-TOPPI-ID": _bytesToHex(imageMetaData.id ?? []),
        "X-TIMESTAMP": timestamp.toString(),
        "X-UTC": utc.toString(),
        "X-CHECKSUM": checksum.toString(),
        "X-SIGNATURE": signature.toString(),
      };

      var request = http.MultipartRequest("POST", Uri.parse(url));
      request.headers.addAll(headers);
      request.files.add(
        http.MultipartFile.fromBytes(
          'Data',
          data,
          filename: fileName,
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      return response;
    } catch (e) {
      throw Exception("OCR request failed: $e");
    }
  }

  // Future<String> ocr(
  //     String url, List<int> data, ImageMetaDataModel imageMetaData) async {
  //   try {
  //     int timestamp = RTC.getSeconds();
  //     List<int> timestampBuffer = List<int>.filled(4, 0, growable: false);
  //     ConvertV2().insertUint32ToBuffer(timestamp, timestampBuffer, 0);

  //     int checksum = CRC32.compute(data);
  //     List<int> checksumBuffer = List<int>.filled(4, 0, growable: false);
  //     ConvertV2().insertUint32ToBuffer(checksum, checksumBuffer, 0);

  //     // # ini untuk handle versi v2.21
  //     String version = await _getVersion();
  //     String fileName = ConvertV2().arrayUint8ToStringHexAddress(
  //       (imageMetaData.id ?? []),
  //     ); // ini untuk requestID

  //     int utc = RTC.getTimeUTC();
  //     // ### ---- ###

  //     List<int> signatureInput = [
  //       ...appName.codeUnits,
  //       ...version.codeUnits,
  //       ...fileName.codeUnits,
  //       ...imageMetaData.id ?? [],
  //       ...timestampBuffer,
  //       ...utc.toString().codeUnits,
  //       ...checksumBuffer,
  //       ...InitConfig.data().md5Salt
  //     ];

  //     Digest signature = md5.convert(signatureInput);

  //     Map<String, String> headers = {
  //       "X-FIRMWARE": appName,
  //       "X-VERSION": version,
  //       "X-REQUEST-ID": fileName, // nama filenya
  //       "X-TOPPI-ID": _bytesToHex(imageMetaData.id ?? []),
  //       "X-TIMESTAMP": timestamp.toString(),
  //       "X-UTC": utc.toString(),
  //       "X-CHECKSUM": checksum.toString(),
  //       "X-SIGNATURE": signature.toString(),
  //     };

  //     var request = http.MultipartRequest("POST", Uri.parse(url));
  //     request.headers.addAll(headers);
  //     request.files.add(http.MultipartFile.fromBytes(
  //       'DATA',
  //       data,
  //       filename: fileName,
  //     ));

  //     var streamedResponse = await request.send();
  //     var response = await http.Response.fromStream(streamedResponse);

  //     // return {
  //     //   "status": response.statusCode,
  //     //   "body": response.body,
  //     // };
  //     return response.body;
  //   } catch (e) {
  //     throw Exception("OCR request failed: $e");
  //   }
  // }

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
