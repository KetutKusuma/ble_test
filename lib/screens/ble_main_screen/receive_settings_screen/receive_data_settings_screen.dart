import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/converter/settings/receive_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../utils/ble.dart';
import '../../../utils/snackbar.dart';

class ReceiveDataSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  const ReceiveDataSettingsScreen({super.key, required this.device});

  @override
  State<ReceiveDataSettingsScreen> createState() =>
      _ReceiveDataSettingsScreenState();
}

class _ReceiveDataSettingsScreenState extends State<ReceiveDataSettingsScreen> {
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
      receiveEnableTxt = '-',
      receiveScheduleTxt = '-',
      receiveIntervalTxt = '-',
      receiveCountTxt = '-',
      receiveTimeAdjust = '-';
  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  TextEditingController receiveEnableTxtController = TextEditingController();
  TextEditingController receiveScheduleTxtController = TextEditingController();
  TextEditingController receiveIntervalTxtController = TextEditingController();
  TextEditingController receiveCountTxtController = TextEditingController();
  TextEditingController  receiveTimeAdjustTxtController = TextEditingController();

  @override
  void initState() {
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
    initGetRawReceive();
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
      initGetRawReceive();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawReceive() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_receive?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Receive", device);
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
        Snackbar.show(ScreenSnackbar.receivesettings,
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
                if (_value.length > 7) {
                  List<dynamic> result =
                      ReceiveSettingsConvert.convertReceiveSettings(_value);
                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      receiveEnableTxt = result[1].toString();
                      receiveScheduleTxt = result[2].toString();
                      receiveIntervalTxt = result[3].toString();
                      receiveCountTxt = result[4].toString();
                      receiveTimeAdjust = result[5].toString();
                    });
                  }
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "receive_enable") {
                      receiveEnableTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "receive_schedule") {
                      receiveScheduleTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "receive_interval") {
                      receiveIntervalTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "receive_count") {
                      receiveCountTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "receive_time_adjust") {
                      receiveTimeAdjust = _setSettings.value;
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
      Snackbar.show(ScreenSnackbar.receivesettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyReceiveSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Receive Settings'),
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
                      title: "Receive Enable",
                      data: receiveEnableTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.compass_calibration_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Receive Schedule",
                      data: receiveScheduleTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.podcasts_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Receive Interval",
                      data: receiveIntervalTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.upload_file,
                      ),
                    ),
                    SettingsContainer(
                      title: "Receive Count",
                      data: receiveCountTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.upload_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Receive Time Adjust",
                      data: receiveTimeAdjust,
                      onTap: () {},
                      icon: const Icon(
                        Icons.vertical_align_top_rounded,
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
      Snackbar.show(ScreenSnackbar.receivesettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.receivesettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.receivesettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.receivesettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.receivesettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.receivesettings,
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
