import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:ble_test/constant/constant_color.dart';
import 'package:ble_test/screens/ble_main_screen/admin_settings_screen/admin_settings_screen.dart';
import 'package:ble_test/utils/converter/bytes_convert.dart';
import 'package:ble_test/utils/converter/settings/transmit_settings_convert.dart';
import 'package:ble_test/utils/extra.dart';
import 'package:ble_test/utils/time_pick/time_pick.dart';
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

  SetSettingsModel _setSettings = SetSettingsModel(setSettings: "", value: "");
  bool isTransmitSettings = true;
  late SimpleFontelicoProgressDialog _progressDialog;

  /// destination id
  TextEditingController destinationIDTxtController = TextEditingController();

  /// transmit schedule
  TextEditingController transmitScheduleTxtController = TextEditingController();

  List<dynamic> result = [];

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
          } else if (value > 24) {
            // Otomatis set menjadi 1.5 jika lebih dari 1.5
            transmitScheduleTxtController.text = '24';
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
    await Future.delayed(const Duration(milliseconds: 500));
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
                  // return of convert transmit
                  // status bool [0]
                  // destination enable list<bool> [1]
                  // destination id list<string> [2]
                  // transmit schedule list<int> [3]
                  result =
                      TransmitSettingsConvert.convertTransmitSettings(_value);
                  _progressDialog.hide();
                }

                // this is for set
                if (_value.length == 1) {
                  if (_value[0] == 1) {
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

  Future<String?> showSetupTransmitDialog(
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
                    // for destination ID
                    TextFormField(
                      style: GoogleFonts.readexPro(),
                      controller: destinationIDTxtController,
                      decoration: const InputDecoration(
                        labelText: "Enter Destination ID",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                      keyboardType: TextInputType.text,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^[a-zA-Z0-9:]*$')),
                        LengthLimitingTextInputFormatter(14),

                        // FilteringTextInputFormatter
                        //     .digitsOnly
                      ],
                    ),
                    const SizedBox(
                      height: 7,
                    ),

                    // for transmit schedule
                    TextFormField(
                      readOnly: true,
                      onTap: () async {
                        TimeOfDay? result =
                            await TimePickerHelper.pickTime(context, null);
                        if (result != null) {
                          transmitScheduleTxtController.text =
                              TimePickerHelper.formatTimeOfDay(result);
                        }
                      },
                      style: GoogleFonts.readexPro(),
                      controller: transmitScheduleTxtController,
                      decoration: const InputDecoration(
                        labelText: "Enter Transmit Schedule",
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
                            "Destination Enable",
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
                    destinationIDTxtController.text.isNotEmpty &&
                    transmitScheduleTxtController.text.isNotEmpty) {
                  String destinationId = destinationIDTxtController.text;
                  int transmitSchedule = TimePickerHelper.timeOfDayToMinutes(
                      TimePickerHelper.stringToTimeOfDay(
                          transmitScheduleTxtController.text));

                  Navigator.of(context).pop(
                      "transmit=${number + 1};$selectedChoice;$destinationId;$transmitSchedule");
                  destinationIDTxtController.clear();
                  transmitScheduleTxtController.clear();
                }
              },
              child: Text(
                'Update',
                style: GoogleFonts.readexPro(),
              ),
            ),
            TextButton(
              onPressed: () {
                destinationIDTxtController.clear();
                transmitScheduleTxtController.clear();
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
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(
                              top: 15, left: 10, right: 10),
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
                                "Destination ${index + 1}",
                                style: GoogleFonts.readexPro(
                                    fontSize: 18, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Destination ID : ",
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
                                          result[2][index],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Destination Enable : ",
                                    style: GoogleFonts.readexPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    result[1][index].toString(),
                                    style: GoogleFonts.readexPro(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Transmit Schedule : ",
                                      style: GoogleFonts.readexPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      TimePickerHelper.formatTimeOfDay(
                                          TimePickerHelper.minutesToTimeOfDay(
                                              result[3][index])),
                                      textAlign: TextAlign.right,
                                      style: GoogleFonts.readexPro(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            String? result =
                                await showSetupTransmitDialog(context, index);
                            if (result != null) {
                              // do your magic
                              List<int> list = utf8.encode(result);
                              Uint8List bytes = Uint8List.fromList(list);
                              await BLEUtils.funcWrite(
                                bytes,
                                "Transmit Set Success !!",
                                device,
                              );
                              onRefresh();
                            }
                          },
                          child: Container(
                            margin: const EdgeInsets.only(
                                left: 10, right: 10, top: 5),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                                color: Colors.blue.shade600,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 1,
                                    blurRadius: 1,
                                    offset: const Offset(
                                        0, 1), // changes position of shadow
                                  ),
                                ]),
                            width: MediaQuery.of(context).size.width,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.update,
                                  color: Colors.white,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Update Destination ${index + 1}",
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
                    );
                  },
                  childCount: result.isEmpty ? 0 : result[1].length,
                ),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 20),
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
