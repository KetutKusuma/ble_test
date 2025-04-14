import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/ble-v2/ble.dart';
import 'package:ble_test/ble-v2/command/command.dart';
import 'package:ble_test/ble-v2/command/command_set.dart';
import 'package:ble_test/ble-v2/model/sub_model/gateway_model.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/screens/ble_main_screen/upload_settings_screen/upload_enable_schedule_settings_screen/upload_enable_schedule_settings_screen.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/time_pick/time_pick.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../constant/constant_color.dart';
import '../../../utils/ble.dart';
import '../../../utils/snackbar.dart';
import 'package:ble_test/utils/extension/extension.dart';

class UploadSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  const UploadSettingsScreen({super.key, required this.device});

  @override
  State<UploadSettingsScreen> createState() => _UploadSettingsScreenState();
}

class _UploadSettingsScreenState extends State<UploadSettingsScreen> {
  late BLEProvider bleProvider;
  // for connection
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.connected;
  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  String serverTxt = '-',
      portTxt = '-',
      uploadUsingTxt = '-',
      uploadInitialDelayTxt = '-',
      wifiSsidTxt = '-',
      wifiPasswordTxt = '-',
      modemApnTxt = '-';
  TextEditingController controller = TextEditingController();
  TextEditingController portController = TextEditingController();

  // for handle >= v2.21
  String secureTxt = '-',
      mikrotikIPTxt = '-',
      mikrotikLoginSecureTxt = '-',
      mikrotikUsernameTxt = '-',
      mikrotikPasswordTxt = '-';

  TextEditingController mikrotikIPController = TextEditingController();
  TextEditingController mikrotikUsernameController = TextEditingController();
  TextEditingController mikrotikPasswordController = TextEditingController();

  // for progress dialog
  late SimpleFontelicoProgressDialog _progressDialog;

  // ini untuk uplado schedule dan upload enbale
  List<bool> uploadEnable = [];
  List<int> uploadSchedule = [];
  TextEditingController uploadScheduleTxtController = TextEditingController();

  // v2
  final _commandSet = CommandSet();
  late GatewayModel gatewayModel;

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
    initGetDataGateway();
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
      initGetDataGateway();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetDataGateway() async {
    try {
      gatewayModel = GatewayModel(
        paramCount: 7,
        server: "",
        port: 0,
        uploadUsing: 0,
        uploadInitialDelay: 0,
        wifi: WifiModel(
          ssid: "",
          password: "",
          secure: false,
          mikrotikIP: "",
          mikrotikLoginSecure: false,
          mikrotikUsername: "",
          mikrotikPassword: "",
        ),
        modemAPN: "",
      );
      BLEResponse<GatewayModel> res = await Command().getGateway(bleProvider);
      _progressDialog.hide();
      if (res.status) {
        gatewayModel = res.data!;
        log("gatewayModel : $gatewayModel");
        setState(() {
          serverTxt = res.data!.server;
          portTxt = res.data!.port.toString();
          uploadUsingTxt =
              GatewayModel.getUploadUsingString(res.data!.uploadUsing);
          uploadInitialDelayTxt = res.data!.uploadInitialDelay.toString();
          wifiSsidTxt = res.data!.wifi.ssid;
          wifiPasswordTxt = res.data!.wifi.password;
          if (gatewayModel.paramCount == 7) {
            modemApnTxt = res.data!.modemAPN;
          } else {
            secureTxt = res.data!.wifi.secure.changeBoolToStringIndo();
            mikrotikIPTxt = res.data!.wifi.mikrotikIP;
            mikrotikLoginSecureTxt =
                res.data!.wifi.mikrotikLoginSecure.changeBoolToStringIndo();
            mikrotikUsernameTxt = res.data!.wifi.mikrotikUsername;
            mikrotikPasswordTxt = res.data!.wifi.mikrotikPassword;
            modemApnTxt = res.data!.modemAPN;
          }
        });
      } else {
        Snackbar.show(ScreenSnackbar.uploadsettings, res.message,
            success: false);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.uploadsettings, "Error dapat gateway : $e",
          success: false);
    }
  }

  Future<String?> _showInputDialog(
      TextEditingController controller, String title,
      {List<TextInputFormatter>? inputFormatters,
      TextInputType? keyboardType = TextInputType.text,
      bool canSaveEmpty = true}) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Masukan data $title"),
          content: Form(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Masukan data",
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
              child: const Text("Batalkan"),
            ),
            TextButton(
              onPressed: () {
                if (canSaveEmpty || controller.text.isNotEmpty) {
                  Navigator.pop(context, controller.text);
                  controller.clear();
                }
              },
              child: const Text("Simpan"),
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
                'Perbarui',
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
      key: Snackbar.snackBarKeyUploadSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pengaturan Unggah'),
          elevation: 0,
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
                    SettingsContainer(
                      title: "Server",
                      data: serverTxt.changeEmptyString(),
                      onTap: () async {
                        try {
                          controller.text = serverTxt;
                          String? input =
                              await _showInputDialog(controller, "Server");
                          log("input : $input");
                          if (input != null) {
                            controller.clear();
                            gatewayModel.server = input;
                            BLEResponse resBLE = await _commandSet.setGateway(
                                bleProvider, gatewayModel);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.uploadsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
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
                      data: portTxt.changeEmptyString(),
                      onTap: () async {
                        try {
                          portController.text = portTxt;
                          String? input = await _showInputDialog(
                            portController,
                            "Upload Port",
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            keyboardType: TextInputType.number,
                          );
                          if (input != null) {
                            gatewayModel.port = int.parse(input);
                            BLEResponse resBLE = await _commandSet.setGateway(
                                bleProvider, gatewayModel);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.uploadsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
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
                                      "Pengaturan Jadwal dan Aktivasi",
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
                      title: "Unggah Menggunakan",
                      data: uploadUsingTxt,
                      onTap: () async {
                        try {
                          Map? input = await _showSelectionPopup(
                              context, GatewayModel.listMapUploadUsing);
                          if (input != null) {
                            gatewayModel.uploadUsing = input["value"];
                            BLEResponse resBLE = await _commandSet.setGateway(
                                bleProvider, gatewayModel);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.uploadsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
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
                      title: "Penundaan Awal Unggah",
                      description: "(detik)",
                      data: uploadInitialDelayTxt,
                      onTap: () async {
                        try {
                          controller.text = uploadInitialDelayTxt;
                          String? input = await _showInputDialog(
                              controller, "Upload Initial Delay",
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly
                              ],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      signed: false, decimal: true));
                          if (input != null) {
                            controller.clear();
                            gatewayModel.uploadInitialDelay = int.parse(input);
                            BLEResponse resBLE = await _commandSet.setGateway(
                                bleProvider, gatewayModel);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.uploadsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
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
                      title: "Nama Wifi",
                      data: wifiSsidTxt.changeEmptyString(),
                      onTap: () async {
                        try {
                          controller.text = wifiSsidTxt;
                          String? input = await _showInputDialog(
                            controller,
                            "Nama Wifi",
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(16)
                            ],
                            canSaveEmpty: false,
                          );
                          if (input != null) {
                            gatewayModel.wifi.ssid = input;
                            BLEResponse resBLE = await _commandSet.setGateway(
                                bleProvider, gatewayModel);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.uploadsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on Nama Wifi : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.wifi_rounded,
                      ),
                    ),
                    SettingsContainer(
                      title: "Kata Sandi Wifi",
                      data: wifiPasswordTxt,
                      onTap: () async {
                        try {
                          controller.text = wifiPasswordTxt;
                          String? input = await _showInputDialog(
                              controller, "Kata Sandi Wifi", inputFormatters: [
                            LengthLimitingTextInputFormatter(32)
                          ]);
                          if (input != null) {
                            gatewayModel.wifi.password = input;
                            BLEResponse resBLE = await _commandSet.setGateway(
                                bleProvider, gatewayModel);
                            Snackbar.showHelperV2(
                              ScreenSnackbar.uploadsettings,
                              resBLE,
                              onSuccess: onRefresh,
                            );
                          }
                        } catch (e) {
                          Snackbar.show(
                            ScreenSnackbar.uploadsettings,
                            "Error click on Kata Sandi Wifi : $e",
                            success: false,
                          );
                        }
                      },
                      icon: const Icon(
                        Icons.wifi_password_rounded,
                      ),
                    ),
                    (uploadUsingTxt != "Wifia")
                        ? const SizedBox()
                        : Padding(
                            padding: const EdgeInsets.only(
                                left: 10.0, right: 10, top: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      List<int> list =
                                          utf8.encode("wifi_connect!");
                                      Uint8List bytes =
                                          Uint8List.fromList(list);
                                      BLEUtils.funcWrite(bytes,
                                          "Success Connect Wifi", device);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 10),
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
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
                                        Uint8List bytes =
                                            Uint8List.fromList(list);
                                        BLEUtils.funcWrite(bytes,
                                            "Success Disonnect Wifi", device);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
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
                    (gatewayModel.paramCount == 7)
                        ? SettingsContainer(
                            title: "Modem APN",
                            data: modemApnTxt,
                            onTap: () async {
                              try {
                                controller.text = modemApnTxt;
                                String? input = await _showInputDialog(
                                  controller,
                                  "Modem APN",
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(24)
                                  ],
                                );
                                if (input != null) {
                                  controller.clear();
                                  gatewayModel.modemAPN = input;
                                  BLEResponse resBLE = await _commandSet
                                      .setGateway(bleProvider, gatewayModel);
                                  Snackbar.showHelperV2(
                                    ScreenSnackbar.uploadsettings,
                                    resBLE,
                                    onSuccess: onRefresh,
                                  );
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
                          )
                        :
                        // handle >= v2.21
                        Column(
                            children: [
                              SettingsContainer(
                                title: "Wifi Aman",
                                data: secureTxt,
                                onTap: () async {
                                  try {
                                    bool? input = await _showTrueFalseDialog(
                                        context, "Wifi Aman");
                                    if (input != null) {
                                      controller.clear();
                                      gatewayModel.wifi.secure = input;
                                      BLEResponse resBLE =
                                          await _commandSet.setGateway(
                                        bleProvider,
                                        gatewayModel,
                                      );
                                      Snackbar.showHelperV2(
                                        ScreenSnackbar.uploadsettings,
                                        resBLE,
                                        onSuccess: onRefresh,
                                      );
                                    }
                                  } catch (e) {
                                    Snackbar.show(
                                      ScreenSnackbar.uploadsettings,
                                      "Error click on wifi aman : $e",
                                      success: false,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  CupertinoIcons.wifi_exclamationmark,
                                ),
                              ),
                              SettingsContainer(
                                title: "Alamat IP Mikrotik",
                                data: mikrotikIPTxt,
                                onTap: () async {
                                  try {
                                    controller.text = mikrotikIPTxt;
                                    String? input = await _showInputDialog(
                                      controller,
                                      "Alamat IP Mikrotik",
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(16)
                                      ],
                                    );
                                    if (input != null) {
                                      controller.clear();
                                      gatewayModel.wifi.mikrotikIP = input;
                                      BLEResponse resBLE =
                                          await _commandSet.setGateway(
                                              bleProvider, gatewayModel);
                                      Snackbar.showHelperV2(
                                        ScreenSnackbar.uploadsettings,
                                        resBLE,
                                        onSuccess: onRefresh,
                                      );
                                    }
                                  } catch (e) {
                                    Snackbar.show(
                                      ScreenSnackbar.uploadsettings,
                                      "Error click on Alamat IP Mikrotik : $e",
                                      success: false,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.network_cell,
                                ),
                              ),
                              SettingsContainer(
                                title: "Login Mikrotik Aman",
                                data: mikrotikLoginSecureTxt,
                                onTap: () async {
                                  try {
                                    bool? input = await _showTrueFalseDialog(
                                        context, "Login Mikrotik Aman");
                                    if (input != null) {
                                      controller.clear();
                                      gatewayModel.wifi.mikrotikLoginSecure =
                                          input;
                                      BLEResponse resBLE =
                                          await _commandSet.setGateway(
                                        bleProvider,
                                        gatewayModel,
                                      );
                                      Snackbar.showHelperV2(
                                        ScreenSnackbar.uploadsettings,
                                        resBLE,
                                        onSuccess: onRefresh,
                                      );
                                    }
                                  } catch (e) {
                                    Snackbar.show(
                                      ScreenSnackbar.uploadsettings,
                                      "Error click on Login MikroTik Aman : $e",
                                      success: false,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.network_locked_outlined,
                                ),
                              ),
                              SettingsContainer(
                                title: "Nama Pengguna Mikrotik",
                                data: mikrotikUsernameTxt,
                                onTap: () async {
                                  try {
                                    controller.text = mikrotikUsernameTxt;
                                    String? input = await _showInputDialog(
                                      controller,
                                      "Nama Pengguna Mikrotik",
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(24)
                                      ],
                                    );
                                    if (input != null) {
                                      controller.clear();
                                      gatewayModel.wifi.mikrotikUsername =
                                          input;
                                      BLEResponse resBLE =
                                          await _commandSet.setGateway(
                                              bleProvider, gatewayModel);
                                      Snackbar.showHelperV2(
                                        ScreenSnackbar.uploadsettings,
                                        resBLE,
                                        onSuccess: onRefresh,
                                      );
                                    }
                                  } catch (e) {
                                    Snackbar.show(
                                      ScreenSnackbar.uploadsettings,
                                      "Error click on Nama Pengguna Mikrotik : $e",
                                      success: false,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.person_outline,
                                ),
                              ),
                              SettingsContainer(
                                title: "Password Mikrotik",
                                data: mikrotikPasswordTxt,
                                onTap: () async {
                                  try {
                                    controller.text = mikrotikPasswordTxt;
                                    String? input = await _showInputDialog(
                                      controller,
                                      "Password Mikrotik",
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(24)
                                      ],
                                    );
                                    if (input != null) {
                                      controller.clear();
                                      gatewayModel.wifi.mikrotikPassword =
                                          input;
                                      BLEResponse resBLE =
                                          await _commandSet.setGateway(
                                              bleProvider, gatewayModel);
                                      Snackbar.showHelperV2(
                                        ScreenSnackbar.uploadsettings,
                                        resBLE,
                                        onSuccess: onRefresh,
                                      );
                                    }
                                  } catch (e) {
                                    Snackbar.show(
                                      ScreenSnackbar.uploadsettings,
                                      "Error click on Password Mikrotik : $e",
                                      success: false,
                                    );
                                  }
                                },
                                icon: const Icon(
                                  Icons.shield_outlined,
                                ),
                              ),
                              SettingsContainer(
                                title: "Modem APN",
                                data: modemApnTxt,
                                onTap: () async {
                                  try {
                                    controller.text = modemApnTxt;
                                    String? input = await _showInputDialog(
                                      controller,
                                      "Modem APN",
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(24)
                                      ],
                                    );
                                    if (input != null) {
                                      controller.clear();
                                      gatewayModel.modemAPN = input;
                                      BLEResponse resBLE =
                                          await _commandSet.setGateway(
                                              bleProvider, gatewayModel);
                                      Snackbar.showHelperV2(
                                        ScreenSnackbar.uploadsettings,
                                        resBLE,
                                        onSuccess: onRefresh,
                                      );
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
                            ],
                          ),
                    const SizedBox(
                      height: 15,
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
