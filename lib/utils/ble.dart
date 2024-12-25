import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BLEUtils {
  static Future<void> funcWrite(
      Uint8List bytes, String msg, BluetoothDevice device) async {
    try {
      for (var service in device.servicesList) {
        for (var element in service.characteristics) {
          // log("characteristic : $element");
          if (element.properties.write && device.isConnected) {
            await element.write(bytes);
            log("message : $msg");
            // if (mounted) {
            //   Snackbar.show(ScreenSnackbar.login, msg, success: true);
            // }
            break;
          }
        }
      }
    } catch (e) {
      log("Error funcWrite : $e");
    }
  }
}
