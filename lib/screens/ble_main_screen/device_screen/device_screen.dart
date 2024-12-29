import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/utils/converter/bytes_convert.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

import '../../../utils/ble.dart';
import '../../../utils/converter/status/status.dart';
import '../../../utils/snackbar.dart';
import '../admin_settings_screen/admin_settings_screen.dart';

class DeviceScreen extends StatefulWidget {
  final BluetoothDevice device;

  const DeviceScreen({super.key, required this.device});

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  StreamSubscription<List<int>>? _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];
  final RefreshController _refreshController = RefreshController();
  String statusTxt = "-", timeTxt = "-", firmwareTxt = "-", versionTxt = "-";

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  bool isDeviceScreen = true;
  late SimpleFontelicoProgressDialog _progressDialog;
  TextEditingController spCaptureDateTxtController = TextEditingController();
  bool isGetTime = false;
  bool isGetFirmware = false;
  bool isGetVersion = false;

  @override
  void initState() {
    // TODO: implement initState
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
          Navigator.popUntil(
            context,
            (route) => route.isFirst,
          );
        }
        if (mounted) {
          setState(() {});
        }
      },
    );
    initGetDevice();
    initDiscoverServices();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    isDeviceScreen = false;
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
  }

  onRefresh() async {
    try {
      initGetDevice();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetDevice() async {
    try {
      List<int> list = [];
      Uint8List bytes = Uint8List(0);
      if (isConnected) {
        list = utf8.encode("time?");
        bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Time", device);
        isGetTime = true;

        await Future.delayed(const Duration(seconds: 3));
        list = utf8.encode("firmware?");
        bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Firmware", device);
        isGetFirmware = true;

        await Future.delayed(const Duration(seconds: 3));
        list = utf8.encode("version?");
        bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Version", device);
        isGetVersion = true;
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings, "Error get raw admin : $e",
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
              if (characters.properties.notify && isDeviceScreen) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");
                if (isGetTime) {
                  isGetTime = false;
                  int timeInt = BytesConvert.bytesToInt32(
                    _value,
                  );
                  timeTxt = DateTime.fromMillisecondsSinceEpoch(timeInt * 1000)
                      .toString();
                }

                if (isGetFirmware) {
                  isGetFirmware = false;
                  firmwareTxt = BytesConvert.bytesToString(_value);
                }

                if (isGetVersion) {
                  isGetVersion = false;
                  versionTxt = BytesConvert.bytesToString(_value);
                }

                if (timeTxt != '-' && firmwareTxt != '-' && versionTxt != '-') {
                  _progressDialog.hide();
                }

                log("value : ${value.length} && value[0] : ${value[0]}");
                if (_value.length == 1 && _value[0] == 1) {
                  if (_setSettings.setSettings == "time") {
                    timeTxt = _setSettings.value;
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

  Future<DateTime?> selectDateTime(BuildContext context) async {
    // Select Date
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      // Select Time
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime != null) {
        // Combine Date and Time
        return DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
      }
    }
    // Return null if either date or time selection is canceled
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Device'),
          elevation: 0,
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
                      SettingsContainer(
                        title: "Time",
                        data: timeTxt,
                        onTap: () async {
                          DateTime? input = await selectDateTime(context);
                          if (input != null) {
                            int secondsInput =
                                input.millisecondsSinceEpoch ~/ 1000;
                            List<int> list = utf8.encode("time=$secondsInput");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "time", value: input.toString());
                            BLEUtils.funcWrite(
                                bytes, "Success Set Time", device);
                          }
                        },
                        icon: const Icon(
                          CupertinoIcons.time,
                        ),
                      ),
                      SettingsContainer(
                        title: "Firmware",
                        data: firmwareTxt,
                        onTap: () {},
                        icon: const Icon(
                          Icons.memory_rounded,
                        ),
                      ),
                      SettingsContainer(
                        title: "Version",
                        data: versionTxt,
                        onTap: () {},
                        icon: const Icon(
                          Icons.settings_suggest_outlined,
                        ),
                      ),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
