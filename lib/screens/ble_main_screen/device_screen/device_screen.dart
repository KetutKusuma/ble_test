import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/ble_main_screen/device_screen/file_screen/file_screen.dart';
import 'package:ble_test/screens/ble_main_screen/device_screen/storage_screen/storage_screen.dart';
import 'package:ble_test/utils/converter/bytes_convert.dart';
import 'package:ble_test/utils/converter/settings/device_settings_convert.dart';
import 'package:ble_test/utils/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../utils/ble.dart';
import '../../../utils/enum/role.dart';
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
  String statusTxt = "-",
      timeTxt = "-",
      firmwareTxt = "-",
      versionTxt = "-",
      temperatureTxt = "-",
      battery1Txt = "-",
      battery2Txt = "-",
      critBattery1Counter = "-",
      critBattery2Counter = "-";

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
    initGetRawDeviceStatus();
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
      initGetRawDeviceStatus();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawDeviceStatus() async {
    try {
      List<int> list = [];
      Uint8List bytes = Uint8List(0);
      if (isConnected) {
        list = utf8.encode("raw_device_status?");
        bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Raw Device Status", device);
        isGetTime = true;
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.devicescreen, "Error get raw admin : $e",
          success: false);
    }
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (isConnected) {
      try {
        _services = await device.discoverServices();
        initLastValueSubscription(device);
      } catch (e) {
        Snackbar.show(ScreenSnackbar.devicescreen,
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
                if (_value.length > 40) {
                  _progressDialog.hide();
                  List<dynamic> result =
                      DeviceStatusConverter.converDeviceStatus(_value);
                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      firmwareTxt = result[1].toString();
                      versionTxt = result[2].toString();
                      timeTxt = result[3].toString();
                      temperatureTxt = result[4].toString();
                      battery1Txt = result[5].toString();
                      battery2Txt = result[6].toString();
                      critBattery1Counter = result[7].toString();
                      critBattery2Counter = result[8].toString();
                    });
                  }
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
          );
          // _lastValueSubscription.cancel();
        }
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.devicescreen, prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyDeviceScreen,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Device Status'),
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
                      title: "Firmware",
                      data: firmwareTxt.trim(),
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
                    SettingsContainer(
                      title: "Temperature",
                      data: "$temperatureTxt °C",
                      onTap: () {},
                      icon: const Icon(
                        Icons.thermostat,
                      ),
                    ),
                    SettingsContainer(
                      title: "Battery 1",
                      data: "$battery1Txt volt",
                      description: critBattery1Counter == "0" ||
                              critBattery1Counter == '-'
                          ? null
                          : "(Critical Counter : $critBattery1Counter)",
                      onTap: () {},
                      icon: const Icon(
                        Icons.battery_5_bar_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Battery 2",
                      data: "$battery2Txt volt",
                      description: critBattery2Counter == "0" ||
                              critBattery2Counter == '-'
                          ? null
                          : "(Critical Counter : $critBattery2Counter)",
                      onTap: () {},
                      icon: const Icon(
                        Icons.battery_full,
                      ),
                    ),
                    FeatureWidget(
                      visible: featureB.contains(roleUser),
                      title: "Storage",
                      onTap: () {
                        if (isConnected) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  StorageScreen(device: device),
                            ),
                          );
                        } else {
                          Snackbar.showNotConnectedFalse(
                              ScreenSnackbar.blemain);
                        }
                      },
                      icon: const Icon(
                        Icons.sd_storage_outlined,
                      ),
                    ),
                    FeatureWidget(
                      visible: featureB.contains(roleUser),
                      title: "Files",
                      onTap: () {
                        if (isConnected) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => FilesScreen(device: device),
                            ),
                          );
                        } else {
                          Snackbar.showNotConnectedFalse(
                              ScreenSnackbar.blemain);
                        }
                      },
                      icon: const Icon(
                        Icons.insert_drive_file_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Time",
                      data: timeTxt,
                      onTap: () async {},
                      icon: const Icon(
                        CupertinoIcons.time,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        DateTime subtraction =
                            DateTime.utc(2000, 1, 1, 0, 0, 0);
                        log("datetime fo subsctraction ${subtraction.millisecondsSinceEpoch ~/ 1000}");
                        DateTime dateTimeNow = DateTime.now()
                            .toUtc()
                            .add(const Duration(hours: 8));
                        int result =
                            (dateTimeNow.millisecondsSinceEpoch ~/ 1000) -
                                (subtraction.millisecondsSinceEpoch ~/ 1000);
                        log("result now $result");
                        List<int> list = utf8.encode("time=$result");
                        Uint8List bytes = Uint8List.fromList(list);

                        String dateTimeNowFormatted =
                            dateTimeNow.toIso8601String().split('.').first;
                        String displayDateTimeNow =
                            dateTimeNowFormatted.replaceFirst('T', ' ');

                        _setSettings = SetSettingsModel(
                          setSettings: "time",
                          // ini hasil pengurangna atau result
                          // value: DateTime.fromMillisecondsSinceEpoch(
                          //         result * 1000)
                          value: displayDateTimeNow,
                        );
                        BLEUtils.funcWrite(bytes, "Success Set Time", device);
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.only(left: 10, right: 10, top: 5),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        width: MediaQuery.of(context).size.width,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Colors.white,
                            ),
                            const SizedBox(
                              width: 5,
                            ),
                            Text(
                              "Set Time",
                              style: GoogleFonts.readexPro(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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

  // GET
  BluetoothDevice get device {
    return widget.device;
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }
}
