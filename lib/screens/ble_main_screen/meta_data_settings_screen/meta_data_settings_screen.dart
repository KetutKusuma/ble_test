import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/converter/settings/meta_data_settings_convert.dart';
import 'package:ble_test/utils/converter/settings/upload_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

import '../../../utils/ble.dart';
import '../../../utils/snackbar.dart';

class MetaDataSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  const MetaDataSettingsScreen({super.key, required this.device});

  @override
  State<MetaDataSettingsScreen> createState() => _MetaDataSettingsScreenState();
}

class _MetaDataSettingsScreenState extends State<MetaDataSettingsScreen> {
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
      modelMeterTxt = '-',
      meterSnTxt = '-',
      meterSealTxt = '-',
      timeUTCTxt = '-';
  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  TextEditingController modelMeterTxtController = TextEditingController();
  TextEditingController meterSnTxtController = TextEditingController();
  TextEditingController meterSealTxtController = TextEditingController();
  TextEditingController timeUTCTxtController = TextEditingController();

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
    timeUTCTxtController.addListener(() {
      final text = timeUTCTxtController.text;
      if (text.isNotEmpty) {
        final value = int.tryParse(text);
        if (value != null) {
          if (value < -12) {
            // Otomatis set menjadi -12 jika kurang dari -12
           timeUTCTxtController.text = '-12';
           timeUTCTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: timeUTCTxtController
                        .text.length)); // Memastikan cursor di akhir
          } else if (value > 12) {
             // Otomatis set menjadi 12 jika lebih dari 12
            timeUTCTxtController.text = '12';
           timeUTCTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: timeUTCTxtController
                        .text.length)); // Memastikan cursor di akhir
          }
        }
      }
    });
    initGetRawMetaData();
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
      initGetRawMetaData();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawMetaData() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_meta_data?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Meta data", device);
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
        Snackbar.show(ScreenSnackbar.metadatasettings,
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
                if (_value.length > 45) {
                  List<dynamic> result =
                      MetaDataSettingsConvert.convertMetaDataSettings(_value);
                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      modelMeterTxt = result[1].toString();
                      meterSnTxt = result[2].toString();
                      meterSealTxt = result[3].toString();
                      timeUTCTxt = result[4].toString();
                    });
                  }
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "meter_model") {
                      _setSettings.value = modelMeterTxt;
                    } else if (_setSettings.setSettings == "meter_sn") {
                      _setSettings.value = meterSnTxt;
                    } else if (_setSettings.setSettings == "meter_seal") {
                      _setSettings.value = meterSealTxt;
                    } else if (_setSettings.setSettings == "time_utc") {
                      _setSettings.value = timeUTCTxt;
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
      Snackbar.show(ScreenSnackbar.metadatasettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

 Future<String?> _showInputDialog(
    TextEditingController controller, String field) async {
  String? input = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Enter Value $field" ),
        content: Form(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9 ]')), // Hanya huruf, angka, dan spasi
            ],
            decoration: InputDecoration(
              labelText: "Enter Valid $field",
              border: const OutlineInputBorder(),
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
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Input cannot be empty!")),
                );
              }
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );

  return input;
}

 Future<String?> _showInputDialogTimeUTC(
      TextEditingController controller) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Value Time UTC"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(signed: true, decimal: false),
              inputFormatters: [
                 FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,2}$')),
              ],
              decoration: const InputDecoration(
                labelText: 'Value between -12 and 12',
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

    return input;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyMetadataSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Meta Data Settings'),
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
                      title: "Model Meter",
                      data: modelMeterTxt,
                      onTap: () async {
                          String? input = await  _showInputDialog(
                              modelMeterTxtController, "Model Meter");
                          if (input != null && input.isNotEmpty) {
                            List<int> list = utf8.encode("meter_model=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "meter_model", value: input);
                            BLEUtils.funcWrite(
                                bytes, "Success Set Model Meter", device);
                          }
                        },
                      icon: const Icon(
                        Icons.compass_calibration_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Meter SN",
                      data: meterSnTxt,
                     onTap: () async {
                        String? input = await _showInputDialog(
                            meterSnTxtController, "Meter Sn");
                        if (input != null && input.isNotEmpty) {
                          List<int> list = utf8.encode("meter_sn=$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          _setSettings = SetSettingsModel(
                              setSettings: "meter_sn", value: input);
                          BLEUtils.funcWrite(
                              bytes, "Success Set Meter Sn", device);
                        }
                      },
                      icon: const Icon(
                        Icons.podcasts_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Meter Seal",
                      data: meterSealTxt,
                        onTap: () async {
                        String? input = await _showInputDialog(
                            meterSealTxtController,"Meter Seal");
                        if (input != null && input.isNotEmpty) {
                          List<int> list = utf8.encode("meter_seal=$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          _setSettings = SetSettingsModel(
                              setSettings: "meter_seal", value: input);
                          BLEUtils.funcWrite(
                              bytes, "Success Set Meter Seal", device);
                        }
                      },
                      icon: const Icon(
                        Icons.upload_file,
                      ),
                    ),
                    SettingsContainer(
                      title: "Time UTC",
                      data: timeUTCTxt,
                       onTap: () async {
                        String? input = await _showInputDialogTimeUTC(
                            timeUTCTxtController);
                        if (input != null) {
                          List<int> list = utf8.encode("time_utc=$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          _setSettings = SetSettingsModel(
                              setSettings: "timeutc", value: input);
                          BLEUtils.funcWrite(
                              bytes, "Success Set Time UTC", device);
                        }
                      },
                      icon: const Icon(
                        Icons.upload_rounded,
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
      Snackbar.show(ScreenSnackbar.metadatasettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.metadatasettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.metadatasettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.metadatasettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.metadatasettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.metadatasettings,
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
