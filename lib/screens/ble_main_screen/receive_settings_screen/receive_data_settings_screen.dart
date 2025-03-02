import 'dart:async';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_set.dart';
import 'package:ble_test/ble-v2/model/sub_model/receive_model.dart';
import 'package:ble_test/ble-v2/utils/convert.dart';
import 'package:ble_test/constant/constant_color.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/time_pick/time_pick.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

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

  TextEditingController controller = TextEditingController();
  TextEditingController receiveEnableTxtController = TextEditingController();
  TextEditingController receiveScheduleTxtController = TextEditingController();
  TextEditingController receiveTimeAdjustTxtController =
      TextEditingController();
  late SimpleFontelicoProgressDialog _progressDialog;

  // v2
  final _commandSet = CommandSet();
  late List<ReceiveModel> listReceive = [];
  bool? selectedChoice; // Tracks the selected choice

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
      message: "Harap Tunggu...",
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
        BLEResponse<List<ReceiveModel>> response =
            await Command().getReceiveSchedule(bleProvider);
        _progressDialog.hide();
        if (response.status) {
          listReceive = response.data!;
          setState(() {
            // receiveEnableTxt = response.data!.enable.toString();
            // receiveScheduleTxt =
            //     ConvertTime.minuteToDateTimeString(response.data!.schedule);
            // receiveIntervalTxt = response.data!.interval.toString();
            // receiveCountTxt = response.data!.count.toString();
            // receiveTimeAdjust = response.data!.timeAdjust.toString();
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

  Future<ReceiveModel?> _showSetupReceiveDialog(
    BuildContext context,
    int number,
  ) async {
    return await showDialog<ReceiveModel>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Atur Penerimaan ${number + 1}"),
          content: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  readOnly: true,
                  onTap: () async {
                    TimeOfDay? result =
                        await TimePickerHelper.pickTime(context, null);
                    if (result != null) {
                      setState(() {
                        receiveScheduleTxtController.text =
                            TimePickerHelper.formatTimeOfDay(result);
                      });
                    }
                  },
                  controller: receiveScheduleTxtController,
                  decoration: const InputDecoration(
                    labelText: "Masukan Jadwal Penerimaan",
                    hintText: "00.00-23.59",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(
                  height: 10,
                ),
                TextFormField(
                  controller: receiveTimeAdjustTxtController,
                  keyboardType: const TextInputType.numberWithOptions(
                      signed: false, decimal: false),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^-?\d{0,3}$')),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Masukan Penyesuaian Waktu Penerimaan (detik)",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(
                  height: 5,
                ),
                // for destination enable
                Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      const Text(
                        "Aktifkan Penerimaan ?",
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(
                              () => selectedChoice = true,
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: selectedChoice == true
                                      ? Colors.green
                                      : Colors.grey,
                                  radius: 12,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Ya',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          GestureDetector(
                            onTap: () => setState(() => selectedChoice = false),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: selectedChoice == false
                                      ? Colors.red
                                      : Colors.grey,
                                  radius: 12,
                                ),
                                const SizedBox(width: 10),
                                const Text(
                                  'Tidak',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),
          actions: [
            TextButton(
              onPressed: () {
                receiveEnableTxtController.clear();
                receiveScheduleTxtController.clear();
                receiveTimeAdjustTxtController.clear();
                Navigator.of(context).pop();
              },
              child: const Text("Batalkan"),
            ),
            TextButton(
              onPressed: () {
                if (selectedChoice != null &&
                    receiveScheduleTxtController.text.isNotEmpty &&
                    receiveTimeAdjustTxtController.text.isNotEmpty) {
                  int receiveSchedule =
                      TimePickerHelper.timeOfDayStringToMinutes(
                          receiveScheduleTxtController.text);
                  ReceiveModel receiveModel = ReceiveModel(
                    enable: selectedChoice ?? false,
                    schedule: receiveSchedule,
                    timeAdjust: int.parse(receiveTimeAdjustTxtController.text),
                  );
                  receiveEnableTxtController.clear();
                  receiveScheduleTxtController.clear();
                  receiveTimeAdjustTxtController.clear();
                  Navigator.pop(context, receiveModel);
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
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
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: listReceive.length,
                  (context, index) {
                    return Container(
                      margin: const EdgeInsets.only(
                        top: 15,
                        left: 10,
                        right: 10,
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 15, vertical: 10),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          )),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pengaturan Jadwal Penerimaan ${index + 1}",
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Aktifkan Penerimaan : ",
                                  style: GoogleFonts.readexPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      listReceive[index].enable
                                          ? "Ya"
                                          : "Tidak",
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 3,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Jadwal Penerimaan : ",
                                  style: GoogleFonts.readexPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      ConvertTime.minuteToDateTimeString(
                                          listReceive[index].schedule),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Penyesuaian Waktu Penerimaan (detik) : ",
                                  style: GoogleFonts.readexPro(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      listReceive[index].timeAdjust.toString(),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            width: MediaQuery.of(context).size.width,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ), // Rounded corners
                                ),
                              ),
                              onPressed: () async {
                                // ReceiveModel receivemodel = listReceive[index];
                                selectedChoice = listReceive[index].enable;
                                receiveScheduleTxtController.text =
                                    TimePickerHelper.formatTimeOfDay(
                                        TimePickerHelper.minutesToTimeOfDay(
                                            listReceive[index].schedule));
                                receiveTimeAdjustTxtController.text =
                                    listReceive[index].timeAdjust.toString();
                                ReceiveModel? resilt =
                                    await _showSetupReceiveDialog(
                                  context,
                                  index,
                                );

                                if (resilt != null) {
                                  listReceive[index] = resilt;
                                  BLEResponse resBLE =
                                      await _commandSet.setReceiveSchedule(
                                          bleProvider, listReceive);
                                  Snackbar.showHelperV2(
                                    ScreenSnackbar.receivesettings,
                                    resBLE,
                                    onSuccess: onRefresh,
                                  );
                                }
                              },
                              child: const Text(
                                "Perbarui Penerimaan",
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
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
