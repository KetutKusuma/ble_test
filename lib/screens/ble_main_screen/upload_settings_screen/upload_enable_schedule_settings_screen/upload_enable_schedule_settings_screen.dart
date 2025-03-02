import 'dart:async';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_set.dart';
import 'package:ble_test/ble-v2/model/sub_model/upload_model.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../../constant/constant_color.dart';
import '../../../../utils/time_pick/time_pick.dart';

class UploadEnableScheduleSettingScreen extends StatefulWidget {
  final BluetoothDevice device;
  const UploadEnableScheduleSettingScreen({super.key, required this.device});

  @override
  State<UploadEnableScheduleSettingScreen> createState() =>
      _UploadEnableScheduleSettingScreenState();
}

class _UploadEnableScheduleSettingScreenState
    extends State<UploadEnableScheduleSettingScreen> {
  late BLEProvider bleProvider;
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  TextEditingController controller = TextEditingController();
  TextEditingController portController = TextEditingController();

  final List<Map<String, dynamic>> listMapUploadUsing = [
    {"title": "Wifi", "value": 0},
    {"title": "Sim800l", "value": 1},
    {"title": "NB-Iot", "value": 2},
  ];

  // for progress dialog
  late SimpleFontelicoProgressDialog _progressDialog;

  // ini untuk uplado schedule dan upload enbale
  List<UploadModel> uploadScheduleList = [];
  TextEditingController uploadScheduleTxtController = TextEditingController();

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
    portController.addListener(() {
      final text = portController.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          if (value < 0 && text.length > 65535) {
            // Otomatis set menjadi 0.5 jika kurang dari 0.5
            portController.text = '0';
            portController.selection = TextSelection.fromPosition(TextPosition(
                offset:
                    portController.text.length)); // Memastikan cursor di akhir
          } else if (value > 65535) {
            // Otomatis set menjadi 1.5 jika lebih dari 1.5
            portController.text = '65535';
            portController.selection = TextSelection.fromPosition(
              TextPosition(
                offset: portController.text.length,
              ),
            ); // Memastikan cursor di akhir
          }
        }
      }
    });
    initGetDataUpload();
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
      initGetDataUpload();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetDataUpload() async {
    try {
      BLEResponse<List<UploadModel>> response =
          await Command().getUploadSchedule(bleProvider);
      _progressDialog.hide();
      if (response.status) {
        setState(() {
          uploadScheduleList = response.data ?? [];
        });
      } else {
        Snackbar.show(ScreenSnackbar.uploadsettings, response.message,
            success: false);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.uploadsettings, "Error get raw admin : $e",
          success: false);
    }
  }

  Future<UploadModel?> showSetupUploadDialog(
    BuildContext context,
    int number,
  ) async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
          ),
          titlePadding:
              const EdgeInsets.only(left: 10, right: 10, bottom: 15, top: 10),
          title: Text(
            "Atur Tujuan ${number + 1}",
            style: GoogleFonts.readexPro(
              fontWeight: FontWeight.w500,
            ),
          ),
          content: SizedBox(
            height: 200,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  children: [
                    // for transmit schedule
                    TextFormField(
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? result =
                            await TimePickerHelper.pickTime(context, null);
                        if (result != null) {
                          uploadScheduleTxtController.text =
                              TimePickerHelper.formatTimeOfDay(result);
                        }
                      },
                      style: GoogleFonts.readexPro(),
                      controller: uploadScheduleTxtController,
                      decoration: const InputDecoration(
                        labelText: "Masukan Jadwal Unggah",
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

                    // for destination enable
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Aktifkan Unggah ?",
                            style: GoogleFonts.readexPro(),
                          ),
                          const SizedBox(
                            height: 5,
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () =>
                                    setState(() => selectedChoice = true),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: selectedChoice == true
                                          ? Colors.green
                                          : Colors.grey,
                                      radius: 12,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Ya',
                                      style: GoogleFonts.readexPro(),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => selectedChoice = false),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: selectedChoice == false
                                          ? Colors.red
                                          : Colors.grey,
                                      radius: 12,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Tidak',
                                      style: GoogleFonts.readexPro(),
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
              },
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                // Save logic here
                if (selectedChoice != null &&
                    uploadScheduleTxtController.text.isNotEmpty) {
                  int transmitSchedule = TimePickerHelper.timeOfDayToMinutes(
                      TimePickerHelper.stringToTimeOfDay(
                          uploadScheduleTxtController.text));
                  UploadModel uploadNew = UploadModel(
                    enable: selectedChoice ?? false,
                    schedule: transmitSchedule,
                  );
                  Navigator.pop(context, uploadNew);
                }
              },
              child: Text(
                'Simpan',
                style: GoogleFonts.readexPro(),
              ),
            ),
            TextButton(
              onPressed: () {
                uploadScheduleTxtController.clear();
                Navigator.of(context).pop();
              },
              child: Text(
                'Batalkan',
                style: GoogleFonts.readexPro(),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarListUploadScreen,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            "Pengaturan Jadwal Unggah",
            style: GoogleFonts.readexPro(),
          ),
        ),
        body: SmartRefresher(
          controller: _refreshController,
          onRefresh: onRefresh,
          child: CustomScrollView(
            slivers: [
              SliverList(
                  delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return Column(
                    children: [
                      Container(
                        margin:
                            const EdgeInsets.only(top: 15, left: 10, right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: borderColor,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pengaturan Jadwal dan Aktivasi Unggah ${index + 1}",
                              style: GoogleFonts.readexPro(
                                  fontSize: 18, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    "Aktifkan Unggah : ",
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
                                        uploadScheduleList[index].enable
                                            ? "Ya"
                                            : "Tidak",
                                        style: GoogleFonts.readexPro(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w400),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Jadwal Unggah : ",
                                  style: GoogleFonts.readexPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  TimePickerHelper.formatTimeOfDay(
                                      TimePickerHelper.minutesToTimeOfDay(
                                          uploadScheduleList[index].schedule)),
                                  style: GoogleFonts.readexPro(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () async {
                                selectedChoice =
                                    uploadScheduleList[index].enable;
                                uploadScheduleTxtController.text =
                                    TimePickerHelper.formatTimeOfDay(
                                        TimePickerHelper.minutesToTimeOfDay(
                                            uploadScheduleList[index]
                                                .schedule));
                                UploadModel? result =
                                    await showSetupUploadDialog(context, index);
                                if (result != null) {
                                  // do your magic
                                  uploadScheduleList[index] = result;
                                  BLEResponse resBLE = await CommandSet()
                                      .setUploadSchedule(
                                          bleProvider, uploadScheduleList);
                                  Snackbar.showHelperV2(
                                    ScreenSnackbar.uploadsettings,
                                    resBLE,
                                    onSuccess: onRefresh,
                                  );
                                }
                              },
                              child: Container(
                                margin: const EdgeInsets.only(
                                    left: 0, right: 0, top: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade600,
                                  borderRadius: BorderRadius.circular(10),
                                  // boxShadow: [
                                  //   BoxShadow(
                                  //     color: Colors.grey.withOpacity(0.5),
                                  //     spreadRadius: 1,
                                  //     blurRadius: 1,
                                  //     offset: const Offset(
                                  //         0, 1), // changes position of shadow
                                  //   ),
                                  // ],
                                ),
                                width: MediaQuery.of(context).size.width,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Perbarui Jadwal Unggah",
                                      style: GoogleFonts.readexPro(
                                        fontSize: 14,
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
                      ),
                    ],
                  );
                },
                childCount: uploadScheduleList.length,
              )),
              const SliverToBoxAdapter(
                child: SizedBox(height: 15),
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
