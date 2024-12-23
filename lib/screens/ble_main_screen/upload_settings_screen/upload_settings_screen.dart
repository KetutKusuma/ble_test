import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/converter/settings/upload_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../utils/ble.dart';
import '../../../utils/snackbar.dart';

class UploadSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  const UploadSettingsScreen({super.key, required this.device});

  @override
  State<UploadSettingsScreen> createState() => _UploadSettingsScreenState();
}

class _UploadSettingsScreenState extends State<UploadSettingsScreen> {
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  final bool _isConnecting = false;
  final bool _isDisconnecting = false;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  StreamSubscription<List<int>>? _lastValueSubscription;

  // ignore: unused_field
  List<BluetoothService> _services = [];
  List<int> _value = [];
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String statusTxt = '-',
      serverTxt = '-',
      portTxt = '-',
      uploadEnableTxt = '-',
      uploadScheduleTxt = '-',
      uploadUsingTxt = '-',
      uploadInitialDelayTxt = '-',
      wifiSsidTxt = '-',
      wifiPasswordTxt = '-',
      modemApnTxt = '-';
  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    initGetRawUpload();
    initDiscoverServices();
  }

  @override
  void dispose() {
    super.dispose();
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
  }

  onRefresh() async {
    try {
      initGetRawUpload();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawUpload() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_capture?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Admin", device);
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
              if (characters.properties.notify) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 16) {
                  List<dynamic> result =
                      UploadSettingsConverter.convertUploadSettings(_value);
                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      serverTxt = result[1].toString();
                      portTxt = result[2].toString();
                      uploadEnableTxt = result[3].toString();
                      uploadScheduleTxt = result[4].toString();
                      uploadUsingTxt = result[5].toString();
                      uploadInitialDelayTxt = result[6].toString();
                      wifiSsidTxt = result[7].toString();
                      wifiPasswordTxt = result[8].toString();
                      modemApnTxt = result[9].toString();
                    });
                  }
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "server") {
                      serverTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "port") {
                      portTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "upload_enable") {
                      uploadEnableTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "upload_schedule") {
                      uploadScheduleTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "upload_using") {
                      uploadUsingTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "upload_initial_delay") {
                      uploadInitialDelayTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "wifi_ssid") {
                      wifiSsidTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "wifi_password") {
                      wifiPasswordTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "modem_apn") {
                      modemApnTxt = _setSettings.value;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Settings'),
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
                    title: "Server",
                    data: serverTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.compass_calibration_rounded,
                    ),
                  ),
                  SettingsContainer(
                    title: "Port",
                    data: portTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.podcasts_rounded,
                    ),
                  ),
                  SettingsContainer(
                    title: "Upload Enable",
                    data: uploadEnableTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.upload_file,
                    ),
                  ),
                  SettingsContainer(
                    title: "Upload Using",
                    data: uploadUsingTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.upload_rounded,
                    ),
                  ),
                  SettingsContainer(
                    title: "Upload Initial Delay",
                    data: uploadInitialDelayTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.vertical_align_top_rounded,
                    ),
                  ),
                  SettingsContainer(
                    title: "Wifi SSID",
                    data: wifiSsidTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.wifi_rounded,
                    ),
                  ),
                  SettingsContainer(
                    title: "Wifi Password",
                    data: wifiPasswordTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.wifi_password_rounded,
                    ),
                  ),
                  SettingsContainer(
                    title: "Modem Wifi APN",
                    data: modemApnTxt,
                    onTap: () {},
                    icon: const Icon(
                      Icons.wifi_tethering_error,
                    ),
                  ),
                ],
              ),
            )
          ],
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
