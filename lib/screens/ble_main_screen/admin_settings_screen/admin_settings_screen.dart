import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/converter/settings/admin_settings_convert.dart';
import 'package:ble_test/utils/enum/role.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/global.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';

import '../../../constant/constant_color.dart';

class AdminSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;

  const AdminSettingsScreen({super.key, required this.device});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
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
      idTxt = '-',
      voltCoef1Txt = '-',
      voltCoef2Txt = '-',
      brightnessText = '-',
      contrastText = '-',
      saturationText = '-',
      specialEffectText = '-',
      hMirrorText = '-',
      vFlipText = '-',
      cameraJpgQualityTxt = '-',
      roleTxt = '-';

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController idTxtController = TextEditingController();
  TextEditingController voltageCoefTxtController = TextEditingController();
  TextEditingController cameraJpegQualityController = TextEditingController();

  final List<Map<String, dynamic>> dataMapRole = [
    {"title": "Undefiend", "value": 0},
    {"title": "Regular", "value": 1},
    {"title": "Gateway", "value": 2},
  ];
  final List<Map<String, dynamic>> dataMapBrightnessContrastSaturation = [
    {"title": "-2", "value": -2},
    {"title": "-1", "value": -1},
    {"title": "0", "value": 0},
    {"title": "1", "value": 1},
    {"title": "2", "value": 2},
  ];
  final List<Map<String, dynamic>> dataMapSpecialEffect = [
    {"title": "No Effect", "value": 0},
    {"title": "Negative", "value": 1},
    {"title": "Grayscale", "value": 2},
    {"title": "Red Tint", "value": 3},
    {"title": "Green Tint", "value": 4},
    {"title": "Blue Tint", "value": 5},
    {"title": "Sepia", "value": 6},
  ];
  List<int> bits = [];
  bool isAdminSettings = true;
  late SimpleFontelicoProgressDialog _progressDialog;

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
          Navigator.pop(context);
        }
        if (mounted) {
          setState(() {});
        }
      },
    );

    idTxtController.addListener(() {
      _onTextChanged(idTxtController);
    });
    voltageCoefTxtController.addListener(() {
      final text = voltageCoefTxtController.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          if (value < 0.5 && text.length > 2) {
            // Otomatis set menjadi 0.5 jika kurang dari 0.5
            voltageCoefTxtController.text = '0.5';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          } else if (value > 1.5) {
            // Otomatis set menjadi 1.5 jika lebih dari 1.5
            voltageCoefTxtController.text = '1.5';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          }
        }
      }
    });
    cameraJpegQualityController.addListener(() {
      final text = voltageCoefTxtController.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          if (value < 0) {
            // Otomatis set menjadi 0.5 jika kurang dari 0.5
            voltageCoefTxtController.text = '0';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          } else if (value > 63) {
            // Otomatis set menjadi 1.5 jika lebih dari 1.5
            voltageCoefTxtController.text = '63';
            voltageCoefTxtController.selection = TextSelection.fromPosition(
                TextPosition(
                    offset: voltageCoefTxtController
                        .text.length)); // Memastikan cursor di akhir
          }
        }
      }
    });

    initGetRawAdmin();
    initDiscoverServices();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _connectionStateSubscription.cancel();
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    isAdminSettings = false;
    super.dispose();
  }

  void _showLoading() {
    _progressDialog.show(
      message: "Please wait...",
    );
  }

  void _onTextChanged(TextEditingController textEditingController) {
    String text = textEditingController.text
        .replaceAll(":", ""); // Remove existing colons
    String formattedText = "";

    // Add colon after every 2 characters
    for (int i = 0; i < text.length; i++) {
      formattedText += text[i];
      if ((i + 1) % 2 == 0 && i != text.length - 1) {
        formattedText += ":";
      }
    }

    // Prevent unnecessary updates (cursor position fixes)
    if (formattedText != textEditingController.text) {
      final cursorPosition = textEditingController.selection.baseOffset;
      textEditingController.value = textEditingController.value.copyWith(
        text: formattedText,
        selection: TextSelection.collapsed(
            offset: cursorPosition +
                (formattedText.length - textEditingController.text.length)),
      );
    }
  }

  onRefresh() async {
    try {
      initGetRawAdmin();
      await Future.delayed(
        const Duration(seconds: 1),
      );
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawAdmin() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_admin?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Admin", device);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.adminsettings, "Error get raw admin : $e",
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
        Snackbar.show(ScreenSnackbar.login,
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
              log("is notifying ga nih : ${characters.isNotifying}");
              if (characters.properties.notify && isAdminSettings) {
                _value = value;
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 16) {
                  List<dynamic> result =
                      AdminSettingsConverter().convertAdminSettings(_value);
                  _progressDialog.hide();

                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      idTxt = result[1].toString();
                      voltCoef1Txt = result[2].toString();
                      voltCoef2Txt = result[3].toString();
                      brightnessText = (result[4]).toString();
                      contrastText = (result[5]).toString();
                      saturationText = (result[6]).toString();
                      specialEffectText = getSpecialEffectString(result[7]);
                      hMirrorText = result[8].toString();
                      vFlipText = result[9].toString();
                      cameraJpgQualityTxt = result[10].toString();
                      roleTxt = result[11] == 0
                          ? "Undifined"
                          : result[10] == 1
                              ? "Regular"
                              : result[10] == 2
                                  ? "Gateway"
                                  : "Error";
                    });
                  }
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "id") {
                      idTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "voltcoef1") {
                      voltCoef1Txt = _setSettings.value;
                    } else if (_setSettings.setSettings == "voltcoef2") {
                      voltCoef2Txt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "camera_setting_brightness") {
                      brightnessText = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "camera_setting_contrast") {
                      contrastText = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "camera_setting_saturation") {
                      saturationText = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "camera_setting_special_effect") {
                      try {
                        specialEffectText = getSpecialEffectString(
                            int.parse(_setSettings.value));
                      } catch (e) {
                        log("error catch on special effect : $e");
                      }
                    } else if (_setSettings.setSettings ==
                        "camera_setting_vflip") {
                      vFlipText = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "camera_setting_hmirror") {
                      hMirrorText = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "camera_jpeg_quality") {
                      cameraJpgQualityTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "role") {
                      roleTxt = _setSettings.value == "0"
                          ? "Undifined"
                          : _setSettings.value == "1"
                              ? "Regular"
                              : _setSettings.value == "2"
                                  ? "Gateway"
                                  : "Error";
                    }
                    Snackbar.show(ScreenSnackbar.adminsettings,
                        "Success set ${_setSettings.setSettings}",
                        success: true);
                  } else {
                    Snackbar.show(ScreenSnackbar.adminsettings,
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
        }
      }
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

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

  String getSpecialEffectString(int value) {
    switch (value) {
      case 0:
        return "None";
      case 1:
        return "Negative";
      case 2:
        return "Grayscale";
      case 3:
        return "Red Tint";
      case 4:
        return "Green Tint";
      case 5:
        return "Blue Tint";
      case 6:
        return "Sepia";
      default:
        return "None";
    }
  }

  /// ===== for connection ===================
  Future onConnectPressed() async {
    try {
      await device.connectAndUpdateStream();
      // initDiscoverServices();
      Snackbar.show(ScreenSnackbar.login, "Connect: Success", success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(
            ScreenSnackbar.login, prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.login, "Cancel: Success", success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.login, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.login, "Disconnect: Success", success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.login, prettyException("Disconnect Error:", e),
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

  // Function to show a dialog for input
  Future<String?> _showInputDialog(
    TextEditingController controller,
    String title, {
    String? label = '',
    TextInputType? keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int? lengthTextNeed = 0,
  }) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Enter $title"),
          content: Form(
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: "Enter $label",
                border: const OutlineInputBorder(),
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
                controller.clear();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (lengthTextNeed != 0 &&
                    lengthTextNeed! < controller.text.length) {
                  Navigator.pop(context, controller.text);
                  controller.clear();
                }
                if (lengthTextNeed == 0) {
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

  Future<String?> _showInputDialogVoltage(
      TextEditingController controller) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter Value Voltage Coef"),
          content: Form(
            child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              decoration: const InputDecoration(
                labelText: 'Value between 0.5 and 1.5',
                border: OutlineInputBorder(),
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

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyAdminSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Settings'),
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
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),

                    /// RESET
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: GestureDetector(
                        onTap: () {
                          List<int> list = utf8.encode("reset!");
                          Uint8List bytes = Uint8List.fromList(list);
                          BLEUtils.funcWrite(bytes, "Reset success", device);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade800,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.settings_backup_restore_rounded,
                                color: Colors.white,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                "Reset",
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

                    /// FORMAT
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: GestureDetector(
                        onTap: () async {
                          List<int> list = utf8.encode("format!");
                          Uint8List bytes = Uint8List.fromList(list);
                          BLEUtils.funcWrite(
                              bytes, "Set Format success", device);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          width: MediaQuery.of(context).size.width,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.drive_file_move_rtl_outlined,
                                color: Colors.white,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                "Format",
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
                    Visibility(
                      visible: featureB.contains(roleUser),
                      child: GestureDetector(
                        onTap: () async {
                          bool? input =
                              await _showTrueFalseDialog(context, "Enable");
                          if (input != null) {
                            List<int> list = utf8.encode("enable?$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            BLEUtils.funcWrite(
                                bytes, "Set Enable $input success", device);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(
                              left: 10, right: 10, top: 5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
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
                                "Enable",
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
                    // Text("VALUE : $_value"),
                    SettingsContainer(
                      icon: const Icon(
                        CupertinoIcons.settings,
                      ),
                      title: "Status",
                      data: statusTxt,
                      onTap: () {
                        // List<int> list = utf8.encode("?");
                        // Uint8List bytes = Uint8List.fromList(list);
                        // BLEUtils.funcWrite(bytes, "Success Get Raw Admin");
                      },
                    ),
                    SettingsContainer(
                      icon: const Icon(Icons.person_outline),
                      title: "ID",
                      data: idTxt,
                      onTap: () async {
                        String? input = await _showInputDialog(
                          idTxtController,
                          "New ID",
                          label: 'New ID ',
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(14),
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          lengthTextNeed: 12,
                        );
                        log("input : $input");
                        if (input != null) {
                          List<int> list = utf8.encode("id=$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          _setSettings =
                              SetSettingsModel(setSettings: "id", value: input);
                          BLEUtils.funcWrite(bytes, "Success Set ID", device);
                        }
                      },
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.bolt),
                        title: "Volt Coef 1",
                        data: voltCoef1Txt,
                        onTap: () async {
                          String? input = await _showInputDialogVoltage(
                              voltageCoefTxtController);
                          if (input != null) {
                            List<int> list =
                                utf8.encode("voltage1_coef=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "voltcoef1", value: input);
                            BLEUtils.funcWrite(
                                bytes, "Success Set Volt Coef 1", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.bolt),
                        title: "Volt Coef 2",
                        data: voltCoef2Txt,
                        onTap: () async {
                          String? input = await _showInputDialogVoltage(
                              voltageCoefTxtController);
                          if (input != null) {
                            List<int> list =
                                utf8.encode("voltage2_coef=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "voltcoef2", value: input);
                            BLEUtils.funcWrite(
                                bytes, "Success Set Volt Coef 2", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.brightness_5),
                        title: "Camera Brightness",
                        data: brightnessText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapBrightnessContrastSaturation);
                          if (input != null) {
                            List<int> list = utf8.encode(
                                "camera_setting_brightness=${input['value']}");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "camera_setting_brightness",
                                value: input['value'].toString());
                            BLEUtils.funcWrite(
                                bytes, "Success Set Camera Brightness", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.brightness_6),
                        title: "Camera Contrast",
                        data: contrastText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapBrightnessContrastSaturation);
                          if (input != null) {
                            List<int> list = utf8.encode(
                                "camera_setting_contrast=${input['value']}");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "camera_setting_contrast",
                                value: input['value'].toString());
                            BLEUtils.funcWrite(
                                bytes, "Success Set Camera Contrast", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.brightness_1_rounded),
                        title: "Camera Saturation",
                        data: saturationText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapBrightnessContrastSaturation);
                          if (input != null) {
                            List<int> list = utf8.encode(
                                "camera_setting_saturation=${input['value']}");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "camera_setting_saturation",
                                value: input['value'].toString());
                            BLEUtils.funcWrite(
                                bytes, "Success Set Camera Saturation", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.wand_stars_inverse),
                        title: "Camera Special effect",
                        data: specialEffectText,
                        onTap: () async {
                          Map? input = await _showSelectionPopup(
                              context, dataMapSpecialEffect);
                          if (input != null) {
                            List<int> list = utf8.encode(
                                "camera_setting_special_effect=${input['value']}");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                              setSettings: "camera_setting_special_effect",
                              value: input['value'].toString(),
                            );
                            BLEUtils.funcWrite(
                                bytes, "Success Set Camera Brightness", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(Icons.flip),
                        title: "Camera H Mirror",
                        data: hMirrorText,
                        onTap: () async {
                          bool? input = await _showTrueFalseDialog(
                              context, "Camera H Mirror");
                          if (input != null) {
                            List<int> list =
                                utf8.encode("camera_setting_hmirror=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "camera_setting_hmirror",
                                value: input.toString());
                            BLEUtils.funcWrite(
                                bytes, "Success Set Camera H Mirror", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: Transform.rotate(
                          angle: 3.14 / 2,
                          child: const Icon(
                            Icons.flip,
                          ),
                        ),
                        title: "Camera V Flip",
                        data: vFlipText,
                        onTap: () async {
                          bool? input = await _showTrueFalseDialog(
                              context, "Camera V Flip");
                          if (input != null) {
                            List<int> list =
                                utf8.encode("camera_setting_vflip=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "camera_setting_vflip",
                                value: input.toString());
                            BLEUtils.funcWrite(
                                bytes, "Success Set Camera V Flip", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(
                          Icons.high_quality_outlined,
                        ),
                        title: "Camera Jpeg Quality",
                        data: cameraJpgQualityTxt,
                        onTap: () async {
                          String? input = await _showInputDialog(
                            cameraJpegQualityController,
                            "Camera Jpeg Quality",
                            label: '0 to 63',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          );
                          log("input : $input");
                          if (input != null) {
                            List<int> list =
                                utf8.encode("camera_jpeg_quality=$input");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "camera_jpeg_quality",
                                value: input);
                            BLEUtils.funcWrite(bytes, "Success Set ID", device);
                          }
                        },
                      ),
                    ),
                    Visibility(
                      visible: featureA.contains(roleUser),
                      child: SettingsContainer(
                        icon: const Icon(CupertinoIcons.gear_big),
                        title: "Role",
                        data: roleTxt,
                        onTap: () async {
                          Map? result =
                              await _showSelectionPopup(context, dataMapRole);
                          if (result != null) {
                            List<int> list =
                                utf8.encode("role=${result["value"]}");
                            Uint8List bytes = Uint8List.fromList(list);
                            _setSettings = SetSettingsModel(
                                setSettings: "role",
                                value: result["value"].toString());
                            BLEUtils.funcWrite(
                                bytes, "Success Set Role", device);
                          }
                        },
                      ),
                    ),
                    const SizedBox(
                      height: 20,
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
}

class SettingsContainer extends StatelessWidget {
  const SettingsContainer({
    super.key,
    required this.title,
    required this.data,
    required this.onTap,
    required this.icon,
    this.description,
  });

  final String title;
  final String? description;
  final String data;
  final void Function() onTap;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 7, left: 10, right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
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
              icon,
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
                      title,
                      style: GoogleFonts.readexPro(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    (description == null)
                        ? const SizedBox()
                        : Text(
                            description ?? '',
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    data,
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
    );
  }
}

class SetSettingsModel {
  String setSettings = "";
  String value = "";

  SetSettingsModel({required this.setSettings, required this.value});
}
