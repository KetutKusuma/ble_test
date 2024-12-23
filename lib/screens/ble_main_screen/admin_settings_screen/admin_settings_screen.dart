import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/utils/ble.dart';
import 'package:ble_test/utils/converter/settings/admin_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/snackbar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

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
  late StreamSubscription<List<int>> _lastValueSubscription;

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
      roleTxt = '-';

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController idTxtController = TextEditingController();
  TextEditingController voltageCoefTxtController = TextEditingController();

  final List<Map<String, dynamic>> dataMap = [
    {"title": "Undefiend", "value": 0},
    {"title": "Regular", "value": 1},
    {"title": "Gateway", "value": 2},
  ];
  List<int> bits = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _connectionStateSubscription = device.connectionState.listen((state) async {
      _connectionState = state;
      if (_connectionState == BluetoothConnectionState.disconnected) {
        _lastValueSubscription.cancel();
        Navigator.pop(
          context,
        );
      }
      if (mounted) {
        setState(() {});
      }
    });

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

    initGetRawAdmin();
    initDiscoverServices();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _connectionStateSubscription.cancel();
    // _lastValueSubscription.cancel();
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
              if (characters.properties.notify) {
                _value = value;
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 16) {
                  List<dynamic> result =
                      AdminSettingsConverter().convertAdminSettings(_value);
                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      idTxt = result[1].toString();
                      voltCoef1Txt = result[2].toString();
                      voltCoef2Txt = result[3].toString();
                      brightnessText = (result[4]).toString();
                      contrastText = (result[5]).toString();
                      saturationText = (result[6]).toString();
                      specialEffectText = result[7].toString();
                      hMirrorText = result[8].toString();
                      vFlipText = result[9].toString();
                      roleTxt = result[10].toString();
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
                    } else if (_setSettings.setSettings == "role") {
                      roleTxt = _setSettings.value;
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
          // _lastValueSubscription.cancel();
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
          children: <Widget>[
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
  Future<String?> _showInputDialog(TextEditingController controller) async {
    String? input = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Enter New ID"),
          content: Form(
            child: TextFormField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: "Enter New ID",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter some text';
                }
                return null;
              },
              inputFormatters: [
                LengthLimitingTextInputFormatter(14),
                FilteringTextInputFormatter.digitsOnly
              ],
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
                if (controller.text.isNotEmpty && controller.text.length > 12) {
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
                labelText: 'Enter a value between 0.5 and 1.5',
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

  Future<Map?> _showSelectionPopup(BuildContext context) async {
    Map? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select an Option'),
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
          actions: [
            Row(
              children: [
                if (_isConnecting || _isDisconnecting) buildSpinner(context),
                TextButton(
                  onPressed: _isConnecting
                      ? onCancelPressed
                      : (isConnected ? onDisconnectPressed : onConnectPressed),
                  child: Text(
                    _isConnecting
                        ? "CANCEL"
                        : (isConnected ? "DISCONNECT" : "CONNECT"),
                    style: Theme.of(context)
                        .primaryTextTheme
                        .labelLarge
                        ?.copyWith(color: Colors.white),
                  ),
                )
              ],
            ),
          ],
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
                    Text("VALUE : $_value"),
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
                        String? input = await _showInputDialog(idTxtController);
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
                    SettingsContainer(
                      icon: const Icon(CupertinoIcons.bolt),
                      title: "Volt Coef 1",
                      data: voltCoef1Txt,
                      onTap: () async {
                        String? input = await _showInputDialogVoltage(
                            voltageCoefTxtController);
                        if (input != null) {
                          List<int> list = utf8.encode("voltage1_coef=$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          _setSettings = SetSettingsModel(
                              setSettings: "voltcoef1", value: input);
                          BLEUtils.funcWrite(
                              bytes, "Success Set Volt Coef 1", device);
                        }
                      },
                    ),
                    SettingsContainer(
                      icon: const Icon(CupertinoIcons.bolt),
                      title: "Volt Coef 2",
                      data: voltCoef2Txt,
                      onTap: () async {
                        String? input = await _showInputDialogVoltage(
                            voltageCoefTxtController);
                        if (input != null) {
                          List<int> list = utf8.encode("voltage2_coef=$input");
                          Uint8List bytes = Uint8List.fromList(list);
                          _setSettings = SetSettingsModel(
                              setSettings: "voltcoef2", value: input);
                          BLEUtils.funcWrite(
                              bytes, "Success Set Volt Coef 2", device);
                        }
                      },
                    ),
                    SettingsContainer(
                      icon: const Icon(Icons.brightness_5),
                      title: "Camera Brightness",
                      data: brightnessText,
                      onTap: () {},
                    ),
                    SettingsContainer(
                      icon: const Icon(Icons.brightness_6),
                      title: "Camera Contrast",
                      data: contrastText,
                      onTap: () {},
                    ),
                    SettingsContainer(
                      icon: const Icon(Icons.brightness_1_rounded),
                      title: "Camera Saturation",
                      data: saturationText,
                      onTap: () {},
                    ),
                    SettingsContainer(
                      icon: const Icon(CupertinoIcons.wand_stars_inverse),
                      title: "Camera Special effect",
                      data: specialEffectText,
                      onTap: () {},
                    ),
                    SettingsContainer(
                      icon: const Icon(Icons.flip_to_front),
                      title: "Camera H Mirror",
                      data: hMirrorText,
                      onTap: () {},
                    ),
                    SettingsContainer(
                      icon: const Icon(Icons.flip),
                      title: "Camera V Flip",
                      data: vFlipText,
                      onTap: () {},
                    ),
                    SettingsContainer(
                      icon: const Icon(CupertinoIcons.gear_big),
                      title: "Role",
                      data: roleTxt,
                      onTap: () async {
                        Map? result = await _showSelectionPopup(context);
                        if (result != null) {
                          List<int> list =
                              utf8.encode("role=${result["value"]}");
                          Uint8List bytes = Uint8List.fromList(list);
                          _setSettings = SetSettingsModel(
                              setSettings: "role",
                              value: result["value"].toString());
                          BLEUtils.funcWrite(bytes, "Success Set Role", device);
                        }
                      },
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
  });

  final String title;
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
                child: Text(
                  title,
                  style: GoogleFonts.readexPro(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
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
