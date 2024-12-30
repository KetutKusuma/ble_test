import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/constant/constant_color.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/converter/bytes_convert.dart';
import 'package:ble_test/utils/converter/settings/transmit_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:simple_fontellico_progress_dialog/simple_fontico_loading.dart';
import '../../../utils/ble.dart';
import '../../../utils/snackbar.dart';

class TransmitSettingsScreen extends StatefulWidget {
  final BluetoothDevice device;
  const TransmitSettingsScreen({super.key, required this.device});

  @override
  State<TransmitSettingsScreen> createState() => _TransmitSettingsScreenState();
}

class _TransmitSettingsScreenState extends State<TransmitSettingsScreen> {
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
      destinationEnableTxt = '-',
      destinationIdTxt = '-',
      transmitScheduleTxt = '-';
  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  TextEditingController controller = TextEditingController();
  bool isTransmitSettings = true;
  late SimpleFontelicoProgressDialog _progressDialog;

  // untuk para destination
  // enable

  String? destinationEnableIndex; // ini untuk formfield
  bool? destinationEnableIndexBoolStatus; // ini untuk formfield
  bool isDestinationEnableStatus = false;
  String? resultDestinationEnable;

  /// destination id
  String? destinationIdIndex; // ini untuk formfield
  String? destinationNewIdText; // ini untuk formfield
  bool isDestinationIdStatus = false;
  String? resultDestinationId;
  TextEditingController destinationIDTxtController = TextEditingController();

  /// transmit schedule
  String? transmitScheduleIndex; // ini untuk formfield
  String? transmitScheduleIntString; // ini untuk formfield
  bool isTransmitScheduleStatus = false;
  String? resultTransmitSchedule;
  TextEditingController transmitScheduleTxtController = TextEditingController();

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
    destinationIDTxtController.addListener(() {
      _onTextChanged(destinationIDTxtController);
    });
    transmitScheduleTxtController.addListener(() {
      final text = transmitScheduleTxtController.text;
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) {
          if (value < 0) {
            // Otomatis set menjadi 0.5 jika kurang dari 0.5
            transmitScheduleTxtController.text = '0';
            transmitScheduleTxtController.selection =
                TextSelection.fromPosition(TextPosition(
                    offset: transmitScheduleTxtController
                        .text.length)); // Memastikan cursor di akhir
          } else if (value > 65535) {
            // Otomatis set menjadi 1.5 jika lebih dari 1.5
            transmitScheduleTxtController.text = '65535';
            transmitScheduleTxtController.selection =
                TextSelection.fromPosition(TextPosition(
                    offset: transmitScheduleTxtController
                        .text.length)); // Memastikan cursor di akhir
          }
        }
      }
    });

    initGetRawTransmit();
    initDiscoverServices();
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    if (_lastValueSubscription != null) {
      _lastValueSubscription!.cancel();
    }
    isTransmitSettings = false;
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
      initGetRawTransmit();
      await Future.delayed(const Duration(seconds: 1));
      _refreshController.refreshCompleted();
    } catch (e) {
      log("Error on refresh : $e");
    }
  }

  initGetRawTransmit() async {
    try {
      if (isConnected) {
        List<int> list = utf8.encode("raw_transmit?");
        Uint8List bytes = Uint8List.fromList(list);
        BLEUtils.funcWrite(bytes, "Success Get Raw Transmit", device);
      }
    } catch (e) {
      Snackbar.show(ScreenSnackbar.transmitsettings, "Error get raw admin : $e",
          success: false);
    }
  }

  Future initDiscoverServices() async {
    await Future.delayed(const Duration(seconds: 1));
    if (isConnected) {
      try {
        _services = await device.discoverServices();
        initLastValueSubscription(device);
      } catch (e) {
        Snackbar.show(ScreenSnackbar.transmitsettings,
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
              if (characters.properties.notify && isTransmitSettings) {
                log("is notifying ga nih : ${characters.isNotifying}");
                _value = value;
                if (mounted) {
                  setState(() {});
                }
                log("VALUE : $_value, ${_value.length}");

                // this is for get raw admin
                if (_value.length > 35) {
                  List<dynamic> result =
                      TransmitSettingsConvert.convertTransmitSettings(_value);
                  _progressDialog.hide();

                  if (mounted) {
                    setState(() {
                      statusTxt = result[0].toString();
                      destinationEnableTxt = result[1].toString();
                      destinationIdTxt = result[2].toString();
                      transmitScheduleTxt = result[3].toString();
                    });
                  }
                }
                // destination enable
                if (isDestinationEnableStatus) {
                  isDestinationEnableStatus = false;
                  resultDestinationEnable = (_value[0] == 1).toString();
                }

                // destination id
                if (isDestinationIdStatus) {
                  isDestinationIdStatus = false;
                  resultDestinationId = String.fromCharCodes(_value);
                }
                // transmit schedule
                if (isTransmitScheduleStatus) {
                  isTransmitScheduleStatus = false;
                  resultTransmitSchedule =
                      BytesConvert.bytesToInt16(_value, isBigEndian: false)
                          .toString();
                }
                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
                    if (_setSettings.setSettings == "destination_enable") {
                      destinationEnableTxt = _setSettings.value;
                    } else if (_setSettings.setSettings == "destination_id") {
                      destinationIdTxt = _setSettings.value;
                    } else if (_setSettings.setSettings ==
                        "transmit_schedule") {
                      transmitScheduleTxt = _setSettings.value;
                    }
                    // if(_setSettings.setSettings == )

                    Snackbar.show(ScreenSnackbar.transmitsettings,
                        "Success ${_setSettings.setSettings}",
                        success: true);
                  } else {
                    Snackbar.show(ScreenSnackbar.transmitsettings,
                        "Failed ${_setSettings.setSettings}",
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
      Snackbar.show(ScreenSnackbar.transmitsettings,
          prettyException("Last Value Error:", e),
          success: false);
      log(e.toString());
    }
  }

  final List<Map<String, dynamic>> dataMapIndex = [
    {"title": "1", "value": 1},
    {"title": "2", "value": 2},
    {"title": "3", "value": 3},
    {"title": "4", "value": 4},
    {"title": "5", "value": 5},
  ];

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

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: Snackbar.snackBarKeyTransmitSettings,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transmit Settings'),
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
                    // Text("VALUE : $_value"),
                    SettingsContainer(
                      title: "Status",
                      data: statusTxt,
                      onTap: () {},
                      icon: const Icon(
                        CupertinoIcons.settings,
                      ),
                    ),
                    SettingsContainer(
                      title: "Destination Enable",
                      data: destinationEnableTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                      ),
                    ),
                    // for search in destination enable
                    // DESTINATION ENABLE
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(
                              top: 5, left: 20, right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Map? input = await _showSelectionPopup(
                                                context, dataMapIndex)
                                            .then((value) {
                                          if (value != null) {
                                            setState(() {
                                              destinationEnableIndex =
                                                  value['title'];
                                            });
                                          }
                                        });
                                        if (input != null) {
                                          destinationEnableIndex =
                                              input['title'];
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          destinationEnableIndex ?? "Index",
                                          style: GoogleFonts.readexPro(
                                            color:
                                                destinationEnableIndex == null
                                                    ? Colors.grey
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (destinationEnableIndex != null) {
                                          isDestinationEnableStatus = true;
                                          List<int> list = utf8.encode(
                                              "destination_enable?$destinationEnableIndex");
                                          Uint8List bytes =
                                              Uint8List.fromList(list);
                                          _setSettings.setSettings =
                                              "get destination enable";
                                          BLEUtils.funcWrite(
                                            bytes,
                                            "Success Destination Enable!",
                                            device,
                                          );
                                        }
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors
                                                .lightBlueAccent.shade700),
                                        child: Text(
                                          "Search",
                                          style: GoogleFonts.readexPro(
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              resultDestinationEnable == null
                                  ? const SizedBox()
                                  : Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.only(
                                          right: 10, top: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "result : $resultDestinationEnable",
                                        style: GoogleFonts.readexPro(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        // ini untuk set destination enable
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(
                              top: 5, left: 20, right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Map? input = await _showSelectionPopup(
                                                context, dataMapIndex)
                                            .then((value) {
                                          if (value != null) {
                                            setState(() {
                                              destinationEnableIndex =
                                                  value['title'];
                                            });
                                          }
                                        });
                                        if (input != null) {
                                          destinationEnableIndex =
                                              input['title'];
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          destinationEnableIndex ?? "Index",
                                          style: GoogleFonts.readexPro(
                                            color:
                                                destinationEnableIndex == null
                                                    ? Colors.grey
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        bool? input =
                                            await _showTrueFalseDialog(
                                          context,
                                          "Destination Enable",
                                        );
                                        if (input != null) {
                                          destinationEnableIndexBoolStatus =
                                              input;
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          (destinationEnableIndexBoolStatus ??
                                                  "Status")
                                              .toString(),
                                          style: GoogleFonts.readexPro(
                                            fontSize: 13,
                                            color:
                                                destinationEnableIndexBoolStatus ==
                                                        null
                                                    ? Colors.grey
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (destinationEnableIndex != null) {
                                    isDestinationEnableStatus = true;
                                    List<int> list = utf8.encode(
                                        "destination_enable=$destinationEnableIndex;$destinationEnableIndexBoolStatus");
                                    Uint8List bytes = Uint8List.fromList(list);
                                    _setSettings.setSettings =
                                        "destination_enable";
                                    _setSettings.value =
                                        destinationEnableIndexBoolStatus
                                            .toString();
                                    BLEUtils.funcWrite(
                                      bytes,
                                      "Success Set Destination Enable!",
                                      device,
                                    );
                                  }
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin:
                                      const EdgeInsets.only(right: 10, top: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.lightBlueAccent.shade700),
                                  child: Text(
                                    "Set Enable Destination",
                                    style: GoogleFonts.readexPro(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // DESTINATION ID
                    SettingsContainer(
                      title: "Destination ID",
                      data: destinationIdTxt,
                      onTap: () {},
                      icon: const Icon(
                        Icons.perm_device_info_outlined,
                      ),
                    ),
                    // for destination id
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(
                              top: 5, left: 20, right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Map? input = await _showSelectionPopup(
                                                context, dataMapIndex)
                                            .then((value) {
                                          if (value != null) {
                                            setState(() {
                                              destinationIdIndex =
                                                  value['title'];
                                            });
                                          }
                                        });
                                        if (input != null) {
                                          destinationIdIndex = input['title'];
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          destinationIdIndex ?? "Index",
                                          style: GoogleFonts.readexPro(
                                            color: destinationIdIndex == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (destinationIdIndex != null) {
                                          isDestinationIdStatus = true;
                                          List<int> list = utf8.encode(
                                              "destination_id_string?$destinationIdIndex");
                                          Uint8List bytes =
                                              Uint8List.fromList(list);
                                          _setSettings.setSettings =
                                              "Get Destination ID";

                                          BLEUtils.funcWrite(
                                            bytes,
                                            "Success Search Destination ID",
                                            device,
                                          );
                                        }
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors
                                                .lightBlueAccent.shade700),
                                        child: Text(
                                          "Search",
                                          style: GoogleFonts.readexPro(
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              resultDestinationId == null
                                  ? const SizedBox()
                                  : Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.only(
                                          right: 10, top: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "result : $resultDestinationId",
                                        style: GoogleFonts.readexPro(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        // for set destination ID
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(
                              top: 5, left: 20, right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Map? input = await _showSelectionPopup(
                                                context, dataMapIndex)
                                            .then((value) {
                                          if (value != null) {
                                            setState(() {
                                              destinationIdIndex =
                                                  value['title'];
                                            });
                                          }
                                        });
                                        if (input != null) {
                                          destinationIdIndex = input['title'];
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          destinationIdIndex ?? "Index",
                                          style: GoogleFonts.readexPro(
                                            color: destinationIdIndex == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        String? input = await _showInputDialog(
                                          destinationIDTxtController,
                                          "Destination ID",
                                          label: 'Destination ID',
                                          keyboardType: TextInputType.text,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(r'^[a-zA-Z0-9:]*$')),
                                            LengthLimitingTextInputFormatter(
                                                14),

                                            // FilteringTextInputFormatter
                                            //     .digitsOnly
                                          ],
                                          lengthTextNeed: 12,
                                        );

                                        if (input != null) {
                                          destinationNewIdText = input;
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          (destinationNewIdText ?? "New Id")
                                              .toString(),
                                          style: GoogleFonts.readexPro(
                                            fontSize: 13,
                                            color: destinationNewIdText == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // this is button for set destination id
                              GestureDetector(
                                onTap: () {
                                  if (destinationIdIndex != null) {
                                    log("MAMAKE");
                                    resultDestinationId = null;
                                    log("mama set destination id : ${"destination_id_string=$destinationIdIndex;$destinationNewIdText"}");
                                    List<int> list = utf8.encode(
                                        "destination_id_string=$destinationIdIndex;$destinationNewIdText");
                                    Uint8List bytes = Uint8List.fromList(list);
                                    _setSettings.setSettings =
                                        "destination_id_string";
                                    _setSettings.value =
                                        destinationEnableIndexBoolStatus
                                            .toString();
                                    BLEUtils.funcWrite(
                                      bytes,
                                      "Success Set Destination Id String!",
                                      device,
                                    );
                                  }
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin:
                                      const EdgeInsets.only(right: 10, top: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.lightBlueAccent.shade700),
                                  child: Text(
                                    "Set Destination Id",
                                    style: GoogleFonts.readexPro(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SettingsContainer(
                      title: "Transmit Schedule",
                      data: transmitScheduleTxt,
                      onTap: () async {},
                      icon: const Icon(
                        Icons.calendar_today_outlined,
                      ),
                    ),
                    // for transmit schedule
                    Column(
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(
                              top: 5, left: 20, right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Map? input = await _showSelectionPopup(
                                                context, dataMapIndex)
                                            .then((value) {
                                          if (value != null) {
                                            setState(() {
                                              transmitScheduleIndex =
                                                  value['title'];
                                            });
                                          }
                                        });
                                        if (input != null) {
                                          transmitScheduleIndex =
                                              input['title'];
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          transmitScheduleIndex ?? "Index",
                                          style: GoogleFonts.readexPro(
                                            color: transmitScheduleIndex == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (transmitScheduleIndex != null) {
                                          isTransmitScheduleStatus = true;
                                          List<int> list = utf8.encode(
                                              "transmit_schedule?$transmitScheduleIndex");
                                          Uint8List bytes =
                                              Uint8List.fromList(list);
                                          BLEUtils.funcWrite(
                                            bytes,
                                            "Success Get Transmit Schedule $transmitScheduleIndex",
                                            device,
                                          );
                                        }
                                      },
                                      child: Container(
                                        width:
                                            MediaQuery.of(context).size.width,
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors
                                                .lightBlueAccent.shade700),
                                        child: Text(
                                          "Search",
                                          style: GoogleFonts.readexPro(
                                            color: Colors.white,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              resultTransmitSchedule == null
                                  ? const SizedBox()
                                  : Container(
                                      width: MediaQuery.of(context).size.width,
                                      margin: const EdgeInsets.only(
                                          right: 10, top: 3),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 10),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        "result : $resultTransmitSchedule",
                                        style: GoogleFonts.readexPro(
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        // for set transmit schedule
                        Container(
                          width: MediaQuery.of(context).size.width,
                          margin: const EdgeInsets.only(
                              top: 5, left: 20, right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: borderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        Map? input = await _showSelectionPopup(
                                                context, dataMapIndex)
                                            .then((value) {
                                          if (value != null) {
                                            setState(() {
                                              transmitScheduleIndex =
                                                  value['title'];
                                            });
                                          }
                                        });
                                        if (input != null) {
                                          transmitScheduleIndex =
                                              input['title'];
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          transmitScheduleIndex ?? "Index",
                                          style: GoogleFonts.readexPro(
                                            color: transmitScheduleIndex == null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () async {
                                        String? input = await _showInputDialog(
                                          transmitScheduleTxtController,
                                          "Transmit Schedule",
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                        );
                                        if (input != null) {
                                          transmitScheduleIntString = input;
                                          setState(() {});
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(right: 10),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 10),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: borderColor,
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          (transmitScheduleIntString ??
                                                  "Minutes")
                                              .toString(),
                                          style: GoogleFonts.readexPro(
                                            fontSize: 13,
                                            color: transmitScheduleIntString ==
                                                    null
                                                ? Colors.grey
                                                : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (transmitScheduleIntString != null) {
                                    // isTransmitScheduleStatus = true;
                                    log("papa : ${"transmit_schedule=$transmitScheduleIndex;$transmitScheduleIntString"}");
                                    List<int> list = utf8.encode(
                                        "transmit_schedule=$transmitScheduleIndex;$transmitScheduleIntString");
                                    Uint8List bytes = Uint8List.fromList(list);
                                    _setSettings.setSettings =
                                        "transmit_schedule";
                                    _setSettings.value =
                                        destinationEnableIndexBoolStatus
                                            .toString();
                                    BLEUtils.funcWrite(
                                      bytes,
                                      "Success Set Transmit Schedule!",
                                      device,
                                    );
                                  }
                                },
                                child: Container(
                                  width: MediaQuery.of(context).size.width,
                                  margin:
                                      const EdgeInsets.only(right: 10, top: 10),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 10),
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      color: Colors.lightBlueAccent.shade700),
                                  child: Text(
                                    "Set Transmit Schedule",
                                    style: GoogleFonts.readexPro(
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
      Snackbar.show(ScreenSnackbar.transmitsettings, "Connect: Success",
          success: true);
    } catch (e) {
      if (e is FlutterBluePlusException &&
          e.code == FbpErrorCode.connectionCanceled.index) {
        // ignore connections canceled by the user
      } else {
        Snackbar.show(ScreenSnackbar.transmitsettings,
            prettyException("Connect Error:", e),
            success: false);
        log(e.toString());
      }
    }
  }

  Future onCancelPressed() async {
    try {
      await device.disconnectAndUpdateStream(queue: false);
      Snackbar.show(ScreenSnackbar.transmitsettings, "Cancel: Success",
          success: true);
    } catch (e) {
      Snackbar.show(
          ScreenSnackbar.transmitsettings, prettyException("Cancel Error:", e),
          success: false);
      log(e.toString());
    }
  }

  Future onDisconnectPressed() async {
    try {
      await device.disconnectAndUpdateStream();
      Snackbar.show(ScreenSnackbar.transmitsettings, "Disconnect: Success",
          success: true);
    } catch (e) {
      Snackbar.show(ScreenSnackbar.transmitsettings,
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
