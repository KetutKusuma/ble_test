import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/converter/settings/transmit_settings_convert.dart';
import 'package:ble_test/utils/converter/settings/upload_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

import '../../../utils/ble.dart';
import '../../../utils/snackbar.dart';

class TransmitSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  const TransmitSettingsScreen({super.key, required this.device});

  @override
  State<TransmitSettingsScreen> createState() => _TransmitSettingsScreenState();
}

class _TransmitSettingsScreenState extends State<TransmitSettingsScreen> {
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
      destinationEnableTxt = '-',
      destinationIdTxt = '-',
      transmitScheduleTxt = '-';
  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  bool isTransmitSettings = true;
  late SimpleFontelicoProgressDialog _progressDialog;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressDialog = SimpleFontelicoProgressDialog(
          context: context, barrierDimisable: true);
      _showLoading();
    });
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
    initGetRawTransmit();
    initDiscoverServices();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    isTransmitSettings = false;
    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
  }

  onRefresh() async {
    try {
      initGetRawTransmit();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawTransmit() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_transmit?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Transmit", device);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.transmitsettings, "Error get raw admin : $e",
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
        Snackbar.show(ScreenSnackbar.transmitsettings,
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
              if (characters.properties.notify && isTransmitSettings) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 35) {
                  List<dynamic> result =
                      TransmitSettingsConvert.convertTransmitSettings(_value);
                  _progressDialog.hide();

                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      destinationEnableTxt = result[1].toString();
                      destinationIdTxt = result[2].toString();
                      transmitScheduleTxt = result[3].toString();
                    });
                  }
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "destination_enable") {
                      destinationEnableTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "destination_id") {
                      destinationIdTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "transmit_schedule") {
                      transmitScheduleTxt = _setSettings.value;
                    }
                    Snackbar.show(ScreenSnackbar.transmitsettings,
                        "Success set ${_setSettings.setSettings}",
                        success: true);
                  } else {
                    Snackbar.show(ScreenSnackbar.transmitsettings,
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
      Snackbar.show(ScreenSnackbar.transmitsettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyTransmitSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transmit Settings'),
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
                    // Text("VALUE : $_value"),
                    SettingsContainer(
                      title: "Status",
                      data: statusTxt,
                      onTap: () {},
                      icon: const Icon(
                        CupertinoIcons.settings,
                      ),
                    ),
                    SettingsContainer(
                      title: "Destination Enable",
                      data: destinationEnableTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Destination ID",
                      data: destinationIdTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.perm_device_info_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Transmit Schedule",
                      data: transmitScheduleTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.calendar_today_outlined,
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
      Snackbar.show(ScreenSnackbar.transmitsettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.transmitsettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.transmitsettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.transmitsettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.transmitsettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.transmitsettings,
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
