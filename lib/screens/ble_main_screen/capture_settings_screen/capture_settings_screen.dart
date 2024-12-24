import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/converter/settings/capture_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../admin_settings_screen/admin_settings_screen.dart';

class CaptureSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;

  const CaptureSettingsScreen({super.key, required this.device});

  @override
  State<CaptureSettingsScreen> createState() => _CaptureSettingsScreenState();
}

class _CaptureSettingsScreenState extends State<CaptureSettingsScreen> {
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  final bool _isConnecting = false;
  final bool _isDisconnecting = false;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  StreamSubscription<List<int>>? _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];
  final RefreshController _refreshController = RefreshController();
  String statusTxt = "-",
      captureScheduleTxt = "-",
      captureIntervalTxt = "-",
      captureCountTxt = '-',
      captureRecentLimitTxt = '-',
      spCaptureDateTxt = '-', // bit operation
      spCaptureScheduleTxt = '-',
      spCaptrueIntervalTxt = '-',
      spCaptureCountTxt = '-';

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  bool isCaptureSettings = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _connectionStateSubscription = device.connectionState.listen(
      (state) async {
        _connectionState = state;
        if (_connectionState == BluetoothConnectionState.disconnected) {
          Navigator.pop(
            context,
          );
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
    initGetRawCapture();
    initDiscoverServices();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    isCaptureSettings = false;
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    super.dispose();
  }

  onRefresh() async {
    try {
      initGetRawCapture();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawCapture() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_capture?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Capture", device);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.adminsettings, "Error get raw admin : $e",
          success: false);
    }
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(seconds: 4));
    if (isConnected) {
      try {
        _services = await device.discoverServices();
        initLastValueSubscription(device);
      } catch (e) {
        Snackbar.show(ScreenSnackbar.capturesettings,
            prettyException("Discover Services Error:", e),
            success: false);
        log(e.toString());
      }
      if (mounted) {
        setState(() {});
      }
    }
  }

  initLastValueSubscription(BluetoothDevice device) {
    try {
      for (var service in device.servicesList) {
        for (var characters in service.characteristics) {
          _lastValueSubscription = characters.lastValueStream.listen(
            (value) {
              if (characters.properties.notify && isCaptureSettings) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 16) {
                  List<dynamic> result =
                      CaptureSettingsConverter.convertCaptureSettings(_value);
                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      captureScheduleTxt = result[1].toString();
                      captureIntervalTxt = result[2].toString();
                      captureCountTxt = result[3].toString();
                      captureRecentLimitTxt = (result[4]).toString();
                      spCaptureDateTxt = (result[5]).toString();
                      spCaptureScheduleTxt = (result[6]).toString();
                      spCaptrueIntervalTxt = result[7].toString();
                      spCaptureCountTxt = result[8].toString();
                    });
                  }
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "capture_schedule") {
                      captureScheduleTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "capture_interval") {
                      captureIntervalTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "capture_count") {
                      captureCountTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "capture_recent_limit") {
                      captureRecentLimitTxt = _setSettings.value;
                    }
                    Snackbar.show(ScreenSnackbar.adminsettings,
                        "Success set ${_setSettings.setSettings}",
                        success: true);
                  } else {
                    Snackbar.show(ScreenSnackbar.adminsettings,
                        "Failed set ${_setSettings.setSettings}",
                        success: false);
                  }
                }

                if (mounted) {
                  setState(() {});
                }
              }
            },
            cancelOnError: true,
          );
          // _lastValueSubscription.cancel();
        }
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future<String?> _showInputDialog(
      TextEditingController controller, String inputTitle) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Value $inputTitle"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Enter a value',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                  controller.clear();
                } else {}
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyCaptureSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Capture Settings'),
          elevation: 0,
          actions: [
            Row(
              children: [
                if (_isConnecting || _isDisconnecting) buildSpinner(context),
                TextButton(
                  onPressed: _isConnecting
                      ? onCancelPressed
                      : (isConnected ? onDisconnectPressed : onConnectPressed),
                  child: Text(
                    _isConnecting
                        ? "CANCEL"
                        : (isConnected ? "DISCONNECT" : "CONNECT"),
                    style: Theme.of(context)
                        .primaryTextTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white),
                  ),
                )
              ],
            ),
          ],
        ),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Text("VALUE : $_value"),
                    SettingsContainer(
                      title: "Status",
                      data: statusTxt,
                      onTap: () {},
                      icon: const Icon(
                        CupertinoIcons.settings,
                      ),
                    ),
                    SettingsContainer(
                      title: "Capture Schedule",
                      data: captureScheduleTxt,
                      onTap: () async {
                        if (isConnected) {
                          String? input = await _showInputDialog(
                              controller, "Capture Schedule");
                          if (input != null) {
                            _setSettings.setSettings = "capture_schedule";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("capture_schedule=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes, "Success Set Capture Schedule", device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Capture Interval",
                      data: captureIntervalTxt,
                      onTap: () async {
                        if (isConnected) {
                          String? input = await _showInputDialog(
                              controller, "Capture Interval");
                          if (input != null) {
                            _setSettings.setSettings = "capture_interval";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("capture_interval=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes, "Success Set Capture Interval", device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.trending_up_sharp,
                      ),
                    ),
                    SettingsContainer(
                      title: "Capture Count",
                      data: captureCountTxt,
                      onTap: () async {
                        if (isConnected) {
                          String? input = await _showInputDialog(
                              controller, "Capture Count");
                          if (input != null) {
                            _setSettings.setSettings = "capture_count";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("capture_count=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes, "Success Set Capture Count", device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.looks_3_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Capture Recent Limit",
                      data: captureRecentLimitTxt,
                      onTap: () async {
                        if (isConnected) {
                          String? input = await _showInputDialog(
                              controller, "Capture Recent Limit");
                          if (input != null) {
                            _setSettings.setSettings = "capture_recent_limit";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("capture_recent_limit=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(bytes,
                                "Success Set Capture Recent Limit", device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.switch_camera_outlined,
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// ===== for connection ===================

  Widget buildSpinner(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(14.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: CircularProgressIndicator(
          backgroundColor: Colors.black12,
          color: Colors.black26,
        ),
      ),
    );
  }

  Future onConnectPressed() async {
    try {
      await device.connectAndUpdateStream();
      // initDiscoverServices();
      Snackbar.show(ScreenSnackbar.capturesettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.capturesettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.capturesettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.capturesettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.capturesettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings,
          prettyException("Disconnect Error:", e),
          success: false);
      log(e.toString());
    }
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
