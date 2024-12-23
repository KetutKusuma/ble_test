import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum ScreenSnackbar {
  device,
  scan,
  login,
  blemain,
  adminsettings,
  bluetoothoff
}

class Snackbar {
  static final snackBarKeyDevice = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyScan = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyLogin = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyBleMain = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyAdminSettings = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyCaptureSettings = GlobalKey<ScaffoldMessengerState>();
  static final snackBluetoothOff = GlobalKey<ScaffoldMessengerState>();

  static GlobalKey<ScaffoldMessengerState> getSnackbar(ScreenSnackbar ss) {
    switch (ss) {
      case ScreenSnackbar.device:
        return snackBarKeyDevice;
      case ScreenSnackbar.scan:
        return snackBarKeyScan;
      case ScreenSnackbar.login:
        return snackBarKeyLogin;
      case ScreenSnackbar.blemain:
        return snackBarKeyBleMain;
      case ScreenSnackbar.adminsettings:
        return snackBarKeyAdminSettings;
      case ScreenSnackbar.bluetoothoff:
        return snackBluetoothOff;
    }
  }

  static show(ScreenSnackbar ss, String msg, {required bool success}) {
    final snackBar = success
        ? SnackBar(content: Text(msg), backgroundColor: Colors.blue)
        : SnackBar(content: Text(msg), backgroundColor: Colors.red);
    getSnackbar(ss).currentState?.removeCurrentSnackBar();
    getSnackbar(ss).currentState?.showSnackBar(snackBar);
  }

  static showA(GlobalKey<ScaffoldMessengerState> key, String msg,
      {required bool success}) {
    final snackBar = success
        ? SnackBar(content: Text(msg), backgroundColor: Colors.blue)
        : SnackBar(content: Text(msg), backgroundColor: Colors.red);
    key.currentState?.removeCurrentSnackBar();
    key.currentState?.showSnackBar(snackBar);
  }
}

String prettyException(String prefix, dynamic e) {
  if (e is FlutterBluePlusException) {
    return "$prefix ${e.description}";
  } else if (e is PlatformException) {
    return "$prefix ${e.message}";
  }
  return prefix + e.toString();
}
