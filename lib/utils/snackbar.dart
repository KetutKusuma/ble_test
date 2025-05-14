import 'package:ble_test/ble-v2/command/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum ScreenSnackbar {
  device,
  scan,
  login,
  blemain,
  bluetoothoff,
  adminsettings,
  capturesettings,
  metadatasettings,
  receivesettings,
  transmitsettings,
  uploadsettings,
  capture,
  setpassword,
  devicesettings,
  filescreen,
  storagescreen,
  devicescreen,
  batteryscreen,
  testradiotransmitscreen,

  /// for new login
  loginscreen,
  searchscreen,

  // v2
  logexplorerscreen,
  imageexplorerscreen,
  uploadlistscreen,

  // v3
  deviceconfigurationscreen
}

class Snackbar {
  static final snackBarKeyDevice = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyScan = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyLogin = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyBleMain = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyAdminSettings = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyCaptureSettings = GlobalKey<ScaffoldMessengerState>();
  static final snackBluetoothOff = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyMetadataSettings =
      GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyReceiveSettings = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyTransmitSettings =
      GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyUploadSettings = GlobalKey<ScaffoldMessengerState>();
  static final snackBarCapture = GlobalKey<ScaffoldMessengerState>();
  static final snackBarSetPassword = GlobalKey<ScaffoldMessengerState>();
  static final snackBarDeviceSettings = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyLoginScreen = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeySearchScreen = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyFileScreen = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyStorageScreen = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyDeviceScreen = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyBatteryScreen = GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyTestRadioTransmitScreen =
      GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyLogExplorerScreen =
      GlobalKey<ScaffoldMessengerState>();
  static final snackBarKeyImageExplorerScreen =
      GlobalKey<ScaffoldMessengerState>();
  static final snackBarListUploadScreen = GlobalKey<ScaffoldMessengerState>();
  static final snackBarDeviceConfiguration =
      GlobalKey<ScaffoldMessengerState>();

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
      case ScreenSnackbar.capturesettings:
        return snackBarKeyCaptureSettings;
      case ScreenSnackbar.metadatasettings:
        return snackBarKeyMetadataSettings;
      case ScreenSnackbar.receivesettings:
        return snackBarKeyReceiveSettings;
      case ScreenSnackbar.transmitsettings:
        return snackBarKeyTransmitSettings;
      case ScreenSnackbar.uploadsettings:
        return snackBarKeyUploadSettings;
      case ScreenSnackbar.capture:
        return snackBarCapture;
      case ScreenSnackbar.setpassword:
        return snackBarSetPassword;
      case ScreenSnackbar.devicesettings:
        return snackBarDeviceSettings;
      case ScreenSnackbar.loginscreen:
        return snackBarKeyLoginScreen;
      case ScreenSnackbar.searchscreen:
        return snackBarKeySearchScreen;
      case ScreenSnackbar.filescreen:
        return snackBarKeyFileScreen;
      case ScreenSnackbar.storagescreen:
        return snackBarKeyStorageScreen;
      case ScreenSnackbar.devicescreen:
        return snackBarKeyDeviceScreen;
      case ScreenSnackbar.batteryscreen:
        return snackBarKeyBatteryScreen;
      case ScreenSnackbar.testradiotransmitscreen:
        return snackBarKeyTestRadioTransmitScreen;
      case ScreenSnackbar.logexplorerscreen:
        return snackBarKeyLogExplorerScreen;
      case ScreenSnackbar.imageexplorerscreen:
        return snackBarKeyImageExplorerScreen;
      case ScreenSnackbar.uploadlistscreen:
        return snackBarListUploadScreen;
      case ScreenSnackbar.deviceconfigurationscreen:
        return snackBarDeviceConfiguration;
    }
  }

  static show(ScreenSnackbar ss, String msg, {required bool success}) {
    final snackBar = success
        ? SnackBar(content: Text(msg), backgroundColor: Colors.blue)
        : SnackBar(content: Text(msg), backgroundColor: Colors.red);
    getSnackbar(ss).currentState?.removeCurrentSnackBar();
    getSnackbar(ss).currentState?.showSnackBar(snackBar);
  }

  static showHelperV2(ScreenSnackbar ss, BLEResponse resBLE,
      {VoidCallback? onSuccess}) {
    final snackBar = resBLE.status
        ? SnackBar(content: Text(resBLE.message), backgroundColor: Colors.blue)
        : SnackBar(content: Text(resBLE.message), backgroundColor: Colors.red);
    if (resBLE.status) {
      Future.delayed(const Duration(milliseconds: 500), onSuccess);
    }
    getSnackbar(ss).currentState?.removeCurrentSnackBar();
    getSnackbar(ss).currentState?.showSnackBar(snackBar);
  }

  static showNotConnectedFalse(ScreenSnackbar ss,
      {String msg = "Device is not connected"}) {
    final snackBar = SnackBar(content: Text(msg), backgroundColor: Colors.red);
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
