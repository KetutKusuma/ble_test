import 'dart:async';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_set.dart';
import 'package:ble_test/ble-v2/model/device_status_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
import 'package:ble_test/screens/ble_main_screen/device_screen/file_screen/file_screen.dart';
import 'package:ble_test/screens/ble_main_screen/device_screen/storage_screen/storage_screen.dart';
import 'package:ble_test/utils/global.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
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
  late BLEProvider bleProvider;
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  final RefreshController _refreshController = RefreshController();
  String timeTxt = "-",
      firmwareTxt = "-",
      versionTxt = "-",
      temperatureTxt = "-",
      battery1Txt = "-",
      battery2Txt = "-",
      critBattery1Counter = "-",
      critBattery2Counter = "-";

  TextEditingController controller = TextEditingController();
  late SimpleFontelicoProgressDialog _progressDialog;
  TextEditingController spCaptureDateTxtController = TextEditingController();
  final _commandSet = CommandSet();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
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
    initGetDeviceStatus();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();

    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
  }

  onRefresh() async {
    try {
      initGetDeviceStatus();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetDeviceStatus() async {
    try {
      BLEResponse<DeviceStatusModels> resDeviceStatus =
          await Command().getDeviceStatus(device, bleProvider);
      log("hasil get device status : $resDeviceStatus");
      _progressDialog.hide();
      if (resDeviceStatus.status) {
        timeTxt =
            ConvertTime.dateFormatDateTime(resDeviceStatus.data!.dateTime!);
        firmwareTxt = resDeviceStatus.data!.firmwareModel!.name;
        versionTxt = resDeviceStatus.data!.firmwareModel!.version;
        temperatureTxt = resDeviceStatus.data!.temperature.toString();
        battery1Txt = resDeviceStatus.data!.batteryVoltageModel!.batteryVoltage1
            .toStringAsFixed(2);

        battery2Txt = resDeviceStatus.data!.batteryVoltageModel!.batteryVoltage2
            .toStringAsFixed(2);

        critBattery1Counter = "0";
        critBattery2Counter = "0";
        setState(() {});
      } else {
        Snackbar.show(
          ScreenSnackbar.devicescreen,
          resDeviceStatus.message,
          success: false,
        );
      }
    } catch (e) {
      Snackbar.show(
        ScreenSnackbar.devicescreen,
        "Dapat error status perangkat : $e",
        success: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyDeviceScreen,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Status Perangkat'),
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
                      title: "Perangkat Tertanam",
                      data: firmwareTxt.trim(),
                      onTap: () {},
                      icon: const Icon(
                        Icons.memory_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Versi",
                      data: versionTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.settings_suggest_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Temperatur",
                      data: "$temperatureTxt °C",
                      onTap: () {},
                      icon: const Icon(
                        Icons.thermostat,
                      ),
                    ),
                    SettingsContainer(
                      title: "Baterai 1",
                      data: "$battery1Txt volt",
                      description: critBattery1Counter == "0" ||
                              critBattery1Counter == '-'
                          ? null
                          : "(Jumlah hitungan kritis : $critBattery1Counter)",
                      onTap: () {},
                      icon: const Icon(
                        Icons.battery_5_bar_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Baterai 2",
                      data: "$battery2Txt volt",
                      description: critBattery2Counter == "0" ||
                              critBattery2Counter == '-'
                          ? null
                          : "(Jumlah hitungan kritis : $critBattery2Counter)",
                      onTap: () {},
                      icon: const Icon(
                        Icons.battery_full,
                      ),
                    ),
                    FeatureWidget(
                      visible: featureB.contains(roleUser),
                      title: "Penyimpanan",
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
                      title: "Berkas",
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
                      title: "Waktu",
                      data: timeTxt,
                      onTap: () async {},
                      icon: const Icon(
                        CupertinoIcons.time,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        int timeNowSeconds = ConvertV2().getTimeNowSeconds();

                        int dataUpdate = timeNowSeconds;
                        BLEResponse resBLE = await _commandSet.setDateTime(
                            bleProvider, dataUpdate);
                        Snackbar.showHelperV2(
                          ScreenSnackbar.devicescreen,
                          resBLE,
                          onSuccess: onRefresh,
                        );
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
                              "Atur Waktu",
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
