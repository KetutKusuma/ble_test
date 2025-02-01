import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/converter/settings/capture_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:ble_test/utils/time_pick/time_pick.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

import '../../../constant/constant_color.dart';
import '../admin_settings_screen/admin_settings_screen.dart';

class CaptureSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;

  const CaptureSettingsScreen({super.key, required this.device});

  @override
  State<CaptureSettingsScreen> createState() => _CaptureSettingsScreenState();
}

class _CaptureSettingsScreenState extends State<CaptureSettingsScreen> {
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  final bool _isConnecting = false;
  final bool _isDisconnecting = false;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  StreamSubscription<List<int>>? _lastValueSubscription;

  List<BluetoothService> _services = [];
  List<int> _value = [];
  final RefreshController _refreshController = RefreshController();
  String statusTxt = "-",
      captureScheduleTxt = "-",
      captureIntervalTxt = "-",
      captureCountTxt = '-',
      captureRecentLimitTxt = '-',
      spCaptureDateTxt = '-', // bit operation
      spCaptureScheduleTxt = '-',
      spCaptrueIntervalTxt = '-',
      spCaptureCountTxt = '-';

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  bool isCaptureSettings = true;
  late SimpleFontelicoProgressDialog _progressDialog;
  TextEditingController spCaptureDateTxtController = TextEditingController();

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
    // spCaptureDateTxtController.addListener(() {
    //   final text = spCaptureDateTxtController.text;
    //   if (text.isNotEmpty) {
    //     final value = double.tryParse(text);
    //     if (value != null) {
    //       if (value <= 1 && text.length >= 31) {
    //         // Otomatis set menjadi 0.5 jika kurang dari 0.5
    //         spCaptureDateTxtController.text = '1';
    //         spCaptureDateTxtController.selection = TextSelection.fromPosition(
    //             TextPosition(
    //                 offset: spCaptureDateTxtController
    //                     .text.length)); // Memastikan cursor di akhir
    //       } else if (value >= 31) {
    //         // Otomatis set menjadi 1.5 jika lebih dari 1.5
    //         spCaptureDateTxtController.text = '31';
    //         spCaptureDateTxtController.selection = TextSelection.fromPosition(
    //             TextPosition(
    //                 offset: spCaptureDateTxtController
    //                     .text.length)); // Memastikan cursor di akhir
    //       }
    //     }
    //   }
    // });
    initGetRawCapture();
    initDiscoverServices();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    isCaptureSettings = false;
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
      initGetRawCapture();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawCapture() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_capture?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Capture", device);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings, "Error get raw admin : $e",
          success: false);
    }
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(milliseconds: 500));
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
              if (characters.properties.notify && isCaptureSettings) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 16) {
                  List<dynamic> result =
                      CaptureSettingsConverter.convertCaptureSettings(_value);
                  _progressDialog.hide();

                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      captureScheduleTxt = TimePickerHelper.formatTimeOfDay(
                          TimePickerHelper.minutesToTimeOfDay(result[1]));
                      captureIntervalTxt = result[2].toString();
                      captureCountTxt = result[3].toString();
                      captureRecentLimitTxt = (result[4]).toString();
                      spCaptureDateTxt = getDateSpecialCaptureDate(result[5]);
                      spCaptureScheduleTxt = TimePickerHelper.formatTimeOfDay(
                          TimePickerHelper.minutesToTimeOfDay(result[6]));
                      spCaptrueIntervalTxt = result[7].toString();
                      spCaptureCountTxt = result[8].toString();
                    });
                  }
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "capture_schedule") {
                      captureScheduleTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "capture_interval") {
                      captureIntervalTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "capture_count") {
                      captureCountTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "capture_recent_limit") {
                      captureRecentLimitTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "special_capture_date") {
                      spCaptureDateTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "special_capture_schedule") {
                      spCaptureScheduleTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "special_capture_interval") {
                      spCaptrueIntervalTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "special_capture_count") {
                      spCaptureCountTxt = _setSettings.value;
                    }
                    Snackbar.show(ScreenSnackbar.capturesettings,
                        "Sukses ubah ${_setSettings.setSettings}",
                        success: true);
                  } else {
                    Snackbar.show(ScreenSnackbar.capturesettings,
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
      Snackbar.show(ScreenSnackbar.capturesettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  String getDateSpecialCaptureDate(List<int> value) {
    List<int> dateTemp = [];

    // Iterate over the list
    for (int i = 0; i < value.length; i++) {
      if (value[i] == 1) {
        if (i + 1 != 32) {
          dateTemp.add(i + 1); // Add (index + 1) to match days of the month
        }
      }
    }
    return dateTemp.toString().replaceAll("[", "").replaceAll("]", "");
  }

  Future<String?> _showInputDialog(
    TextEditingController controller,
    String inputTitle, {
    String label = '',
  }) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Masukan data $inputTitle"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Enter $label',
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
              child: const Text("Batalkan"),
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
  }

  Future<Map?> _showInputSpecialCaptureDateDialog(
    String inputTitle,
  ) async {
    return await showDialog<Map>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Masukan data $inputTitle"),
          content: Column(
            mainAxisSize:
                MainAxisSize.min, // Ensures the Column remains compact
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextFormField(
                controller: spCaptureDateTxtController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: false),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  labelText: 'Masukan Tanggal (1 - 31)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(
                height: 15,
              ),
              const Text("Status Tanggal Pengambilan Khusus"),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      int dataParse =
                          int.parse(spCaptureDateTxtController.text.toString());
                      if (dataParse >= 1 && dataParse <= 31) {
                        if (spCaptureDateTxtController.text.isNotEmpty) {
                          Navigator.pop(context, {
                            "date": spCaptureDateTxtController.text,
                            "status": true,
                          });
                        }
                      }
                    },
                    child: const Text("Aktif"),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      int dataParse =
                          int.parse(spCaptureDateTxtController.text.toString());
                      if (dataParse >= 1 && dataParse <= 31) {
                        if (spCaptureDateTxtController.text.isNotEmpty) {
                          Navigator.pop(context, {
                            "date": spCaptureDateTxtController.text,
                            "status": false,
                          });
                        }
                      }
                    },
                    child: const Text("Non Aktif"),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyCaptureSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Pengambilan Gambar'),
          elevation: 0,
          // actions: [
          //   Row(
          //     children: [
          //       if (_isConnecting || _isDisconnecting) buildSpinner(context),
          //       TextButton(
          //         onPressed: _isConnecting
          //             ? onCancelPressed
          //             : (isConnected ? onDisconnectPressed : onConnectPressed),
          //         child: Text(
          //           _isConnecting
          //               ? "Batalkan"
          //               : (isConnected ? "DISCONNECT" : "CONNECT"),
          //           style: Theme.of(context)
          //               .primaryTextTheme
          //               .labelLarge
          //               ?.copyWith(color: Colors.white),
          //         ),
          //       )
          //     ],
          //   ),
          // ],
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
                    // SettingsContainer(
                    //   title: "Status",
                    //   data: statusTxt,
                    //   onTap: () {},
                    //   icon: const Icon(
                    //     CupertinoIcons.settings,
                    //   ),
                    // ),
                    const SizedBox(
                      height: 7,
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(vertical: 7.0, horizontal: 15),
                      margin: const EdgeInsets.symmetric(
                          vertical: 0.0, horizontal: 15),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10)),
                      ),
                      width: MediaQuery.of(context).size.width,
                      child: const Text(
                        "Pengaturan Pengambilan Gambar Perhari",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SettingsContainer(
                      title: "Jadwal Pengambilan Gambar",
                      description: "(Mulai Pengambilan Gambar Hari Ini)",
                      data: captureScheduleTxt,
                      onTap: () async {
                        TimeOfDay? result =
                            await TimePickerHelper.pickTime(context, null);
                        if (result != null) {
                          _setSettings.setSettings = "capture_schedule";
                          _setSettings.value =
                              TimePickerHelper.formatTimeOfDay(result);
                          List<int> list = utf8.encode(
                              "capture_schedule=${TimePickerHelper.timeOfDayToMinutes(result)}");
                          Uint8List bytes = Uint8List.fromList(list);
                          BLEUtils.funcWrite(bytes,
                              "Sukses ubah Jadwal Pengambilan Gambar", device);
                        }
                        // if (isConnected) {
                        //   String? input = await _showInputDialog(
                        //       controller, "Capture Schedule",
                        //       label: "what minute of a day");
                        //   if (input != null) {
                        //     _setSettings.setSettings = "capture_schedule";
                        //     _setSettings.value = input;
                        //     List<int> list =
                        //         utf8.encode("capture_schedule=$input");
                        //     Uint8List bytes = Uint8List.fromList(list);
                        //     BLEUtils.funcWrite(
                        //         bytes, "Sukses ubah Capture Schedule", device);
                        //   }
                        // }
                      },
                      icon: const Icon(
                        Icons.calendar_month_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Jumlah Pengambilan Gambar",
                      description: "(Berapa banyak pengulangan perhari)",
                      data: captureCountTxt,
                      onTap: () async {
                        if (isConnected) {
                          controller.text = captureCountTxt;
                          String? input = await _showInputDialog(
                              controller, "Jumlah Pengambilan Gambar",
                              label: "how many repetitions a day");
                          if (input != null) {
                            _setSettings.setSettings = "capture_count";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("capture_count=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes,
                                "Sukses ubah Jumlah Pengambilan Gambar",
                                device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.looks_3_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Interval Pengambilan Gambar",
                      description:
                          "(Pengambilan Gambar Berulang berapa menit sekali dalam Satu Hari) (menit)",
                      data: captureIntervalTxt,
                      onTap: () async {
                        if (isConnected) {
                          controller.text = captureIntervalTxt;
                          String? input = await _showInputDialog(
                              controller, "Interval Pengambilan Gambar",
                              label: "repetition capture");
                          if (input != null) {
                            _setSettings.setSettings = "capture_interval";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("capture_interval=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes,
                                "Sukses ubah Interval Pengambilan Gambar",
                                device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.trending_up_rounded,
                      ),
                    ),

                    SettingsContainer(
                      title: "Batas Pengambilan Terbaru",
                      description:
                          "(Jumlah Riwayat Foto yang Disimpan Sebelum Dihapus)",
                      data: captureRecentLimitTxt,
                      onTap: () async {
                        if (isConnected) {
                          controller.text = captureRecentLimitTxt;
                          String? input = await _showInputDialog(
                            controller,
                            "Batas Pengambilan Terbaru",
                          );
                          if (input != null) {
                            _setSettings.setSettings = "capture_recent_limit";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("capture_recent_limit=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes,
                                "Sukses ubah Batas Pengambilan Terbaru",
                                device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.switch_camera_outlined,
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        // ini agak special untuk updatenya
                        Map? input = await _showInputSpecialCaptureDateDialog(
                            "Tanggal Pengambilan Khusus");
                        if (input != null) {
                          spCaptureDateTxtController.clear();
                          log("input : $input | special_capture_date=${input["date"]};${input["status"]}");
                          List<int> list = utf8.encode(
                              "special_capture_date=${input["date"]};${input["status"]}");
                          Uint8List bytes = Uint8List.fromList(list);
                          BLEUtils.funcWrite(bytes,
                              "Sukses ubah Tanggal Pengambilan Khusus", device);
                        }
                        // nanti setelah 200 detik get lagi raw_capture
                        // hold dulu
                        await Future.delayed(const Duration(milliseconds: 200));
                        initGetRawCapture();
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.only(top: 7, left: 10, right: 10),
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
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.edit_calendar_outlined),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                flex: 4,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tanggal Pengambilan Khusus",
                                      style: GoogleFonts.readexPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "(Tanggal Aktif untuk Pengambilan Khusus)",
                                      style: GoogleFonts.readexPro(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Text(
                                    spCaptureDateTxt,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),

                    SettingsContainer(
                      title: "Jadwal Pengambilan Gambar Khusus",
                      description:
                          "(Mulai Pengambilan Gambar pada Tanggal Khusus)",
                      data: spCaptureScheduleTxt,
                      onTap: () async {
                        TimeOfDay? result =
                            await TimePickerHelper.pickTime(context, null);
                        if (result != null) {
                          _setSettings.setSettings = "special_capture_schedule";
                          _setSettings.value =
                              TimePickerHelper.formatTimeOfDay(result);
                          List<int> list = utf8.encode(
                              "special_capture_schedule=${TimePickerHelper.timeOfDayToMinutes(result)}");
                          Uint8List bytes = Uint8List.fromList(list);
                          BLEUtils.funcWrite(
                              bytes,
                              "Sukses ubah Jadwal Pengambilan Gambar Khusus",
                              device);
                        }
                        // if (isConnected) {
                        //   String? input = await _showInputDialog(
                        //       controller, "Jadwal Pengambilan Gambar Khusus",
                        //       label: "start minute");
                        //   if (input != null) {
                        //     _setSettings.setSettings =
                        //         "special_capture_schedule";
                        //     _setSettings.value = input;
                        //     List<int> list =
                        //         utf8.encode("special_capture_schedule=$input");
                        //     Uint8List bytes = Uint8List.fromList(list);
                        //     BLEUtils.funcWrite(bytes,
                        //         "Sukses ubah Jadwal Pengambilan Gambar Khusus", device);
                        //   }
                        // }
                      },
                      icon: const Icon(
                        Icons.calendar_month_sharp,
                      ),
                    ),
                    SettingsContainer(
                      title: "Interval Pengambilan Gambar Khusus",
                      description:
                          "(Pengambilan Berulang pada Tanggal Khusus) (menit)",
                      data: spCaptrueIntervalTxt,
                      onTap: () async {
                        if (isConnected) {
                          controller.text = spCaptrueIntervalTxt;
                          String? input = await _showInputDialog(
                              controller, "Interval Pengambilan Gambar Khusus",
                              label: "repetition capture");
                          if (input != null) {
                            _setSettings.setSettings =
                                "special_capture_interval";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("special_capture_interval=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes,
                                "Sukses ubah Interval Pengambilan Gambar Khusus",
                                device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.trending_up_outlined,
                      ),
                    ),
                    SettingsContainer(
                      title: "Jumlah Pengambilan Gambar Khusus",
                      description:
                          "(Berapa banyak pengulangan dari tanggal khusus)",
                      data: spCaptureCountTxt,
                      onTap: () async {
                        if (isConnected) {
                          controller.text = spCaptureCountTxt;
                          String? input = await _showInputDialog(
                            controller,
                            "Jumlah Pengambilan Gambar Khusus",
                            label: "how many repetitions a day",
                          );
                          if (input != null) {
                            _setSettings.setSettings = "special_capture_count";
                            _setSettings.value = input;
                            List<int> list =
                                utf8.encode("special_capture_count=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes,
                                "Sukses ubah Jumlah Pengambilan Gambar Khusus",
                                device);
                          }
                        }
                      },
                      icon: const Icon(
                        Icons.looks_4_outlined,
                      ),
                    ),
                    const SizedBox(
                      height: 20,
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
      Snackbar.show(ScreenSnackbar.capturesettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.capturesettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.capturesettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.capturesettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.capturesettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.capturesettings,
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
