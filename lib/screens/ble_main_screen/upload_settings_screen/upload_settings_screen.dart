import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/converter/settings/upload_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final List<Map<String, dynamic>> listMapUploadUsing = [
    {"title": "Wifi", "value": 0},
    {"title": "Sim800l", "value": 1},
    {"title": "NB-Iot", "value": 2},
  ];

  bool isUploadSettings = true;

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
    initGetRawUpload();
    initDiscoverServices();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    isUploadSettings = false;
    super.dispose();
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
        List<int> list = utf8.encode("raw_upload?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Upload", device);
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
        Snackbar.show(ScreenSnackbar.uploadsettings,
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
              if (characters.properties.notify && isUploadSettings) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 100) {
                  List<dynamic> result =
                      UploadSettingsConverter.convertUploadSettings(_value);
                  if (mounted) {
                    log("result[1]: '${result[1]}', ${result[1].trim().length} ${result[1].isEmpty}");
                    setState(() {
                      statusTxt = result[0].toString();
                      serverTxt = "${result[1]}";
                      portTxt = result[2].toString();
                      uploadEnableTxt = result[3].toString();
                      uploadScheduleTxt = result[4].toString();
                      uploadUsingTxt = result[5] == 0
                          ? "Wifi"
                          : result[5] == 1
                              ? "Sim800l"
                              : result[5] == 2
                                  ? "NB-IoT"
                                  : "Error";
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
                      uploadUsingTxt = _setSettings.value == "0"
                          ? "Wifi"
                          : _setSettings.value == "1"
                              ? "Sim800l"
                              : _setSettings.value == "2"
                                  ? "NB-IoT"
                                  : "Error";
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
      Snackbar.show(ScreenSnackbar.uploadsettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future<String?> _showInputDialog(
      TextEditingController controller, String title,
      {List<TextInputFormatter>? inputFormatters}) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter Value $title"),
          content: Form(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Enter Value",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              inputFormatters: inputFormatters,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty && controller.text.length > 12) {
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

  Future<bool?> _showTrueFalseDialog(BuildContext context, String msg) async {
    bool? selectedValue = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(msg),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, true); // Return true
              },
              child: const Text('True'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, false); // Return false
              },
              child: const Text('False'),
            ),
          ],
        );
      },
    );

    return selectedValue;
  }

  Future<Map?> _showSelectionPopup(
      BuildContext context, List<Map<String, dynamic>> dataMap) async {
    Map? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select an Option'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: dataMap.map((item) {
              return ListTile(
                title: Text(item['title']),
                onTap: () {
                  Navigator.of(context).pop(item); // Return the selected item
                },
              );
            }).toList(),
          ),
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyUploadSettings,
      child: Scaffold(
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
                      onTap: () async {
                        try {
                          String? input =
                              await _showInputDialog(controller, "Server");
                          if (input != null) {
                            List<int> list = utf8.encode("server=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings.setSettings = "server";
                            _setSettings.value = input;
                            BLEUtils.funcWrite(
                                bytes, "Success Set Server", device);
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on server : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.compass_calibration_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Port",
                      data: portTxt,
                      onTap: () async {
                        try {
                          String? input = await _showInputDialog(
                              controller, "Upload Port", inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ]);
                          if (input != null) {
                            List<int> list = utf8.encode("port=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings.setSettings = "port";
                            _setSettings.value = input;
                            BLEUtils.funcWrite(
                                bytes, "Success Set Upload Port", device);
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on upload Port : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.podcasts_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Upload Enable",
                      data: uploadEnableTxt,
                      onTap: () async {
                        try {
                          bool? input = await _showTrueFalseDialog(
                              context, "Upload Enable");
                          if (input != null) {
                            List<int> list =
                                utf8.encode("upload_enable=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes, "Success Set Upload Enable", device);
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on upload enable : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.upload_file,
                      ),
                    ),
                    SettingsContainer(
                      title: "Upload Using",
                      data: uploadUsingTxt,
                      onTap: () async {
                        try {
                          Map? input = await _showSelectionPopup(
                              context, listMapUploadUsing);
                          if (input != null) {
                            List<int> list =
                                utf8.encode("port=${input['value']}");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings.setSettings = "upload_using";
                            _setSettings.value = input['value'].toString();
                            BLEUtils.funcWrite(
                                bytes, "Success Set Upload Using", device);
                          }
                        } catch (e) {
                          Snackbar.show(ScreenSnackbar.uploadsettings,
                              "Error click on upload using : $e",
                              success: false);
                        }
                      },
                      icon: const Icon(
                        Icons.upload_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Upload Initial Delay",
                      data: uploadInitialDelayTxt,
                      onTap: () async {
                        try {
                          String? input = await _showInputDialog(
                              controller, "Upload Initial Delay",
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ]);
                          if (input != null) {
                            List<int> list =
                                utf8.encode("upload_initial_delay=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings.setSettings = "upload_initial_delay";
                            _setSettings.value = input;
                            BLEUtils.funcWrite(bytes,
                                "Success Set Upload Initial Delay", device);
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on upload initial delay : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.vertical_align_top_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Wifi SSID",
                      data: wifiSsidTxt,
                      onTap: () async {
                        try {
                          String? input =
                              await _showInputDialog(controller, "Wifi SSID");
                          if (input != null) {
                            List<int> list = utf8.encode("wifi_ssid=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings.setSettings = "wifi_ssid";
                            _setSettings.value = input;
                            BLEUtils.funcWrite(
                                bytes, "Success Set Wifi SSID", device);
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on wifi ssid : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.wifi_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Wifi Password",
                      data: wifiPasswordTxt,
                      onTap: () async {
                        try {
                          String? input = await _showInputDialog(
                              controller, "Wifi Password");
                          if (input != null) {
                            List<int> list =
                                utf8.encode("wifi_password=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings.setSettings = "wifi_password";
                            _setSettings.value = input;
                            BLEUtils.funcWrite(
                                bytes, "Success Set Wifi Password", device);
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on wifi password : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.wifi_password_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Modem APN",
                      data: modemApnTxt,
                      onTap: () async {
                        try {
                          String? input =
                              await _showInputDialog(controller, "Modem APN");
                          if (input != null) {
                            List<int> list = utf8.encode("modem_apn=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings.setSettings = "modem_apn";
                            _setSettings.value = input;
                            BLEUtils.funcWrite(
                                bytes, "Success Set Modem APN", device);
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on modem apn : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.wifi_tethering_error,
                      ),
                    ),
                    const SizedBox(
                      height: 15,
                    )
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
      Snackbar.show(ScreenSnackbar.uploadsettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(
            ScreenSnackbar.uploadsettings, prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.uploadsettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.uploadsettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.uploadsettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.uploadsettings,
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
