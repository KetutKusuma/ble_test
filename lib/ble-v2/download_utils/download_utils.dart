import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:ble_test/utils/snackbar.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloadUtils {
  static Future saveToDownload(BuildContext context, ScreenSnackbar ss,
      Uint8List data, String fileName) async {
    try {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      int androidVersion = androidInfo.version.sdkInt;
      log("version android : $androidVersion");

      if (androidVersion < 33) {
        if (!await Permission.storage.status.isGranted) {
          await Permission.storage.request();
        }
        if (await Permission.manageExternalStorage.isDenied) {
          await Permission.manageExternalStorage.request();
        }
        // Minta izin storage
        if (await Permission.storage.request().isDenied) {
          Snackbar.show(
            ss,
            "Izin penyimpanan ditolak",
            success: false,
          );
          return null;
        }
      }

      // Dapatkan path folder Download
      String path = await ExternalPath.getExternalStoragePublicDirectory(
          ExternalPath.DIRECTORY_DOWNLOADS);

      // buat folder
      Directory customDir = Directory("$path/Toppi");
      if (!customDir.existsSync()) {
        customDir.createSync(recursive: true);
      }

      String filePath = "${customDir.path}/$fileName";

      // Simpan file di folder Download
      File file = File(filePath);
      await file.writeAsBytes(data);

      bool ex = await file.exists();

      if (ex) {
        Snackbar.show(
          ss,
          "Berkas disimpan di: $filePath",
          success: true,
        );
      } else {
        Snackbar.show(
          ss,
          "Berkas gagal disimpan di: $filePath",
          success: false,
        );
      }
      return;
    } catch (e) {
      log("Error catch : $e");
      Snackbar.show(
        ss,
        "Gagal menyimpan gambar : $e",
        success: false,
      );
      return;
    }
  }
}
