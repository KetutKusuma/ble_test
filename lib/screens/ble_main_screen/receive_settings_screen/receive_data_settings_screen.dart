import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_set.dart';

import 'package:ble_test/ble-v2/model/sub_model/receive_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/time_pick/time_pick.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

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
  late BLEProvider bleProvider;
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String receiveEnableTxt = '-',
      receiveScheduleTxt = '-',
      receiveIntervalTxt = '-',
      receiveCountTxt = '-',
      receiveTimeAdjust = '-';
  TextEditingController controller = TextEditingController();
  TextEditingController receiveEnableTxtController = TextEditingController();
  TextEditingController receiveScheduleTxtController = TextEditingController();
  TextEditingController receiveIntervalTxtController = TextEditingController();
  TextEditingController receiveCountTxtController = TextEditingController();
  TextEditingController receiveTimeAdjustTxtController =
      TextEditingController();
  late SimpleFontelicoProgressDialog _progressDialog;

  // v2
  final _commandSet = CommandSet();
  late ReceiveModel receive;

  @override
  void initState() {
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
    initGetReceive();
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
      initGetReceive();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetReceive() async {
    try {
      if (isConnected) {
        BLEResponse<ReceiveModel> response =
            await Command().getReceiveSchedule(bleProvider);
        _progressDialog.hide();
        if (response.status) {
          receive = response.data!;
          setState(() {
            receiveEnableTxt = response.data!.enable.toString();
            receiveScheduleTxt =
                ConvertTime.minuteToDateTimeString(response.data!.schedule);
            receiveIntervalTxt = response.data!.interval.toString();
            receiveCountTxt = response.data!.count.toString();
            receiveTimeAdjust = response.data!.timeAdjust.toString();
          });
        } else {
          Snackbar.show(ScreenSnackbar.receivesettings, response.message,
              success: false);
        }
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.receivesettings, "Dapat error jadwal terima : $e",
          success: false);
    }
  }

  Future<bool?> _showTrueFalseDialog(BuildContext context, String msg) async {
    bool? selectedValue = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(msg),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, true); // Return true
              },
              child: const Text('Ya'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, false); // Return false
              },
              child: const Text('Tidak'),
            ),
          ],
        );
      },
    );

    return selectedValue;
  }

  Future<String?> _showInputDialogInteger(
      TextEditingController controller, String field, String time) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Masukan data $field"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                  signed: false, decimal: false),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,2}$')),
              ],
              decoration: InputDecoration(
                labelText: 'Value in $time',
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
      key: Snackbar.snackBarKeyReceiveSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Penerimaan'),
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
                      title: "Izinkan Penerimaan",
                      data: receiveEnableTxt == "true" ? "Ya" : "Tidak",
                      onTap: () async {
                        bool? input = await _showTrueFalseDialog(
                            context, "Ubah Izin Penerimaan");
                        if (input != null) {
                          // Ubah nilai boolean menjadi string "1" untuk true atau "0" untuk false
                          receive.enable = input;
                          BLEResponse resBLE = await _commandSet
                              .setReceiveSchedule(bleProvider, receive);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.receivesettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Jadwal Penerimaan (waktu)",
                      data: receiveScheduleTxt,
                      onTap: () async {
                        TimeOfDay? result =
                            await TimePickerHelper.pickTime(context, null);
                        if (result != null) {
                          int data =
                              TimePickerHelper.timeOfDayToMinutes(result);
                          receive.schedule = data;
                          BLEResponse resBLE = await _commandSet
                              .setReceiveSchedule(bleProvider, receive);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.receivesettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Jumlah Penerimaan",
                      data: receiveCountTxt,
                      onTap: () async {
                        receiveCountTxtController.text = receiveCountTxt;
                        String? input = await _showInputDialogInteger(
                            receiveCountTxtController,
                            "Jumlah Penerimaan",
                            "angka");
                        if (input != null) {
                          receive.count = int.parse(input);
                          BLEResponse resBLE = await _commandSet
                              .setReceiveSchedule(bleProvider, receive);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.receivesettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.looks_3_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Interval Penerimaan (menit)",
                      data: receiveIntervalTxt,
                      onTap: () async {
                        receiveIntervalTxtController.text = receiveIntervalTxt;
                        String? input = await _showInputDialogInteger(
                            receiveIntervalTxtController,
                            "Interval Penerimaan",
                            "menit");
                        if (input != null) {
                          receive.interval = int.parse(input);
                          BLEResponse resBLE = await _commandSet
                              .setReceiveSchedule(bleProvider, receive);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.receivesettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.trending_up_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Penyesuaian Waktu Penerimaan (detik)",
                      data: receiveTimeAdjust,
                      onTap: () async {
                        receiveTimeAdjustTxtController.text = receiveTimeAdjust;
                        String? input = await _showInputDialogInteger(
                            receiveTimeAdjustTxtController,
                            "Penyesuaian Waktu Penerimaan",
                            "detik");
                        if (input != null) {
                          receive.timeAdjust = int.parse(input);
                          BLEResponse resBLE = await _commandSet
                              .setReceiveSchedule(bleProvider, receive);
                          Snackbar.showHelperV2(
                            ScreenSnackbar.receivesettings,
                            resBLE,
                            onSuccess: onRefresh,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.more_time_rounded,
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
