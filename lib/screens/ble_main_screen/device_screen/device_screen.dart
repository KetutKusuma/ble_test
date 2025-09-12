import 'dart:async';
import 'dart:developer';

import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_set.dart';
import 'package:ble_test/ble-v2/model/device_status_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/screens/ble_main_screen/ble_main_screen.dart';
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
      critBattery1CounterTxt = "-",
      critBattery2CounterTxt = "-",
      timeUTCText = "-";

  TextEditingController controller = TextEditingController();
  late SimpleFontelicoProgressDialog _progressDialog;
  TextEditingController spCaptureDateTxtController = TextEditingController();
  TextEditingController timeUTCTxtController = TextEditingController();
  final _commandSet = CommandSet();
  List<String> utcList = [
    "+12:00",
    "+11:00",
    "+10:00",
    "+09:00",
    "+08:00",
    "+07:00",
    "+06:00",
    "+05:00",
    "+04:00",
    "+03:00",
    "+02:00",
    "+01:00",
    "00:00",
    "-01:00",
    "-02:00",
    "-03:00",
    "-04:00",
    "-05:00",
    "-06:00",
    "-07:00",
    "-08:00",
    "-09:00",
    "-10:00",
    "-11:00",
    "-12:00",
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    bleProvider = Provider.of<BLEProvider>(context, listen: false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _progressDialog = SimpleFontelicoProgressDialog(
        context: context,
        barrierDimisable: true,
      );
      _showLoading();
    });
    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (_connectionState == BluetoothConnectionState.disconnected) {
        Navigator.popUntil(context, (route) => route.isFirst);
      }
      if (mounted) {
        setState(() {});
      }
    });
    initGetDeviceStatus();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();

    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(message: "Harap Tunggu...");
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

  Future<int?> _showClearCounterkDialog(
    BuildContext context,
    String msg,
  ) async {
    int? selectedValue = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(msg),
          actionsAlignment: MainAxisAlignment.start,
          alignment: Alignment.center,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, 1); // Return true
                },
                child: const Text('Hitungan magnet tidak diangkat'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, 2); // Return false
                },
                child: const Text('Hitungan baterai kritis'),
              ),
            ],
          ),
        );
      },
    );

    return selectedValue;
  }

  initGetDeviceStatus() async {
    try {
      BLEResponse<DeviceStatusModels> resDeviceStatus = await Command()
          .getDeviceStatus(device, bleProvider);
      log("hasil get device status : $resDeviceStatus");
      _progressDialog.hide();
      if (resDeviceStatus.status) {
        if (resDeviceStatus.data != null) {
          DeviceStatusModels dS = resDeviceStatus.data!;
          timeTxt = ConvertTime.dateFormatDateTime(dS.dateTime!);
          firmwareTxt = dS.firmwareModel!.name;
          versionTxt = dS.firmwareModel!.version;
          temperatureTxt = dS.temperature.toString();
          battery1Txt = dS.batteryVoltageModel!.batteryVoltage1.toStringAsFixed(
            2,
          );

          battery2Txt = dS.batteryVoltageModel!.batteryVoltage2.toStringAsFixed(
            2,
          );
          timeUTCText = ConvertV2().uint8ToUtcString(dS.timeUTC!);
          critBattery1CounterTxt = dS.otherModel!.criticalBattery1Counter
              .toString();
          critBattery2CounterTxt = dS.otherModel!.criticalBattery2Counter
              .toString();
          setState(() {});
        }
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

  Future<String?> _showSelectionPopupUTC(
    BuildContext context,
    List<String> dataList,
  ) async {
    String? result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pilih Sebuah Opsi'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: dataList.map((item) {
                  return ListTile(
                    dense: false,
                    visualDensity: const VisualDensity(vertical: -4),
                    contentPadding: const EdgeInsets.all(0),
                    horizontalTitleGap: 0,
                    minVerticalPadding: 0,
                    subtitle: Row(
                      children: [
                        const Icon(Icons.radio_button_checked_outlined),
                        const SizedBox(width: 20),
                        Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.of(
                        context,
                      ).pop(item); // Return the selected item
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyDeviceScreen,
      child: Scaffold(
        appBar: AppBar(title: const Text('Status Perangkat'), elevation: 0),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        title: "Bersihkan hitungan perangkat",
                        data: "",
                        onTap: () async {
                          int? input = await _showClearCounterkDialog(
                            context,
                            "Pilih bersihkan hitungan",
                          );
                          if (input != null) {
                            if (input == 1) {
                              // magnet tidak diangkat
                              BLEResponse resBLE = await Command()
                                  .clearNeodumiumNotRemovedCounter(bleProvider);
                              Snackbar.showHelperV2(
                                ScreenSnackbar.devicescreen,
                                resBLE,
                              );
                            }
                            if (input == 2) {
                              // baterai kritis
                              BLEResponse resBLE = await Command()
                                  .clearCriticalBatteryCounter(bleProvider);
                              Snackbar.showHelperV2(
                                ScreenSnackbar.devicescreen,
                                resBLE,
                                onSuccess: onRefresh,
                              );
                            }
                          }
                        },
                        icon: const Icon(CupertinoIcons.gobackward),
                      ),
                    ),
                    SettingsContainer(
                      title: "Perangkat Tertanam",
                      data: firmwareTxt.trim(),
                      onTap: () {},
                      icon: const Icon(Icons.memory_rounded),
                    ),
                    SettingsContainer(
                      title: "Versi",
                      data: versionTxt,
                      onTap: () {},
                      icon: const Icon(Icons.settings_suggest_outlined),
                    ),

                    SettingsContainer(
                      title: "Temperatur",
                      data: "$temperatureTxt °C",
                      onTap: () {},
                      icon: const Icon(Icons.thermostat),
                    ),

                    /// BATTERY
                    Column(
                      children: [
                        SettingsContainer(
                          title: "Baterai 1",
                          data: "$battery1Txt volt",
                          description:
                              critBattery1CounterTxt == "0" ||
                                  critBattery1CounterTxt == '-'
                              ? null
                              : "(Jumlah hitungan kritis : $critBattery1CounterTxt)",
                          onTap: () {},
                          icon: const Icon(Icons.battery_5_bar_outlined),
                        ),
                        SettingsContainer(
                          title: "Baterai 2",
                          data: "$battery2Txt volt",
                          description:
                              critBattery2CounterTxt == "0" ||
                                  critBattery2CounterTxt == '-'
                              ? null
                              : "(Jumlah hitungan kritis : $critBattery2CounterTxt)",
                          onTap: () {},
                          icon: const Icon(Icons.battery_full),
                        ),
                      ],
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
                            ScreenSnackbar.blemain,
                          );
                        }
                      },
                      icon: const Icon(Icons.sd_storage_outlined),
                    ),

                    SettingsContainer(
                      title: "Waktu",
                      data: timeTxt,
                      onTap: () async {},
                      icon: const Icon(CupertinoIcons.time),
                    ),
                    SettingsContainer(
                      title: "Waktu UTC",
                      data: timeUTCText,
                      onTap: () async {
                        if (!featureA.contains(roleUser)) {
                          return;
                        }
                        timeUTCTxtController.text = timeUTCText;
                        String? input = await _showSelectionPopupUTC(
                          context,
                          utcList,
                        );
                        if (input != null) {
                          int data = ConvertV2().utcStringToUint8(input);
                          BLEResponse resBLE = await _commandSet.setTimeUTC(
                            bleProvider,
                            data,
                          );
                          Snackbar.showHelperV2(
                            ScreenSnackbar.devicescreen,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(Icons.access_time),
                    ),
                    const SizedBox(height: 5),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: GestureDetector(
                        onTap: () async {
                          int timeNowSeconds = ConvertV2().getTimeNowSeconds();

                          int dataUpdate = timeNowSeconds;
                          BLEResponse resBLE = await _commandSet.setDateTime(
                            bleProvider,
                            dataUpdate,
                          );
                          if (resBLE.status) {
                            DateTime now = DateTime.now();
                            Duration offset = now.timeZoneOffset;

                            // Format offset as +hh:mm or -hh:mm
                            String formattedOffset =
                                "${offset.isNegative ? "-" : "+"}${offset.inHours.abs().toString().padLeft(2, '0')}:${(offset.inMinutes.abs() % 60).toString().padLeft(2, '0')}";
                            int timeUTC = ConvertV2().utcStringToUint8(
                              formattedOffset,
                            );
                            resBLE = await _commandSet.setTimeUTC(
                              bleProvider,
                              timeUTC,
                            );
                          }
                          if (resBLE.status) {
                            onRefresh();
                            Snackbar.show(
                              ScreenSnackbar.devicescreen,
                              "Waktu berhasil diatur",
                              success: true,
                            );
                          } else {
                            Snackbar.showHelperV2(
                              ScreenSnackbar.devicescreen,
                              resBLE,
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                            left: 10,
                            right: 10,
                            top: 5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
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
                              const SizedBox(width: 5),
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
                    ),
                  ],
                ),
              ),
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
