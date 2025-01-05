import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:typed_data';

import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/upload_settings_screen/upload_enable_schedule_settings_screen/upload_enable_schedule_settings_screen.dart';
import 'package:ble_test/utils/converter/settings/upload_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/time_pick/time_pick.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../constant/constant_color.dart';
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
      uploadUsingTxt = '-',
      uploadInitialDelayTxt = '-',
      wifiSsidTxt = '-',
      wifiPasswordTxt = '-',
      modemApnTxt = '-';
  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  TextEditingController portController = TextEditingController();

  final List<Map<String, dynamic>> listMapUploadUsing = [
    {"title": "Wifi", "value": 0},
    {"title": "Sim800l", "value": 1},
    {"title": "NB-Iot", "value": 2},
  ];

  bool isUploadSettings = true;

  // for progress dialog
  late SimpleFontelicoProgressDialog _progressDialog;

  // ini untuk uplado schedule dan upload enbale
  List<bool> uploadEnable = [];
  List<int> uploadSchedule = [];
  TextEditingController uploadScheduleTxtController = TextEditingController();

  @override
  void initState() {
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

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
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
      Snackbar.show(ScreenSnackbar.uploadsettings, "Error get raw admin : $e",
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
                  _progressDialog.hide();
                  if (mounted) {
                    log("result[1]: '${result[1]}', ${result[1].trim().length} ${result[1].isEmpty}");
                    setState(() {
                      statusTxt = result[0].toString();
                      serverTxt = "${result[1]}";
                      portTxt = result[2].toString();
                      // upload enable dan upload schedule itu harusnya berupa list

                      uploadEnable = result[3]; // List<bool> [8]
                      uploadSchedule = result[4]; // List<int> [8]
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
                    Snackbar.show(ScreenSnackbar.uploadsettings,
                        "Success set ${_setSettings.setSettings}",
                        success: true);
                  } else {
                    Snackbar.show(ScreenSnackbar.uploadsettings,
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
      {List<TextInputFormatter>? inputFormatters,
      TextInputType? keyboardType = TextInputType.text}) async {
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
              keyboardType: keyboardType,
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
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                  controller.clear();
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

  Future<List<String>?> showSetupUploadDialog(
      BuildContext context, int number) async {
    bool? selectedChoice; // Tracks the selected choice

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
            "Setup Destination ${number + 1}",
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
                        labelText: "Enter Upload Schedule",
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
                            "Upload Enable",
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
                                      'True',
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
                                      'False',
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

                  Navigator.of(context).pop([
                    "upload_schedule=$number;$transmitSchedule",
                    "upload_enable=$number;$selectedChoice",
                  ]);
                }
              },
              child: Text(
                'Update',
                style: GoogleFonts.readexPro(),
              ),
            ),
            TextButton(
              onPressed: () {
                uploadScheduleTxtController.clear();
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
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
      key: Snackbar.snackBarKeyUploadSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Upload Settings'),
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
          //               ? "CANCEL"
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
              SliverToBoxAdapter(
                // hasScrollBody: false,
                child: Column(
                  children: [
                    // SettingsContainer(
                    //   title: "Status",
                    //   data: statusTxt,
                    //   onTap: () {},
                    //   icon: const Icon(
                    //     CupertinoIcons.settings,
                    //   ),
                    // ),
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
                            portController,
                            "Upload Port",
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            keyboardType: TextInputType.number,
                          );
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

                    // CustomScrollView(
                    //   slivers: [

                    //   ],
                    // ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                UploadEnableScheduleSettingScreen(
                                    device: device),
                          ),
                        );
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
                              const Icon(CupertinoIcons.gear),
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
                                      "Settings Enable & Schedule",
                                      style: GoogleFonts.readexPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Expanded(
                                flex: 3,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 20,
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
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
                                utf8.encode("upload_using=${input['value']}");
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
                      title: "Upload Initial Delay (seconds)",
                      data: uploadInitialDelayTxt,
                      onTap: () async {
                        try {
                          String? input = await _showInputDialog(
                              controller, "Upload Initial Delay",
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      signed: false, decimal: true));
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
                          String? input = await _showInputDialog(
                            controller,
                            "Wifi SSID",
                          );
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
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 10.0, right: 10, top: 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                List<int> list = utf8.encode("wifi_connect!");
                                Uint8List bytes = Uint8List.fromList(list);
                                BLEUtils.funcWrite(
                                    bytes, "Success Connect Wifi", device);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 10),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.green.shade600),
                                child: Text(
                                  "Connect Wifi",
                                  style: GoogleFonts.readexPro(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            width: 15,
                          ),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                splashColor: Colors.black,
                                onTap: () {
                                  List<int> list =
                                      utf8.encode("wifi_disconnect!");
                                  Uint8List bytes = Uint8List.fromList(list);
                                  BLEUtils.funcWrite(
                                      bytes, "Success Disonnect Wifi", device);
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 10, horizontal: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.grey.shade600),
                                  child: Text(
                                    "Disconnect Wifi",
                                    style: GoogleFonts.readexPro(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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
